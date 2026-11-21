<?php

namespace App\Modules\FeedingSpot\Services;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Layanan kalkulasi formula poin dinamis Feeding Spot sesuai Lampiran A.1 PRD
 * serta mekanisme reversal poin (AFS-11, AFS-12, MEOW-14).
 */
class FeedingRewardService
{
    /**
     * Hitung snapshot poin dinamis sesuai Lampiran A.1 PRD:
     * poin = round(P0 * (1 + wp*Sp + wt*St + wq*Sq) * D(n)), diklem ke [Pmin, Pmax].
     *
     * Catatan Arsitektur: Kredit poin aktual tetap dilakukan melalui PointService::award()
     * sesuai Aturan Keras #2 AGENTS.md; hasil formula dinamis disimpan di reward_snapshot
     * dan potential_points sebagai audit trail kalkulasi AFS-11.
     */
    public function calculateRewardSnapshot(FeedingActivity $activity, ?Carbon $verifiedAt = null): array
    {
        $now = $verifiedAt ?? now();

        $p0 = FeedingSetting::getFloat('reward_base_p0', 10.0);
        $pMin = (int) FeedingSetting::getFloat('reward_min_points', 5.0);
        $pMax = (int) FeedingSetting::getFloat('reward_max_points', 20.0);
        $wp = FeedingSetting::getFloat('reward_weight_priority', 0.60);
        $wt = FeedingSetting::getFloat('reward_weight_time_gap', 0.25);
        $wq = FeedingSetting::getFloat('reward_weight_quality', 0.15);
        $t14 = max(1.0, FeedingSetting::getFloat('target_feedings_14d', 28.0));
        $dailyCap = (int) FeedingSetting::getFloat('daily_reward_cap', 3.0);

        // Urutan ke-n kegiatan terverifikasi pengguna pada hari ini (WIB)
        $todayStart = $now->copy()->timezone('Asia/Jakarta')->startOfDay()->utc();
        $verifiedTodayBefore = FeedingActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->where('status', 'VERIFIED')
            ->where('finalized_at', '>=', $todayStart)
            ->count();

        $n = $verifiedTodayBefore + 1;

        // Faktor penurunan harian D(n): n=1 -> 1.00, n=2 -> 0.75, n=3 -> 0.50, n>=4 -> 0.00
        $dn = match (true) {
            $n === 1 => 1.00,
            $n === 2 => 0.75,
            $n === 3 => 0.50,
            default => 0.00,
        };

        if ($n > $dailyCap || $dn <= 0.0) {
            return [
                'dynamic_points' => 0,
                'reward_capped' => true,
                'n_today' => $n,
                'sp' => 0.0,
                'st' => 0.0,
                'sq' => 0.0,
                'dn' => 0.0,
            ];
        }

        // 1. Skor prioritas spot Sp = clamp(1 - N14 / T14, 0, 1)
        $n14 = FeedingActivity::query()
            ->where('spot_id', $activity->spot_id)
            ->where('id', '!=', $activity->id)
            ->where('status', 'VERIFIED')
            ->where('finalized_at', '>=', $now->copy()->subDays(14))
            ->count();

        $sp = max(0.0, min(1.0, 1.0 - ($n14 / $t14)));

        // 2. Skor jarak waktu sejak pemberian makan terakhir St = clamp(delta_t / 24, 0, 1)
        $lastVerified = FeedingActivity::query()
            ->where('spot_id', $activity->spot_id)
            ->where('id', '!=', $activity->id)
            ->where('status', 'VERIFIED')
            ->whereNotNull('finalized_at')
            ->latest('finalized_at')
            ->first();

        $deltaHours = $lastVerified && $lastVerified->finalized_at
            ? max(0.0, $lastVerified->finalized_at->diffInMinutes($now) / 60.0)
            : 24.0;

        $st = max(0.0, min(1.0, $deltaHours / 24.0));

        // 3. Skor kelengkapan bukti Sq in [0, 1]
        $evidenceCount = $activity->evidences()->count();
        $flags = $activity->flags ?? [];
        if (empty($flags) && $evidenceCount >= 2) {
            $sq = 1.0;
        } elseif (empty($flags) && $evidenceCount === 1) {
            $sq = 0.5;
        } else {
            $sq = 0.0;
        }

        // Rumus Lampiran A.1
        $rawPoints = round($p0 * (1.0 + ($wp * $sp) + ($wt * $st) + ($wq * $sq)) * $dn);
        $clampedPoints = (int) max($pMin, min($pMax, $rawPoints));

        return [
            'dynamic_points' => $clampedPoints,
            'reward_capped' => false,
            'n_today' => $n,
            'n14' => $n14,
            'delta_hours' => round($deltaHours, 2),
            'sp' => round($sp, 4),
            'st' => round($st, 4),
            'sq' => round($sq, 4),
            'dn' => $dn,
        ];
    }

    /**
     * Reversal poin jika aktivitas yang sudah CREDITED dibatalkan/ditolak saat audit (AFS-12).
     * Saldo poin pengguna tidak boleh menjadi negatif (clamped ke >= 0).
     */
    public function reverseReward(FeedingActivity $activity, string $reason, ?string $actorId = null): array
    {
        return DB::transaction(function () use ($activity, $reason, $actorId) {
            $creditedPoints = $activity->points_awarded;
            if ($activity->reward_status !== 'CREDITED' || $creditedPoints <= 0) {
                $activity->update(['reward_status' => 'REVERSED']);

                return [
                    'reversed_points' => 0,
                    'new_balance' => (int) (DB::table('point_balances')->where('user_id', $activity->user_id)->value('total_points') ?? 0),
                ];
            }

            $reversalKey = "feeding.reversal:{$activity->id}";
            $existingReversal = DB::table('point_transactions')
                ->where('idempotency_key', $reversalKey)
                ->first();

            if (!$existingReversal) {
                $balanceRow = DB::table('point_balances')
                    ->where('user_id', $activity->user_id)
                    ->lockForUpdate()
                    ->first();

                $currentBalance = $balanceRow ? (int) $balanceRow->total_points : 0;
                $deducted = min($currentBalance, $creditedPoints);
                $newBalance = max(0, $currentBalance - $creditedPoints);

                $origTxId = $activity->reward_snapshot['transaction_id'] ?? null;

                DB::table('point_transactions')->insert([
                    'id' => (string) Str::ulid(),
                    'user_id' => $activity->user_id,
                    'rule_key' => 'feeding.verified',
                    'points' => -$deducted,
                    'source_module' => 'FeedingSpot',
                    'source_type' => 'REVERSAL',
                    'source_ref_id' => $activity->id,
                    'idempotency_key' => $reversalKey,
                    'status' => 'REVERSED',
                    'reversal_of' => $origTxId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                if ($balanceRow) {
                    DB::table('point_balances')
                        ->where('user_id', $activity->user_id)
                        ->update([
                            'total_points' => $newBalance,
                            'updated_at' => now(),
                        ]);
                }
            }

            $snapshot = $activity->reward_snapshot ?? [];
            $snapshot['reversed_at'] = now()->toIso8601String();
            $snapshot['reversal_reason'] = $reason;
            $snapshot['points_awarded'] = 0;

            $activity->update([
                'reward_status' => 'REVERSED',
                'reward_snapshot' => $snapshot,
            ]);

            $finalBalance = (int) (DB::table('point_balances')->where('user_id', $activity->user_id)->value('total_points') ?? 0);

            return [
                'reversed_points' => $creditedPoints,
                'new_balance' => $finalBalance,
            ];
        });
    }
}
