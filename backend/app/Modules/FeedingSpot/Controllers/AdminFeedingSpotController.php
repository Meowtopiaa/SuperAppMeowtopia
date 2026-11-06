<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Services\PointService;
use App\Modules\FeedingSpot\Events\FeedingVerified;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingReview;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRewardService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminFeedingSpotController extends Controller
{
    public function __construct(
        private readonly PointService $pointService,
        private readonly FeedingRewardService $rewardService,
    ) {}

    /**
     * POST /api/v1/admin/feeding/spots
     * Buat titik feeding spot baru beserta token QR resmi (AFS-01, MEOW-7).
     * Permission: spot.manage
     */
    public function storeSpot(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['required', 'string', 'max:64', 'unique:feeding_spots,code'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'status' => ['nullable', 'string', Rule::in(['ACTIVE', 'MAINTENANCE', 'TEMPORARILY_UNAVAILABLE', 'INACTIVE'])],
        ]);

        $qrToken = Str::random(32);

        $spot = FeedingSpot::create([
            'code' => strtoupper(trim($validated['code'])),
            'name' => trim($validated['name']),
            'description' => $validated['description'] ?? null,
            'latitude' => (float) $validated['latitude'],
            'longitude' => (float) $validated['longitude'],
            'territory_id' => $validated['territory_id'] ?? null,
            'qr_token' => $qrToken,
            'status' => $validated['status'] ?? 'ACTIVE',
        ]);

        return ApiResponse::created([
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'status' => $spot->status,
            'qr_token' => $spot->qr_token,
            'qr_payload' => "MTP1.S.{$spot->qr_token}",
        ], 'Titik feeding spot berhasil dibuat.');
    }

    /**
     * PATCH /api/v1/admin/feeding/spots/{id}
     * Perbarui data atau status feeding spot (ACTIVE, MAINTENANCE, TEMPORARILY_UNAVAILABLE, INACTIVE) (AFS-01, MEOW-7).
     * Permission: spot.manage
     */
    public function updateSpot(Request $request, string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $validated = $request->validate([
            'code' => ['sometimes', 'string', 'max:64', Rule::unique('feeding_spots', 'code')->ignore($spot->id)],
            'name' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'latitude' => ['sometimes', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'status' => ['sometimes', 'string', Rule::in(['ACTIVE', 'MAINTENANCE', 'TEMPORARILY_UNAVAILABLE', 'INACTIVE'])],
        ]);

        if (isset($validated['code'])) {
            $validated['code'] = strtoupper(trim($validated['code']));
        }

        $spot->update($validated);

        return ApiResponse::success([
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'status' => $spot->status,
        ], 'Titik feeding spot berhasil diperbarui.');
    }

    /**
     * POST /api/v1/admin/feeding/spots/{id}/qr
     * Regenerate token QR feeding spot dan otomatis mencabut token lama (AFS-01, MEOW-7).
     * Permission: spot.manage
     */
    public function regenerateQr(string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $newToken = Str::random(32);
        $spot->update(['qr_token' => $newToken]);

        return ApiResponse::success([
            'spot_id' => $spot->id,
            'code' => $spot->code,
            'qr_token' => $spot->qr_token,
            'qr_payload' => "MTP1.S.{$spot->qr_token}",
        ], 'Token QR feeding spot berhasil diperbarui.');
    }

    /**
     * GET /api/v1/admin/feeding/review-queue
     * Daftar antrean pengajuan pemberian makan berstatus UNDER_REVIEW (AFS-07, MEOW-12).
     * Permission: feeding.review
     */
    public function reviewQueue(Request $request): JsonResponse
    {
        $status = $request->filled('status')
            ? $request->string('status')->upper()->toString()
            : 'UNDER_REVIEW';

        $items = FeedingActivity::query()
            ->where('status', $status)
            ->with([
                'user:id,name,email,user_type',
                'spot:id,code,name,latitude,longitude,status',
                'cat:id,unique_code,name',
                'evidence',
                'ruleResults',
                'reviews.reviewer:id,name',
            ])
            ->orderBy('finalized_at')
            ->get()
            ->map(fn (FeedingActivity $a) => [
                'id' => $a->id,
                'feeding_record_ref' => $a->feeding_record_ref,
                'status' => $a->status,
                'reward_status' => $a->reward_status,
                'points_awarded' => $a->points_awarded,
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
                    'email' => $a->user->email,
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
                    'sort_order' => $e->sort_order,
                ])->values(),
                'rule_results' => $a->ruleResults->map(fn (FeedingRuleResult $r) => [
                    'rule' => $r->rule,
                    'result' => $r->result,
                    'detail' => $r->detail,
                ])->values(),
            ])
            ->values();

        return ApiResponse::success($items, 'Antrean review pemberian pakan berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/activities/{id}/review
     * Simpan keputusan reviewer (VERIFIED atau REJECTED) dengan larangan self-review (AFS-07, AFS-10, MEOW-12).
     * Permission: feeding.review
     */
    public function reviewActivity(Request $request, string $id): JsonResponse
    {
        $activity = FeedingActivity::with(['user', 'spot'])->find($id);
        if (!$activity) {
            return ApiResponse::error('Aktivitas pemberian pakan tidak ditemukan.', 404, 'ACTIVITY_NOT_FOUND');
        }

        $reviewer = $request->user();

        // AFS-07: Reviewer tidak boleh me-review pengajuannya sendiri
        if ($activity->user_id === $reviewer->id) {
            return ApiResponse::error(
                'Reviewer tidak diperbolehkan memeriksa pengajuan pemberian pakan miliknya sendiri.',
                403,
                'SELF_REVIEW_FORBIDDEN'
            );
        }

        $validated = $request->validate([
            'decision' => ['required', 'string', Rule::in(['VERIFIED', 'REJECTED'])],
            'notes' => ['nullable', 'string', 'max:1000'],
            'reason' => ['nullable', 'string', 'max:1000'],
        ]);

        if (!in_array($activity->status, ['UNDER_REVIEW', 'SUBMITTED', 'VERIFIED'], true)) {
            return ApiResponse::error(
                "Aktivitas berstatus {$activity->status} tidak dapat direview.",
                422,
                'INVALID_ACTIVITY_STATUS'
            );
        }

        $decision = $validated['decision'];
        $reason = $validated['notes'] ?? $validated['reason'] ?? null;

        $payload = DB::transaction(function () use ($activity, $reviewer, $decision, $reason) {
            FeedingReview::create([
                'activity_id' => $activity->id,
                'reviewer_id' => $reviewer->id,
                'decision' => $decision,
                'reason' => $reason,
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

                $pointsAwarded = (int) ($award['points'] ?? 0);
                $rewardCapped = (bool) ($award['reward_capped'] ?? false);
                $snapshot = $activity->reward_snapshot ?? [];

                $activity->update([
                    'status' => 'VERIFIED',
                    'reward_status' => 'CREDITED',
                    'potential_points' => $pointsAwarded,
                    'reward_snapshot' => array_merge($snapshot, $formulaSnapshot, [
                        'points_awarded' => $pointsAwarded,
                        'reward_capped' => $rewardCapped,
                        'transaction_id' => $award['transaction_id'] ?? null,
                        'review_reason' => $reason,
                    ]),
                ]);

                $this->refreshSpotAggregate($activity->spot_id);
                event(new FeedingVerified($activity->fresh()));

                return [
                    'activity_id' => $activity->id,
                    'decision' => 'VERIFIED',
                    'status' => 'VERIFIED',
                    'reward_status' => 'CREDITED',
                    'points_awarded' => $pointsAwarded,
                    'reward_capped' => $rewardCapped,
                    'reviewed_by' => $reviewer->id,
                    'reviewed_at' => now()->toIso8601String(),
                ];
            }

            // REJECTED: jika sebelumnya sudah CREDITED, jalankan reversal poin (AFS-12)
            if ($activity->reward_status === 'CREDITED') {
                $reversal = $this->rewardService->reverseReward(
                    $activity,
                    $reason ?? 'Dibatalkan oleh reviewer saat audit.',
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
                    'review_reason' => $reason,
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
                'reviewed_by' => $reviewer->id,
                'reviewed_at' => now()->toIso8601String(),
            ];
        });

        return ApiResponse::success($payload, 'Keputusan review berhasil disimpan.');
    }

    /**
     * Perbarui agregat 14 hari terakhir untuk spot (feeding_aggregates).
     */
    private function refreshSpotAggregate(string $spotId): FeedingAggregate
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

    /**
     * GET /api/v1/admin/feeding/spots/{id}/cats
     * Ambil daftar kucing yang terasosiasi dengan spot pakan (MEOW-23).
     */
    public function getSpotCats(string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $cats = $spot->cats()->select(['cats.id', 'cats.unique_code', 'cats.name', 'cats.presence_status', 'cats.health_status'])->get();

        return ApiResponse::success([
            'spot_id' => $spot->id,
            'spot_code' => $spot->code,
            'cats' => $cats,
        ], 'Daftar kucing terkait spot berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/spots/{id}/cats
     * Asosiasikan kucing dengan spot pakan (MEOW-23).
     */
    public function attachCats(Request $request, string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $validated = $request->validate([
            'cat_ids' => ['required', 'array', 'min:1'],
            'cat_ids.*' => ['required', 'string', 'size:26', 'exists:cats,id'],
        ]);

        $spot->cats()->syncWithoutDetaching($validated['cat_ids']);

        return ApiResponse::success([
            'spot_id' => $spot->id,
            'attached_count' => count($validated['cat_ids']),
        ], 'Kucing berhasil diasosiasikan dengan spot pakan.');
    }

    /**
     * DELETE /api/v1/admin/feeding/spots/{id}/cats/{catId}
     * Hapus asosiasi kucing dari spot pakan (MEOW-23).
     */
    public function detachCat(string $id, string $catId): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $spot->cats()->detach($catId);

        return ApiResponse::success(null, 'Asosiasi kucing dengan spot pakan berhasil dihapus.');
    }

    /**
     * GET /api/v1/admin/feeding/spots/{id}/qr-sheet
     * Tampilkan lembar cetak QR resmi untuk spot pakan (MEOW-21).
     */
    public function printQrSheet(string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        return view('feeding-spot::filament.qr-sheet', [
            'spot' => $spot,
        ]);
    }

    /**
     * GET /api/v1/admin/feeding/reviews/{id}
     * Halaman inspeksi bukti foto & hasil rule engine untuk reviewer (MEOW-22).
     */
    public function showReviewEvidence(string $id)
    {
        $activity = FeedingActivity::with(['user', 'spot', 'evidence', 'ruleResults'])
            ->where('id', $id)
            ->orWhere('feeding_record_ref', $id)
            ->first();

        if (!$activity) {
            return ApiResponse::error('Aktivitas pemberian pakan tidak ditemukan.', 404, 'ACTIVITY_NOT_FOUND');
        }

        return view('feeding-spot::filament.review-evidence', [
            'activity' => $activity,
        ]);
    }
}
