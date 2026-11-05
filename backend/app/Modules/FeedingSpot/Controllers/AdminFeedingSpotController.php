<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Services\MediaService;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingReview;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRewardService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AdminFeedingSpotController extends Controller
{
    public function __construct(
        protected FeedingRewardService $rewardService,
        protected MediaService $mediaService
    ) {
    }

    /**
     * Check Spatie permission (never role string per AGENTS.md Rule #3).
     */
    protected function ensurePermission(Request $request, string $permission): ?JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->can($permission)) {
            return ApiResponse::error(
                "Akses ditolak. Diperlukan izin '{$permission}'.",
                403,
                'FORBIDDEN'
            );
        }
        return null;
    }

    /**
     * GET /api/v1/admin/feeding/spots
     * List all feeding spots (including INACTIVE) for spot_admin.
     */
    public function indexSpots(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $spots = FeedingSpot::with(['latestVerifiedActivity', 'latestAggregate'])
            ->orderBy('code')
            ->get()
            ->map(function (FeedingSpot $spot) {
                return [
                    'id' => $spot->id,
                    'code' => $spot->code,
                    'name' => $spot->name,
                    'description' => $spot->description,
                    'latitude' => $spot->latitude,
                    'longitude' => $spot->longitude,
                    'territory_id' => $spot->territory_id,
                    'qr_token' => $spot->qr_token,
                    'qr_payload' => 'MTP1.S.' . $spot->qr_token,
                    'status' => $spot->status,
                    'last_fed_at' => $spot->latestVerifiedActivity?->finalized_at?->toIso8601String(),
                    'aggregate' => $this->rewardService->getSpotAggregateSummary($spot),
                    'created_at' => $spot->created_at?->toIso8601String(),
                    'updated_at' => $spot->updated_at?->toIso8601String(),
                ];
            });

        return ApiResponse::success($spots, 'Daftar seluruh titik makan (admin) berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/spots
     * Create a new feeding spot with generated QR token (AFS-01).
     */
    public function storeSpot(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $validator = Validator::make($request->all(), [
            'code' => ['required', 'string', 'max:50', 'unique:feeding_spots,code'],
            'name' => ['required', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:500'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'exists:territories,id'],
            'status' => ['nullable', 'in:ACTIVE,TEMPORARILY_UNAVAILABLE,INACTIVE'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error(
                'Data titik makan tidak valid.',
                422,
                'VALIDATION_ERROR',
                $validator->errors()
            );
        }

        $spot = FeedingSpot::create([
            'code' => strtoupper(trim((string) $request->input('code'))),
            'name' => trim((string) $request->input('name')),
            'description' => $request->input('description'),
            'latitude' => (float) $request->input('latitude'),
            'longitude' => (float) $request->input('longitude'),
            'territory_id' => $request->input('territory_id'),
            'qr_token' => Str::random(32),
            'status' => $request->input('status', 'ACTIVE'),
        ]);

        return ApiResponse::created([
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => $spot->latitude,
            'longitude' => $spot->longitude,
            'territory_id' => $spot->territory_id,
            'qr_token' => $spot->qr_token,
            'qr_payload' => 'MTP1.S.' . $spot->qr_token,
            'status' => $spot->status,
            'last_fed_at' => null,
            'created_at' => $spot->created_at?->toIso8601String(),
        ], 'Titik makan baru berhasil dibuat.');
    }

    /**
     * PATCH/PUT /api/v1/admin/feeding/spots/{id}
     * Update feeding spot details or status (AFS-01).
     */
    public function updateSpot(Request $request, string $id): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $spot = FeedingSpot::find($id);
        if (!$spot) {
            return ApiResponse::error('Titik makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $validator = Validator::make($request->all(), [
            'code' => ['sometimes', 'string', 'max:50', 'unique:feeding_spots,code,' . $spot->id],
            'name' => ['sometimes', 'string', 'max:150'],
            'description' => ['nullable', 'string', 'max:500'],
            'latitude' => ['sometimes', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'exists:territories,id'],
            'status' => ['sometimes', 'in:ACTIVE,TEMPORARILY_UNAVAILABLE,INACTIVE'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error(
                'Data pembaruan titik makan tidak valid.',
                422,
                'VALIDATION_ERROR',
                $validator->errors()
            );
        }

        $spot->fill($validator->validated());
        if ($request->has('code')) {
            $spot->code = strtoupper(trim((string) $request->input('code')));
        }
        $spot->save();

        return ApiResponse::success([
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => $spot->latitude,
            'longitude' => $spot->longitude,
            'territory_id' => $spot->territory_id,
            'qr_token' => $spot->qr_token,
            'qr_payload' => 'MTP1.S.' . $spot->qr_token,
            'status' => $spot->status,
            'updated_at' => $spot->updated_at?->toIso8601String(),
        ], 'Titik makan berhasil diperbarui.');
    }

    /**
     * DELETE /api/v1/admin/feeding/spots/{id}
     * Deactivate spot by setting status to INACTIVE (AFS-01).
     */
    public function destroySpot(Request $request, string $id): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $spot = FeedingSpot::find($id);
        if (!$spot) {
            return ApiResponse::error('Titik makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $spot->update(['status' => 'INACTIVE']);

        return ApiResponse::success([
            'id' => $spot->id,
            'code' => $spot->code,
            'status' => $spot->status,
        ], 'Titik makan telah dinonaktifkan (INACTIVE).');
    }

    /**
     * POST /api/v1/admin/feeding/spots/{id}/qr/regenerate
     * Regenerate QR token for a feeding spot while preserving spot_id (AFS-01).
     */
    public function regenerateQr(Request $request, string $id): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $spot = FeedingSpot::find($id);
        if (!$spot) {
            return ApiResponse::error('Titik makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $oldToken = $spot->qr_token;
        $newToken = Str::random(32);

        $spot->update([
            'qr_token' => $newToken,
        ]);

        return ApiResponse::success([
            'spot_id' => $spot->id,
            'code' => $spot->code,
            'old_qr_token_revoked' => substr($oldToken, 0, 8) . '...',
            'qr_token' => $spot->qr_token,
            'qr_payload' => 'MTP1.S.' . $spot->qr_token,
            'regenerated_at' => now()->toIso8601String(),
        ], 'Token QR titik makan berhasil diperbarui. Token lama tidak lagi berlaku.');
    }

    /**
     * GET /api/v1/admin/feeding/spots/qr-sheet
     * Printable QR sheet data for all active/temporarily unavailable spots.
     */
    public function qrSheet(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $spots = FeedingSpot::whereIn('status', ['ACTIVE', 'TEMPORARILY_UNAVAILABLE'])
            ->orderBy('code')
            ->get()
            ->map(fn (FeedingSpot $spot) => [
                'spot_id' => $spot->id,
                'code' => $spot->code,
                'name' => $spot->name,
                'status' => $spot->status,
                'qr_token' => $spot->qr_token,
                'qr_payload' => 'MTP1.S.' . $spot->qr_token,
            ]);

        return ApiResponse::success($spots, 'Lembar QR titik makan siap cetak berhasil diambil.');
    }

    /**
     * GET /api/v1/admin/feeding/review-queue
     * List feeding activities with status UNDER_REVIEW for reviewers (AFS-07).
     */
    public function reviewQueue(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'feeding.review')) {
            return $denied;
        }

        $queue = FeedingActivity::with(['user:id,name,email', 'spot:id,code,name', 'evidence', 'ruleResults'])
            ->where('status', 'UNDER_REVIEW')
            ->orderBy('finalized_at')
            ->get()
            ->map(function (FeedingActivity $act) use ($request) {
                return [
                    'id' => $act->id,
                    'feeding_record_ref' => $act->feeding_record_ref,
                    'status' => $act->status,
                    'reward_status' => $act->reward_status,
                    'potential_points' => $act->potential_points,
                    'food_type' => $act->food_type,
                    'food_amount' => $act->food_amount,
                    'scanned_at' => $act->scanned_at?->toIso8601String(),
                    'intent_at' => $act->intent_at?->toIso8601String(),
                    'finalized_at' => $act->finalized_at?->toIso8601String(),
                    'flags' => $act->flags['reasons'] ?? [],
                    'can_review' => $act->user_id !== $request->user()->id,
                    'user' => $act->user ? [
                        'id' => $act->user->id,
                        'name' => $act->user->name,
                        'email' => $act->user->email,
                    ] : null,
                    'spot' => $act->spot ? [
                        'id' => $act->spot->id,
                        'code' => $act->spot->code,
                        'name' => $act->spot->name,
                    ] : null,
                    'evidence' => $act->evidence->map(fn ($ev) => [
                        'id' => $ev->id,
                        'media_id' => $ev->media_id,
                        'url' => $this->mediaService->getUrl($ev->media_id),
                        'captured_at' => $ev->captured_at?->toIso8601String(),
                    ])->values(),
                    'rule_results' => $act->ruleResults->map(fn ($rr) => [
                        'rule' => $rr->rule,
                        'result' => $rr->result,
                        'detail' => $rr->detail,
                    ])->values(),
                ];
            });

        return ApiResponse::success($queue, 'Antrean pemeriksaan aktivitas pakan berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/activities/{id}/review
     * Approve (VERIFIED) or reject (REJECTED) an activity. Reviewer cannot review their own activity (AFS-07).
     */
    public function reviewActivity(Request $request, string $id): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'feeding.review')) {
            return $denied;
        }

        $activity = FeedingActivity::with('spot')->find($id);
        if (!$activity) {
            return ApiResponse::error('Aktivitas pemberian makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $reviewer = $request->user();

        // AFS-07 Hard Rule: Reviewer cannot review their own submission
        if ($activity->user_id === $reviewer->id) {
            return ApiResponse::error(
                'Reviewer tidak diizinkan menilai pengajuan miliknya sendiri.',
                403,
                'SELF_REVIEW_FORBIDDEN'
            );
        }

        if (!in_array($activity->status, ['UNDER_REVIEW', 'SUBMITTED'], true)) {
            return ApiResponse::error(
                "Aktivitas berstatus '{$activity->status}' tidak dapat direview.",
                422,
                'INVALID_ACTIVITY_STATUS'
            );
        }

        $validator = Validator::make($request->all(), [
            'decision' => ['required', 'in:VERIFIED,REJECTED'],
            'reason' => ['required_if:decision,REJECTED', 'nullable', 'string', 'max:500'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error(
                'Keputusan review wajib berupa VERIFIED atau REJECTED (disertai alasan jika ditolak).',
                422,
                'VALIDATION_ERROR',
                $validator->errors()
            );
        }

        $decision = (string) $request->input('decision');
        $reason = $request->input('reason');

        $result = DB::transaction(function () use ($activity, $reviewer, $decision, $reason) {
            $reviewRecord = FeedingReview::create([
                'activity_id' => $activity->id,
                'reviewer_id' => $reviewer->id,
                'decision' => $decision,
                'reason' => $reason,
            ]);

            if ($decision === 'VERIFIED') {
                $activity->update(['status' => 'VERIFIED']);
                $rewardOutcome = $this->rewardService->processVerifiedActivity($activity->fresh());
            } else {
                $activity->update([
                    'status' => 'REJECTED',
                    'reward_status' => 'NOT_ELIGIBLE',
                ]);
                $rewardOutcome = [
                    'reward_status' => 'NOT_ELIGIBLE',
                    'points_awarded' => 0,
                    'reward_capped' => false,
                ];
            }

            if ($activity->spot) {
                $this->rewardService->getSpotAggregateSummary($activity->spot);
            }

            return [
                'activity' => $activity->fresh(),
                'review' => $reviewRecord,
                'reward_outcome' => $rewardOutcome,
            ];
        });

        /** @var FeedingActivity $updated */
        $updated = $result['activity'];
        $rewardOutcome = $result['reward_outcome'];

        return ApiResponse::success([
            'activity_id' => $updated->id,
            'status' => $updated->status,
            'reward_status' => $updated->reward_status,
            'points_awarded' => $rewardOutcome['points_awarded'],
            'reward_capped' => $rewardOutcome['reward_capped'],
            'review' => [
                'id' => $result['review']->id,
                'reviewer_id' => $reviewer->id,
                'decision' => $decision,
                'reason' => $reason,
                'reviewed_at' => $result['review']->created_at?->toIso8601String(),
            ],
        ], $decision === 'VERIFIED'
            ? 'Pengajuan aktivitas pakan disetujui (VERIFIED).'
            : 'Pengajuan aktivitas pakan ditolak (REJECTED).');
    }

    /**
     * POST /api/v1/admin/feeding/activities/{id}/reverse
     * Reverse a previously VERIFIED activity and deduct credited points via PointService::reverse (AFS-12).
     */
    public function reverseActivity(Request $request, string $id): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'feeding.review')) {
            return $denied;
        }

        $activity = FeedingActivity::with('spot')->find($id);
        if (!$activity) {
            return ApiResponse::error('Aktivitas pemberian makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $reviewer = $request->user();
        if ($activity->user_id === $reviewer->id) {
            return ApiResponse::error(
                'Reviewer tidak diizinkan membatalkan pengajuan miliknya sendiri.',
                403,
                'SELF_REVIEW_FORBIDDEN'
            );
        }

        $validator = Validator::make($request->all(), [
            'reason' => ['required', 'string', 'max:500'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error('Alasan koreksi/pembatalan wajib diisi.', 422, 'VALIDATION_ERROR', $validator->errors());
        }

        $reason = (string) $request->input('reason');

        $outcome = DB::transaction(function () use ($activity, $reviewer, $reason) {
            FeedingReview::create([
                'activity_id' => $activity->id,
                'reviewer_id' => $reviewer->id,
                'decision' => 'REVERSED',
                'reason' => $reason,
            ]);

            $res = $this->rewardService->reverseActivityReward($activity, $reason);

            if ($activity->spot) {
                $this->rewardService->getSpotAggregateSummary($activity->spot);
            }

            return $res;
        });

        return ApiResponse::success($outcome, 'Aktivitas pakan dan poin terkait telah dibatalkan (REVERSED).');
    }

    /**
     * GET /api/v1/admin/feeding/settings
     */
    public function getSettings(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        return ApiResponse::success(
            FeedingSetting::allEffective(),
            'Pengaturan modul Feeding Spot berhasil diambil.'
        );
    }

    /**
     * PUT /api/v1/admin/feeding/settings
     */
    public function updateSettings(Request $request): JsonResponse
    {
        if ($denied = $this->ensurePermission($request, 'spot.manage')) {
            return $denied;
        }

        $allowedKeys = array_keys(FeedingSetting::defaults());
        $payload = $request->only($allowedKeys);

        foreach ($payload as $key => $val) {
            FeedingSetting::setValue($key, $val);
        }

        return ApiResponse::success(
            FeedingSetting::allEffective(),
            'Pengaturan modul Feeding Spot berhasil diperbarui.'
        );
    }
}

