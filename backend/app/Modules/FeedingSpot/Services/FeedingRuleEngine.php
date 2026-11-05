<?php

namespace App\Modules\FeedingSpot\Services;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use Illuminate\Support\Facades\DB;

class FeedingRuleEngine
{
    /**
     * Evaluasi aturan verifikasi pemberian pakan tanpa GPS (Aturan R3 & R9 dihapus sesuai PRD OQ-01 & Aturan Keras #8).
     *
     * Aturan aktif:
     * - R1_QR_VALID: Spot valid dan berstatus ACTIVE
     * - R2_SESSION_TIMELY: Finalisasi dilakukan dalam batas waktu <= 60 menit sejak scan QR
     * - R4_PHOTO_UNIQUE: Bukti foto (1-3 foto) belum pernah dipakai pada aktivitas lain (cek SHA-256 di media_files)
     * - R5_COOLDOWN_PASSED: Tidak ada aktivitas pengguna yang sama di spot yang sama dalam 6 jam terakhir
     * - R6_NEW_USER_SAMPLE: 2 pengajuan pertama pengguna baru otomatis masuk UNDER_REVIEW
     * - R8_RATE_LIMIT_OK: Frekuensi harian wajar (jika melebihi batas wajar, arahkan ke UNDER_REVIEW)
     *
     * @param  FeedingActivity  $activity
     * @param  array<int, string>  $mediaIds
     * @return array{status: string, flags: array<int, string>, results: array<int, array{rule: string, result: string, detail: string}>}
     */
    public function evaluateAndRecord(FeedingActivity $activity, array $mediaIds): array
    {
        FeedingSetting::ensureDefaults();

        $results = [];
        $flags = [];
        $hardFailure = false;

        // R1: Validitas Spot & QR
        $spot = $activity->spot;
        $r1Pass = $spot !== null && $spot->status === 'ACTIVE';
        if (!$r1Pass) {
            $hardFailure = true;
            $flags[] = 'SPOT_INACTIVE_OR_MISSING';
        }
        $results[] = [
            'rule' => 'R1_QR_VALID',
            'result' => $r1Pass ? 'PASS' : 'FAIL',
            'detail' => $r1Pass ? 'Spot aktif dan token QR valid.' : 'Spot tidak ditemukan atau sedang tidak aktif.',
        ];

        // R2: Ketepatan Waktu Sesi (<= 60 menit sejak scan QR)
        $finalizeWindowMinutes = (int) FeedingSetting::getFloat('finalize_window_minutes', 60.0);
        $elapsedMinutes = $activity->scanned_at ? $activity->scanned_at->diffInMinutes(now()) : 999;
        $r2Pass = $elapsedMinutes <= $finalizeWindowMinutes;
        if (!$r2Pass) {
            $hardFailure = true;
            $flags[] = 'SESSION_EXPIRED';
        }
        $results[] = [
            'rule' => 'R2_SESSION_TIMELY',
            'result' => $r2Pass ? 'PASS' : 'FAIL',
            'detail' => "Sesi diselesaikan dalam {$elapsedMinutes} menit (batas {$finalizeWindowMinutes} menit).",
        ];

        // R4: Keunikan Bukti Foto (SHA-256 hash di tabel media_files)
        $photoCount = count($mediaIds);
        $hasCountValid = $photoCount >= 1 && $photoCount <= 3;
        $duplicateHashes = [];

        if ($hasCountValid) {
            $hashes = DB::table('media_files')
                ->whereIn('id', $mediaIds)
                ->pluck('sha256', 'id')
                ->filter()
                ->toArray();

            if (!empty($hashes)) {
                $reusedCount = DB::table('feeding_evidence')
                    ->join('media_files', 'feeding_evidence.media_id', '=', 'media_files.id')
                    ->where('feeding_evidence.activity_id', '!=', $activity->id)
                    ->whereIn('media_files.sha256', array_values($hashes))
                    ->count();

                if ($reusedCount > 0) {
                    $duplicateHashes[] = 'DUPLICATE_SHA256';
                }
            }
        }

        $r4Pass = $hasCountValid && empty($duplicateHashes);
        if (!$hasCountValid) {
            $hardFailure = true;
            $flags[] = 'INVALID_PHOTO_COUNT';
        } elseif (!empty($duplicateHashes)) {
            $flags[] = 'PHOTO_REUSED';
        }
        $results[] = [
            'rule' => 'R4_PHOTO_UNIQUE',
            'result' => !$hasCountValid ? 'FAIL' : ($r4Pass ? 'PASS' : 'REVIEW'),
            'detail' => $r4Pass
                ? "Bukti {$photoCount} foto unik tervalidasi melalui SHA-256."
                : (!$hasCountValid ? 'Jumlah foto wajib 1 sampai 3.' : 'Terdeteksi foto dengan hash SHA-256 yang pernah dipakai sebelumnya.'),
        ];

        // R5: Cooldown 6 Jam per Pengguna di Spot yang Sama
        $cooldownHours = (int) FeedingSetting::getFloat('cooldown_hours', 6.0);
        $recentSameSpotCount = FeedingActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('spot_id', $activity->spot_id)
            ->where('id', '!=', $activity->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED'])
            ->where('finalized_at', '>=', now()->subHours($cooldownHours))
            ->count();

        $r5Pass = $recentSameSpotCount === 0;
        if (!$r5Pass) {
            $hardFailure = true;
            $flags[] = 'COOLDOWN_VIOLATION';
        }
        $results[] = [
            'rule' => 'R5_COOLDOWN_PASSED',
            'result' => $r5Pass ? 'PASS' : 'FAIL',
            'detail' => $r5Pass
                ? "Tidak ada pengajuan di spot ini dalam {$cooldownHours} jam terakhir."
                : "Ditemukan pengajuan lain di spot ini dalam {$cooldownHours} jam terakhir.",
        ];

        // R6: Sampel Pengguna Baru (2 aktivitas pertama wajib UNDER_REVIEW sesuai AFS-06)
        $newUserThreshold = (int) FeedingSetting::getFloat('new_user_review_threshold', 2.0);
        $verifiedHistoryCount = FeedingActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->where('status', 'VERIFIED')
            ->count();

        $r6Pass = $verifiedHistoryCount >= $newUserThreshold;
        if (!$r6Pass) {
            $flags[] = 'NEW_USER_SAMPLE';
        }
        $results[] = [
            'rule' => 'R6_NEW_USER_SAMPLE',
            'result' => $r6Pass ? 'PASS' : 'REVIEW',
            'detail' => $r6Pass
                ? "Pengguna telah memiliki {$verifiedHistoryCount} riwayat terverifikasi."
                : "Pengguna baru ({$verifiedHistoryCount}/{$newUserThreshold} riwayat terverifikasi); diarahkan ke antrean review.",
        ];

        // R8: Rate Limit / Kewajaran Frekuensi Harian
        $todaySubmittedCount = FeedingActivity::query()
            ->where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED'])
            ->whereDate('finalized_at', now()->toDateString())
            ->count();

        $r8Pass = $todaySubmittedCount < 5;
        if (!$r8Pass) {
            $flags[] = 'HIGH_DAILY_FREQUENCY';
        }
        $results[] = [
            'rule' => 'R8_RATE_LIMIT_OK',
            'result' => $r8Pass ? 'PASS' : 'REVIEW',
            'detail' => $r8Pass
                ? "Frekuensi pengajuan hari ini wajar ({$todaySubmittedCount} kali)."
                : "Frekuensi pengajuan hari ini tinggi ({$todaySubmittedCount} kali); diarahkan ke antrean review.",
        ];

        // Simpan ke tabel feeding_rule_results
        FeedingRuleResult::where('activity_id', $activity->id)->delete();
        foreach ($results as $r) {
            FeedingRuleResult::create([
                'activity_id' => $activity->id,
                'rule' => $r['rule'],
                'result' => $r['result'],
                'detail' => $r['detail'],
            ]);
        }

        $activity->update(['flags' => $flags]);

        if ($hardFailure) {
            $finalStatus = 'REJECTED';
        } elseif (!empty($flags)) {
            $finalStatus = 'UNDER_REVIEW';
        } else {
            $finalStatus = 'VERIFIED';
        }

        return [
            'status' => $finalStatus,
            'flags' => $flags,
            'results' => $results,
        ];
    }
}
