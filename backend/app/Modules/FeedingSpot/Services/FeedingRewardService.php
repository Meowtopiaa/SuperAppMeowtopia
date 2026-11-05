<?php

namespace App\Modules\FeedingSpot\Services;

use App\Models\User;
use App\Modules\Core\Services\PointService;
use App\Modules\FeedingSpot\Events\FeedingVerified;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FeedingRewardService
{
    public function __construct(
        protected PointService $pointService
    ) {
    }

    /**
     * Calculate 14-day window aggregate and potential reward points (5-20) per Appendix A.1.
     */
    public function computePotentialReward(FeedingSpot $spot): array
    {
        $windowDays = (int) FeedingSetting::getValue('window_days', 14);
        $targetT = (int) FeedingSetting::getValue('target_activities_per_window', 14);
        $baseB = (int) FeedingSetting::getValue('base_points', 10);
        $minSpotAgeDays = (int) FeedingSetting::getValue('min_spot_age_days_for_formula', 7);
        $minCampusActivities = (int) FeedingSetting::getValue('min_campus_activities_for_formula', 30);
        $configVersion = (string) FeedingSetting::getValue('config_version', '1.1.0');

        $windowEnd = now();
        $windowStart = $windowEnd->copy()->subDays($windowDays);

        // N = verified count in window W
        $verifiedCountN = FeedingActivity::where('spot_id', $spot->id)
            ->where('status', 'VERIFIED')
            ->where('finalized_at', '>=', $windowStart)
            ->count();

        // P = submitted or under_review count in window W
        $pendingCountP = FeedingActivity::where('spot_id', $spot->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW'])
            ->where('finalized_at', '>=', $windowStart)
            ->count();

        // Update or insert aggregate snapshot for this spot
        FeedingAggregate::create([
            'spot_id' => $spot->id,
            'window_start' => $windowStart,
            'window_end' => $windowEnd,
            'verified_count' => $verifiedCountN,
            'pending_count' => $pendingCountP,
            'computed_at' => $windowEnd,
        ]);

        // Coverage C = min(N / T, 1)
        $coverageC = $targetT > 0 ? min($verifiedCountN / $targetT, 1.0) : 0.0;

        // Need S = 1 - min((N + P) / T, 1)
        $needS = $targetT > 0 ? 1.0 - min(($verifiedCountN + $pendingCountP) / $targetT, 1.0) : 0.0;

        // Check calibration mode: spot age < 7 days OR total campus verified activities < 30
        $spotAgeDays = $spot->created_at ? $spot->created_at->diffInDays($windowEnd) : 0;
        $totalCampusVerified = FeedingActivity::where('status', 'VERIFIED')->count();
        $isCalibration = ($spotAgeDays < $minSpotAgeDays) || ($totalCampusVerified < $minCampusActivities);

        if ($isCalibration) {
            $multiplierM = 1.0;
            $potentialPoints = $baseB; // 10 points during calibration
        } else {
            // Multiplier M = 0.5 + 1.5 * S
            $multiplierM = 0.5 + (1.5 * $needS);
            // Round half up: range 5 to 20 when B = 10
            $potentialPoints = (int) round($baseB * $multiplierM, 0, PHP_ROUND_HALF_UP);
            $potentialPoints = max(5, min(20, $potentialPoints));
        }

        return [
            'N' => $verifiedCountN,
            'P' => $pendingCountP,
            'T' => $targetT,
            'B' => $baseB,
            'coverage_c' => round($coverageC, 4),
            'need_s' => round($needS, 4),
            'multiplier_m' => round($multiplierM, 4),
            'potential_points' => $potentialPoints,
            'calibration_mode' => $isCalibration,
            'calibration_label' => $isCalibration ? 'Data belum cukup (mode kalibrasi)' : null,
            'config_version' => $configVersion,
            'computed_at' => $windowEnd->toIso8601String(),
        ];
    }

    /**
     * Get or compute 14-day aggregate summary for a spot.
     */
    public function getSpotAggregateSummary(FeedingSpot $spot): array
    {
        $staleMinutes = (int) FeedingSetting::getValue('aggregate_stale_minutes', 60);
        $targetT = (int) FeedingSetting::getValue('target_activities_per_window', 14);
        $windowDays = (int) FeedingSetting::getValue('window_days', 14);

        $latest = $spot->latestAggregate;
        $now = now();

        if (!$latest || !$latest->computed_at || $latest->computed_at->diffInSeconds($now) > 60) {
            $windowStart = $now->copy()->subDays($windowDays);
            $verifiedCount = FeedingActivity::where('spot_id', $spot->id)
                ->where('status', 'VERIFIED')
                ->where('finalized_at', '>=', $windowStart)
                ->count();
            $pendingCount = FeedingActivity::where('spot_id', $spot->id)
                ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW'])
                ->where('finalized_at', '>=', $windowStart)
                ->count();

            $latest = FeedingAggregate::create([
                'spot_id' => $spot->id,
                'window_start' => $windowStart,
                'window_end' => $now,
                'verified_count' => $verifiedCount,
                'pending_count' => $pendingCount,
                'computed_at' => $now,
            ]);
        }

        $isStale = $latest->computed_at && $latest->computed_at->diffInMinutes($now) > $staleMinutes;
        $coverageC = $targetT > 0 ? round(min($latest->verified_count / $targetT, 1.0), 4) : 0.0;

        return [
            'window_days' => $windowDays,
            'verified_count' => (int) $latest->verified_count,
            'pending_count' => (int) $latest->pending_count,
            'target_count' => $targetT,
            'coverage' => $coverageC,
            'computed_at' => $latest->computed_at?->toIso8601String(),
            'is_stale' => $isStale,
            'stale_label' => $isStale ? 'Data agregat usang (lebih dari 60 menit)' : null,
            'activity_label' => "{$latest->verified_count} aktivitas tercatat dalam {$windowDays} hari terakhir",
        ];
    }

    /**
     * Award points via PointService when an activity is VERIFIED, and record optional cat sighting.
     */
    public function processVerifiedActivity(FeedingActivity $activity): array
    {
        $user = User::find($activity->user_id);
        if (!$user) {
            $activity->update(['reward_status' => 'FAILED']);
            return [
                'reward_status' => 'FAILED',
                'points_awarded' => 0,
                'reward_capped' => false,
                'transaction_id' => null,
            ];
        }

        try {
            $idempotencyKey = 'feeding:' . $activity->id;
            $awardResult = $this->pointService->award(
                $user,
                'feeding.verified',
                'FeedingSpot',
                'feeding_activity',
                $activity->id,
                $idempotencyKey
            );

            $rewardCapped = (bool) ($awardResult['reward_capped'] ?? false);
            $pointsAwarded = (int) ($awardResult['points'] ?? 0);
            $rewardStatus = ($rewardCapped && $pointsAwarded === 0) ? 'NOT_ELIGIBLE' : 'CREDITED';

            $snapshot = is_array($activity->reward_snapshot) ? $activity->reward_snapshot : [];
            $snapshot['transaction_id'] = $awardResult['transaction_id'] ?? null;
            $snapshot['awarded_points'] = $pointsAwarded;
            $snapshot['reward_capped'] = $rewardCapped;
            $snapshot['awarded_at'] = now()->toIso8601String();

            $activity->update([
                'reward_status' => $rewardStatus,
                'reward_snapshot' => $snapshot,
            ]);

            // Record cat_sightings if cat_id is present (AFS-10 & Section 9.3)
            if ($activity->cat_id) {
                $existingSighting = DB::table('cat_sightings')
                    ->where('source', 'feeding')
                    ->where('request_id', $activity->id)
                    ->exists();

                if (!$existingSighting) {
                    DB::table('cat_sightings')->insert([
                        'id' => (string) Str::ulid(),
                        'cat_id' => $activity->cat_id,
                        'user_id' => $activity->user_id,
                        'source' => 'feeding',
                        'request_id' => $activity->id,
                        'location_lat' => $activity->location_lat,
                        'location_lng' => $activity->location_lng,
                        'occurred_at' => $activity->finalized_at ?? now(),
                        'metadata' => json_encode(['spot_id' => $activity->spot_id]),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            // Dispatch FeedingVerified event
            event(new FeedingVerified(
                $activity->id,
                $activity->user_id,
                $activity->spot_id,
                $activity->cat_id
            ));

            return [
                'reward_status' => $rewardStatus,
                'points_awarded' => $pointsAwarded,
                'reward_capped' => $rewardCapped,
                'transaction_id' => $awardResult['transaction_id'] ?? null,
            ];
        } catch (\Throwable $e) {
            $activity->update(['reward_status' => 'FAILED']);
            return [
                'reward_status' => 'FAILED',
                'points_awarded' => 0,
                'reward_capped' => false,
                'transaction_id' => null,
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Reverse previously credited points for an activity (AFS-12).
     */
    public function reverseActivityReward(FeedingActivity $activity, string $reason): array
    {
        $snapshot = is_array($activity->reward_snapshot) ? $activity->reward_snapshot : [];
        $transactionId = $snapshot['transaction_id'] ?? null;

        if (!$transactionId) {
            $tx = DB::table('point_transactions')
                ->where('source_module', 'FeedingSpot')
                ->where('source_ref_id', $activity->id)
                ->where('status', 'CREDITED')
                ->first();
            $transactionId = $tx?->id;
        }

        $reversalResult = null;
        if ($transactionId) {
            $reversalResult = $this->pointService->reverse($transactionId, $reason);
        }

        $snapshot['reversed_at'] = now()->toIso8601String();
        $snapshot['reversal_reason'] = $reason;

        $activity->update([
            'status' => 'REJECTED',
            'reward_status' => 'REVERSED',
            'reward_snapshot' => $snapshot,
        ]);

        return [
            'activity_id' => $activity->id,
            'status' => 'REJECTED',
            'reward_status' => 'REVERSED',
            'reversal' => $reversalResult,
        ];
    }
}

