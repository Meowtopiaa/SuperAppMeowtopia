<?php

namespace App\Modules\FeedingSpot\Services;

use App\Models\User;
use App\Modules\Core\Services\PointService;
use App\Modules\FeedingSpot\Events\FeedingVerified;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingReview;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Service terpadu untuk antrean review & keputusan reviewer (MEOW-12 & MEOW-22).
 * Digunakan bersama oleh REST API Admin dan Filament Resource.
 */
class FeedingReviewService
{
    public function __construct(
        private readonly PointService $pointService,
        private readonly FeedingRewardService $rewardService,
    ) {}

    /**
     * Query dasar antrean review (AFS-07, MEOW-12, MEOW-22).
     * Menyembunyikan pengajuan milik reviewer sendiri bila $excludeSelf = true,
     * dan tidak memuat data pribadi sensitif (tanpa phone, identity_number, email).
     */
    public function getReviewQueueQuery(
        ?User $reviewer = null,
        bool $excludeSelf = true,
        string $status = 'UNDER_REVIEW'
    ): Builder {
        $query = FeedingActivity::query()
            ->where('status', strtoupper($status))
            ->with([
                'user:id,name,user_type',
                'spot:id,code,name,latitude,longitude,status',
                'cat:id,unique_code,name',
                'evidence',
                'ruleResults',
                'reviews.reviewer:id,name',
            ]);

        if ($excludeSelf && $reviewer !== null) {
            $query->where('user_id', '!=', $reviewer->id);
        }

        return $query;
    }

    /**
     * Format satu item aktivitas dalam antrean review beserta signed URL foto 10 menit,
     * flags sistem, dan hasil feeding_rule_results, tanpa data pribadi pengguna.
     */
    public function formatQueueItem(FeedingActivity $a): array
    {
        return [
            'id' => $a->id,
            'feeding_record_ref' => $a->feeding_record_ref,
            'status' => $a->status,
            'reward_status' => $a->reward_status,
            'points_awarded' => $a->points_awarded,
            'potential_points' => $a->potential_points,
            'food_type' => $a->food_type,
            'food_amount' => $a->food_amount,
            'notes' => $a->notes,
            'flags' => $a->flags ?? [],
            'scanned_at' => $a->scanned_at?->toIso8601String(),
            'submitted_at' => $a->finalized_at?->toIso8601String(),
            'verified_at' => $a->status === 'VERIFIED' ? $a->finalized_at?->toIso8601String() : null,
            'user' => $a->user ? [
                'id' => $a->user->id,
                'name' => $a->user->name,
                'user_type' => $a->user->user_type,
            ] : null,
            'spot' => $a->spot ? [
                'id' => $a->spot->id,
                'code' => $a->spot->code,
                'name' => $a->spot->name,
            ] : null,
            'cat' => $a->cat ? [
                'id' => $a->cat->id,
                'unique_code' => $a->cat->unique_code,
                'name' => $a->cat->name,
            ] : null,
            'evidence' => $a->evidence->map(fn (FeedingEvidence $e) => [
                'id' => $e->id,
                'media_id' => $e->media_id,
                'signed_url' => $e->signed_url,
                'media_url' => $e->media_url,
                'expires_in_seconds' => 600,
                'captured_at' => $e->captured_at?->toIso8601String(),
                'sort_order' => $e->sort_order,
            ])->values(),
            'rule_results' => $a->ruleResults->map(fn (FeedingRuleResult $r) => [
                'rule' => $r->rule,
                'result' => $r->result,
                'detail' => $r->detail,
            ])->values(),
        ];
    }

    /**
     * Eksekusi keputusan reviewer (VERIFIED atau REJECTED) dengan:
     * - Cek permission feeding.review (403)
     * - Larangan self-review (403 SELF_REVIEW_FORBIDDEN)
     * - Alasan wajib (disimpan ke feeding_reviews)
     * - Idempotensi keputusan: keputusan yang sama dikirim dua kali tidak memberi/mencabut poin dua kali
     * - Integrasi PointService::award() & PointService::reverse()
     */
    public function reviewActivity(
        FeedingActivity $activity,
        User $reviewer,
        string $decision,
        ?string $reason
    ): array {
        if (!$reviewer->can('feeding.review')) {
            throw new HttpException(403, 'Anda tidak memiliki izin feeding.review.');
        }

        // AFS-07: Reviewer tidak boleh me-review pengajuannya sendiri
        if ($activity->user_id === $reviewer->id) {
            throw new HttpException(
                403,
                'Reviewer tidak diperbolehkan memeriksa pengajuan pemberian pakan miliknya sendiri.'
            );
        }

        $decision = strtoupper(trim($decision));
        if (!in_array($decision, ['VERIFIED', 'REJECTED'], true)) {
            throw ValidationException::withMessages([
                'decision' => ['Keputusan review harus bernilai VERIFIED atau REJECTED.'],
            ]);
        }

        $trimmedReason = $reason !== null ? trim($reason) : '';
        if ($trimmedReason === '') {
            throw ValidationException::withMessages([
                'reason' => ['Alasan keputusan review wajib diisi.'],
            ]);
        }

        // Idempotensi: jika keputusan yang sama dikirim dua kali, jangan proses/beri poin dua kali
        if ($activity->status === $decision) {
            $snapshot = $activity->reward_snapshot ?? [];
            $pointsAwarded = (int) ($snapshot['points_awarded'] ?? ($decision === 'VERIFIED' ? $activity->potential_points : 0));
            $rewardCapped = (bool) ($snapshot['reward_capped'] ?? false);

            return [
                'activity_id' => $activity->id,
                'decision' => $decision,
                'status' => $activity->status,
                'reward_status' => $activity->reward_status,
                'points_awarded' => $decision === 'VERIFIED' ? $pointsAwarded : 0,
                'credited_points' => $decision === 'VERIFIED' ? $pointsAwarded : 0,
                'reward_capped' => $rewardCapped,
                'is_replay' => true,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now()->toIso8601String(),
            ];
        }

        if (!in_array($activity->status, ['UNDER_REVIEW', 'SUBMITTED', 'VERIFIED'], true)) {
            throw new HttpException(
                422,
                "Aktivitas berstatus {$activity->status} tidak dapat direview."
            );
        }

        return DB::transaction(function () use ($activity, $reviewer, $decision, $trimmedReason) {
            FeedingReview::create([
                'activity_id' => $activity->id,
                'reviewer_id' => $reviewer->id,
                'decision' => $decision,
                'reason' => $trimmedReason,
            ]);

            if ($decision === 'VERIFIED') {
                $formulaSnapshot = $this->rewardService->calculateRewardSnapshot($activity, now());
                $award = $this->pointService->award(
                    user: $activity->user,
                    ruleKey: 'feeding.verified',
                    sourceModule: 'FeedingSpot',
                    sourceType: 'feeding_activity',
                    sourceRefId: $activity->id,
                    idempotencyKey: "feeding.verified:{$activity->id}"
                );

                $rewardCapped = (bool) ($award['reward_capped'] ?? false) || ($formulaSnapshot['reward_capped'] ?? false);
                $pointsAwarded = $rewardCapped ? 0 : (int) ($award['points'] ?? 0);
                $snapshot = $activity->reward_snapshot ?? [];

                $activity->update([
                    'status' => 'VERIFIED',
                    'reward_status' => $pointsAwarded > 0 ? 'CREDITED' : 'NOT_ELIGIBLE',
                    'potential_points' => $pointsAwarded,
                    'reward_snapshot' => array_merge($snapshot, $formulaSnapshot, [
                        'points_awarded' => $pointsAwarded,
                        'reward_capped' => $rewardCapped,
                        'transaction_id' => $award['transaction_id'] ?? null,
                        'review_reason' => $trimmedReason,
                    ]),
                ]);

                $this->refreshSpotAggregate($activity->spot_id);
                event(new FeedingVerified($activity->fresh()));

                return [
                    'activity_id' => $activity->id,
                    'decision' => 'VERIFIED',
                    'status' => 'VERIFIED',
                    'reward_status' => $pointsAwarded > 0 ? 'CREDITED' : 'NOT_ELIGIBLE',
                    'points_awarded' => $pointsAwarded,
                    'credited_points' => $pointsAwarded,
                    'reward_capped' => $rewardCapped,
                    'is_replay' => (bool) ($award['is_replay'] ?? false),
                    'reviewed_by' => $reviewer->id,
                    'reviewed_at' => now()->toIso8601String(),
                ];
            }

            // REJECTED: jika sebelumnya sudah CREDITED, jalankan reversal poin (AFS-12)
            if ($activity->reward_status === 'CREDITED') {
                $reversal = $this->rewardService->reverseReward(
                    $activity,
                    $trimmedReason,
                    $reviewer->id
                );
                $activity->update(['status' => 'REJECTED']);
                $this->refreshSpotAggregate($activity->spot_id);

                return [
                    'activity_id' => $activity->id,
                    'decision' => 'REJECTED',
                    'status' => 'REJECTED',
                    'reward_status' => 'REVERSED',
                    'points_awarded' => 0,
                    'reversed_points' => $reversal['reversed_points'],
                    'new_balance' => $reversal['new_balance'],
                    'reward_capped' => false,
                    'is_replay' => false,
                    'reviewed_by' => $reviewer->id,
                    'reviewed_at' => now()->toIso8601String(),
                ];
            }

            $snapshot = $activity->reward_snapshot ?? [];
            $activity->update([
                'status' => 'REJECTED',
                'reward_status' => 'NOT_ELIGIBLE',
                'reward_snapshot' => array_merge($snapshot, [
                    'points_awarded' => 0,
                    'review_reason' => $trimmedReason,
                ]),
            ]);

            $this->refreshSpotAggregate($activity->spot_id);

            return [
                'activity_id' => $activity->id,
                'decision' => 'REJECTED',
                'status' => 'REJECTED',
                'reward_status' => 'NOT_ELIGIBLE',
                'points_awarded' => 0,
                'reward_capped' => false,
                'is_replay' => false,
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now()->toIso8601String(),
            ];
        });
    }

    /**
     * Perbarui agregat 14 hari terakhir untuk spot (feeding_aggregates).
     */
    public function refreshSpotAggregate(string $spotId): FeedingAggregate
    {
        $windowStart = now()->subDays(14)->startOfDay();
        $windowEnd = now();

        $verifiedCount = FeedingActivity::query()
            ->where('spot_id', $spotId)
            ->where('status', 'VERIFIED')
            ->where('finalized_at', '>=', $windowStart)
            ->count();

        $pendingCount = FeedingActivity::query()
            ->where('spot_id', $spotId)
            ->where('status', 'UNDER_REVIEW')
            ->where('finalized_at', '>=', $windowStart)
            ->count();

        return FeedingAggregate::updateOrCreate(
            ['spot_id' => $spotId],
            [
                'window_start' => $windowStart,
                'window_end' => $windowEnd,
                'verified_count' => $verifiedCount,
                'pending_count' => $pendingCount,
                'computed_at' => now(),
            ]
        );
    }
}

