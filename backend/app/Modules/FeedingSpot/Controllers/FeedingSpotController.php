<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\Core\Services\MediaService;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRewardService;
use App\Modules\FeedingSpot\Services\FeedingRuleEngine;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class FeedingSpotController extends Controller
{
    public function __construct(
        protected FeedingRuleEngine $ruleEngine,
        protected FeedingRewardService $rewardService,
        protected MediaService $mediaService
    ) {
    }

    /**
     * GET /api/v1/feeding/spots
     * List visible feeding spots (ACTIVE & TEMPORARILY_UNAVAILABLE; INACTIVE hidden per AFS-01)
     * with last_fed_at (AFS-02) and 14-day aggregate summary (AFS-09).
     */
    public function index(Request $request): JsonResponse
    {
        $spots = FeedingSpot::with(['latestVerifiedActivity', 'latestAggregate', 'cats:id,unique_code,name,color_pattern'])
            ->whereIn('status', ['ACTIVE', 'TEMPORARILY_UNAVAILABLE'])
            ->orderBy('name')
            ->get();

        $data = $spots->map(fn (FeedingSpot $spot) => $this->formatSpot($spot));

        return ApiResponse::success($data, 'Daftar titik makan berhasil diambil.');
    }

    /**
     * GET /api/v1/feeding/spots/{id}
     * Detail of a specific feeding spot with last_fed_at, aggregate, and recent verified feedings.
     */
    public function show(string $id): JsonResponse
    {
        $spot = FeedingSpot::with(['latestVerifiedActivity', 'latestAggregate', 'cats:id,unique_code,name,color_pattern'])
            ->whereIn('status', ['ACTIVE', 'TEMPORARILY_UNAVAILABLE'])
            ->where(function ($q) use ($id) {
                $q->where('id', $id)->orWhere('code', $id);
            })
            ->first();

        if (!$spot) {
            return ApiResponse::error('Titik makan tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $recentActivities = FeedingActivity::with('user:id,name')
            ->where('spot_id', $spot->id)
            ->where('status', 'VERIFIED')
            ->latest('finalized_at')
            ->limit(10)
            ->get()
            ->map(fn (FeedingActivity $act) => [
                'id' => $act->id,
                'feeding_record_ref' => $act->feeding_record_ref,
                'feeder_name' => $act->user?->name ?? 'Kontributor Meowtopia',
                'food_type' => $act->food_type,
                'food_amount' => $act->food_amount,
                'finalized_at' => $act->finalized_at?->toIso8601String(),
            ]);

        $payload = $this->formatSpot($spot);
        $payload['recent_verified_activities'] = $recentActivities;

        return ApiResponse::success($payload, 'Detail titik makan berhasil diambil.');
    }

    /**
     * POST /api/v1/feeding/activities †
     * Scan spot QR token and open a DRAFT feeding session (AFS-03, AFS-04, AFS-06).
     */
    public function startSession(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'qr_token' => ['required', 'string'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error(
                'Token QR spot wajib diisi.',
                422,
                'VALIDATION_ERROR',
                $validator->errors()
            );
        }

        $user = $request->user();
        $rawToken = (string) $request->input('qr_token');

        $validation = $this->ruleEngine->validateSpotAndCooldownForNewSession($rawToken, $user->id);
        if (!$validation['ok']) {
            return ApiResponse::error(
                $validation['message'],
                $validation['http_status'],
                $validation['code'],
                $validation['errors'] ?? null
            );
        }

        /** @var FeedingSpot $spot */
        $spot = $validation['spot'];

        $intentMinutes = (int) FeedingSetting::getValue('intent_deadline_minutes', 15);
        $finalizeMinutes = (int) FeedingSetting::getValue('finalize_deadline_minutes', 60);
        $now = now();
        $intentDeadline = $now->copy()->addMinutes($intentMinutes);
        $finalizeDeadline = $now->copy()->addMinutes($finalizeMinutes);

        $activity = DB::transaction(function () use ($user, $spot, $now, $intentDeadline, $finalizeDeadline) {
            $ref = 'AFS-' . $now->format('Ymd') . '-' . strtoupper(Str::random(6));

            $act = FeedingActivity::create([
                'feeding_record_ref' => $ref,
                'user_id' => $user->id,
                'spot_id' => $spot->id,
                'location_lat' => $spot->latitude,
                'location_lng' => $spot->longitude,
                'status' => 'DRAFT',
                'scanned_at' => $now,
                'intent_at' => null,
                'intent_deadline_at' => $intentDeadline,
                'finalize_deadline_at' => $finalizeDeadline,
                'food_type' => 'dry_food',
                'reward_status' => 'PENDING',
                'potential_points' => 0,
                'flags' => [
                    'spot_qr_token_snapshot' => $spot->qr_token,
                    'spot_status_snapshot' => $spot->status,
                ],
            ]);

            FeedingRuleResult::create([
                'activity_id' => $act->id,
                'rule' => 'R1',
                'result' => 'PASS',
                'detail' => 'Token QR spot valid dan status spot ACTIVE saat sesi dibuat.',
            ]);

            return $act;
        });

        return ApiResponse::created([
            'activity_id' => $activity->id,
            'feeding_record_ref' => $activity->feeding_record_ref,
            'status' => $activity->status,
            'reward_status' => $activity->reward_status,
            'spot' => $this->formatSpot($spot),
            'scanned_at' => $activity->scanned_at->toIso8601String(),
            'intent_deadline_at' => $activity->intent_deadline_at->toIso8601String(),
            'finalize_deadline_at' => $activity->finalize_deadline_at->toIso8601String(),
        ], 'Sesi pemberian makan berhasil dibuka. Konfirmasi niat memberi makan dalam 15 menit.');
    }

    /**
     * POST /api/v1/feeding/activities/{id}/intent †
     * Record user's intent to feed within 15 minutes of scan (AFS-04, Rule R2).
     */
    public function confirmIntent(Request $request, string $id): JsonResponse
    {
        $activity = FeedingActivity::find($id);
        if (!$activity) {
            return ApiResponse::error('Sesi aktivitas tidak ditemukan.', 404, 'NOT_FOUND');
        }

        if ($activity->user_id !== $request->user()->id) {
            return ApiResponse::error('Anda tidak memiliki akses ke sesi aktivitas ini.', 403, 'FORBIDDEN');
        }

        // If intent was already confirmed on this DRAFT session, return idempotently
        if ($activity->status === 'DRAFT' && $activity->intent_at !== null) {
            return ApiResponse::success([
                'activity_id' => $activity->id,
                'status' => $activity->status,
                'intent_at' => $activity->intent_at->toIso8601String(),
                'finalize_deadline_at' => $activity->finalize_deadline_at?->toIso8601String(),
            ], 'Konfirmasi memberi makan sudah tercatat.');
        }

        $windowCheck = $this->ruleEngine->validateIntentWindow($activity);
        if (!$windowCheck['ok']) {
            return ApiResponse::error(
                $windowCheck['message'],
                $windowCheck['http_status'],
                $windowCheck['code']
            );
        }

        $activity->update([
            'intent_at' => now(),
        ]);

        return ApiResponse::success([
            'activity_id' => $activity->id,
            'status' => $activity->status,
            'intent_at' => $activity->intent_at->toIso8601String(),
            'finalize_deadline_at' => $activity->finalize_deadline_at?->toIso8601String(),
        ], 'Konfirmasi memberi makan berhasil dicatat. Silakan ambil foto bukti dan selesaikan sebelum batas waktu.');
    }

    /**
     * POST /api/v1/feeding/activities/{id}/finalize †
     * Finalize feeding activity with 1-3 camera photos, run rules R1-R8, and process reward (AFS-04 to AFS-11).
     */
    public function finalizeSession(Request $request, string $id): JsonResponse
    {
        $activity = FeedingActivity::with('spot')->find($id);
        if (!$activity) {
            return ApiResponse::error('Sesi aktivitas tidak ditemukan.', 404, 'NOT_FOUND');
        }

        if ($activity->user_id !== $request->user()->id) {
            return ApiResponse::error('Anda tidak memiliki akses ke sesi aktivitas ini.', 403, 'FORBIDDEN');
        }

        $validator = Validator::make($request->all(), [
            'media_ids' => ['required', 'array', 'min:1', 'max:3'],
            'media_ids.*' => ['required', 'string'],
            'food_type' => ['required', 'string', 'max:50'],
            'food_amount' => ['nullable', 'string', 'max:100'],
            'cat_code' => ['nullable', 'string', 'max:100'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::error(
                'Data finalisasi tidak lengkap atau tidak valid.',
                422,
                'VALIDATION_ERROR',
                $validator->errors()
            );
        }

        $mediaIds = $request->input('media_ids', []);
        $evaluation = $this->ruleEngine->evaluateFinalization($activity, $mediaIds);

        if (!$evaluation['ok']) {
            return ApiResponse::error(
                $evaluation['message'],
                $evaluation['http_status'],
                $evaluation['code']
            );
        }

        // Resolve optional cat_code without failing the submission if invalid (AFS-10)
        $resolvedCatId = $this->resolveOptionalCatId($request->input('cat_code'));

        $result = DB::transaction(function () use ($request, $activity, $evaluation, $resolvedCatId) {
            $spot = $activity->spot;
            $rewardSnapshot = $this->rewardService->computePotentialReward($spot);
            $potentialPoints = (int) ($rewardSnapshot['potential_points'] ?? 10);

            if ($request->filled('notes')) {
                $rewardSnapshot['notes'] = trim((string) $request->input('notes'));
            }

            // Save evidence rows
            FeedingEvidence::where('activity_id', $activity->id)->delete();
            foreach ($evaluation['ordered_media_ids'] as $idx => $mediaId) {
                $mediaRow = $evaluation['media_files'][$mediaId] ?? null;
                FeedingEvidence::create([
                    'activity_id' => $activity->id,
                    'media_id' => $mediaId,
                    'captured_at' => $mediaRow?->captured_at ?? now(),
                    'sort_order' => $idx,
                ]);
            }

            $finalStatus = $evaluation['status']; // UNDER_REVIEW or VERIFIED
            $now = now();

            $activity->update([
                'status' => $finalStatus,
                'intent_at' => $activity->intent_at ?? $now,
                'finalized_at' => $now,
                'food_type' => (string) $request->input('food_type'),
                'food_amount' => $request->input('food_amount'),
                'cat_id' => $resolvedCatId,
                'reward_status' => 'PENDING',
                'potential_points' => $potentialPoints,
                'reward_snapshot' => $rewardSnapshot,
                'flags' => $evaluation['flags'],
            ]);

            $rewardOutcome = [
                'reward_status' => 'PENDING',
                'points_awarded' => 0,
                'reward_capped' => false,
                'transaction_id' => null,
            ];

            if ($finalStatus === 'VERIFIED') {
                $rewardOutcome = $this->rewardService->processVerifiedActivity($activity->fresh());
            } else {
                // Refresh spot aggregate so pending_count P includes this UNDER_REVIEW activity
                $this->rewardService->getSpotAggregateSummary($spot);
            }

            return [
                'activity' => $activity->fresh(['spot', 'evidence', 'ruleResults']),
                'reward_outcome' => $rewardOutcome,
            ];
        });

        /** @var FeedingActivity $updatedActivity */
        $updatedActivity = $result['activity'];
        $rewardOutcome = $result['reward_outcome'];

        $message = $updatedActivity->status === 'VERIFIED'
            ? 'Aktivitas pemberian makan terverifikasi.'
            : 'Pengajuan diterima untuk pemeriksaan.';

        return ApiResponse::success([
            'activity_id' => $updatedActivity->id,
            'feeding_record_ref' => $updatedActivity->feeding_record_ref,
            'status' => $updatedActivity->status,
            'reward_status' => $updatedActivity->reward_status,
            'potential_points' => $updatedActivity->potential_points,
            'points_awarded' => $rewardOutcome['points_awarded'],
            'reward_capped' => $rewardOutcome['reward_capped'],
            'flags' => $updatedActivity->flags['reasons'] ?? [],
            'finalized_at' => $updatedActivity->finalized_at?->toIso8601String(),
        ], $message);
    }

    /**
     * GET /api/v1/feeding/activities/mine
     * Authenticated user's feeding history with separate activity status and reward status (AFS-08).
     */
    public function myActivities(Request $request): JsonResponse
    {
        $activities = FeedingActivity::with(['spot', 'evidence', 'ruleResults', 'reviews'])
            ->where('user_id', $request->user()->id)
            ->whereNotIn('status', ['DRAFT'])
            ->latest('scanned_at')
            ->get()
            ->map(function (FeedingActivity $act) {
                $latestReview = $act->reviews->first();
                $snapshot = is_array($act->reward_snapshot) ? $act->reward_snapshot : [];

                return [
                    'id' => $act->id,
                    'feeding_record_ref' => $act->feeding_record_ref,
                    'status' => $act->status,
                    'reward_status' => $act->reward_status,
                    'potential_points' => $act->potential_points,
                    'points_awarded' => (int) ($snapshot['awarded_points'] ?? 0),
                    'reward_capped' => (bool) ($snapshot['reward_capped'] ?? false),
                    'food_type' => $act->food_type,
                    'food_amount' => $act->food_amount,
                    'notes' => $snapshot['notes'] ?? null,
                    'cat_id' => $act->cat_id,
                    'scanned_at' => $act->scanned_at?->toIso8601String(),
                    'intent_at' => $act->intent_at?->toIso8601String(),
                    'finalized_at' => $act->finalized_at?->toIso8601String(),
                    'flags' => $act->flags['reasons'] ?? [],
                    'spot' => $act->spot ? [
                        'id' => $act->spot->id,
                        'code' => $act->spot->code,
                        'name' => $act->spot->name,
                        'status' => $act->spot->status,
                    ] : null,
                    'evidence' => $act->evidence->map(fn ($ev) => [
                        'id' => $ev->id,
                        'media_id' => $ev->media_id,
                        'url' => $this->mediaService->getUrl($ev->media_id),
                        'captured_at' => $ev->captured_at?->toIso8601String(),
                    ])->values(),
                    'review' => $latestReview ? [
                        'decision' => $latestReview->decision,
                        'reason' => $latestReview->reason,
                        'reviewed_at' => $latestReview->created_at?->toIso8601String(),
                    ] : null,
                ];
            });

        return ApiResponse::success($activities, 'Riwayat aktivitas pemberian makan berhasil diambil.');
    }

    /**
     * GET /api/v1/feeding/heatmap?days=14
     * 14-day coverage per spot and per campus zone (AFS-09 & Appendix A.1).
     */
    public function heatmap(Request $request): JsonResponse
    {
        $days = max(1, min(90, (int) $request->query('days', 14)));
        $targetT = (int) FeedingSetting::getValue('target_activities_per_window', 14);
        $minSpotAgeDays = (int) FeedingSetting::getValue('min_spot_age_days_for_formula', 7);
        $windowStart = now()->subDays($days);

        $spots = FeedingSpot::with('latestVerifiedActivity')
            ->whereIn('status', ['ACTIVE', 'TEMPORARILY_UNAVAILABLE'])
            ->get();

        $territories = DB::table('territories')->get()->keyBy('id');

        $spotItems = [];
        $zoneBuckets = [];

        foreach ($spots as $spot) {
            $verifiedN = FeedingActivity::where('spot_id', $spot->id)
                ->where('status', 'VERIFIED')
                ->where('finalized_at', '>=', $windowStart)
                ->count();

            $pendingP = FeedingActivity::where('spot_id', $spot->id)
                ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW'])
                ->where('finalized_at', '>=', $windowStart)
                ->count();

            $coverageC = $targetT > 0 ? round(min($verifiedN / $targetT, 1.0), 4) : 0.0;
            $spotAgeDays = $spot->created_at ? $spot->created_at->diffInDays(now()) : 0;
            $hasSufficientData = $spotAgeDays >= $minSpotAgeDays;
            $lastFedAt = $spot->latestVerifiedActivity?->finalized_at?->toIso8601String();

            $spotData = [
                'spot_id' => $spot->id,
                'code' => $spot->code,
                'name' => $spot->name,
                'status' => $spot->status,
                'territory_id' => $spot->territory_id,
                'latitude' => $spot->latitude,
                'longitude' => $spot->longitude,
                'last_fed_at' => $lastFedAt,
                'window_days' => $days,
                'verified_count' => $verifiedN,
                'pending_count' => $pendingP,
                'target_count' => $targetT,
                'coverage' => $coverageC,
                'has_sufficient_data' => $hasSufficientData,
                'activity_label' => "{$verifiedN} aktivitas tercatat dalam {$days} hari terakhir",
                'computed_at' => now()->toIso8601String(),
            ];

            $spotItems[] = $spotData;

            if ($spot->territory_id && $spot->status === 'ACTIVE') {
                $tid = $spot->territory_id;
                if (!isset($zoneBuckets[$tid])) {
                    $tRow = $territories[$tid] ?? null;
                    $zoneBuckets[$tid] = [
                        'territory_id' => $tid,
                        'code' => $tRow?->code ?? 'UNKNOWN',
                        'name' => $tRow?->name ?? 'Zona Kampus',
                        'active_spots_count' => 0,
                        'total_verified_count' => 0,
                        'coverages_for_mean' => [],
                    ];
                }
                $zoneBuckets[$tid]['active_spots_count']++;
                $zoneBuckets[$tid]['total_verified_count'] += $verifiedN;
                $zoneBuckets[$tid]['coverages_for_mean'][] = $coverageC;
            }
        }

        $zones = array_values(array_map(function (array $z) {
            $covs = $z['coverages_for_mean'];
            $avgCoverage = !empty($covs) ? round(array_sum($covs) / count($covs), 4) : 0.0;
            unset($z['coverages_for_mean']);
            $z['average_coverage'] = $avgCoverage;
            return $z;
        }, $zoneBuckets));

        return ApiResponse::success([
            'window_days' => $days,
            'target_per_spot' => $targetT,
            'computed_at' => now()->toIso8601String(),
            'spots' => $spotItems,
            'zones' => $zones,
        ], 'Data heatmap dan agregat aktivitas pakan berhasil diambil.');
    }

    /**
     * Format spot object consistently with last_fed_at (AFS-02) and 14-day aggregate (AFS-09).
     */
    protected function formatSpot(FeedingSpot $spot): array
    {
        $lastFedAt = $spot->latestVerifiedActivity?->finalized_at;
        $aggregate = $this->rewardService->getSpotAggregateSummary($spot);

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
            'last_fed_at' => $lastFedAt?->toIso8601String(),
            'aggregate' => $aggregate,
            'cats' => $spot->relationLoaded('cats') ? $spot->cats : [],
            'created_at' => $spot->created_at?->toIso8601String(),
            'updated_at' => $spot->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Resolve optional cat_code from collar QR or unique_code without throwing (AFS-10).
     */
    protected function resolveOptionalCatId(?string $rawCatCode): ?string
    {
        if (!$rawCatCode || trim($rawCatCode) === '') {
            return null;
        }

        try {
            $code = trim($rawCatCode);
            $parts = explode('.', $code);

            if (count($parts) === 3 && $parts[0] === 'MTP1' && $parts[1] === 'C') {
                $qrRow = DB::table('cat_qr_tokens')
                    ->where('token', $parts[2])
                    ->where('status', 'ACTIVE')
                    ->first();
                return $qrRow?->cat_id;
            }

            $cat = Cat::where('unique_code', $code)->orWhere('id', $code)->first();
            return $cat?->id;
        } catch (\Throwable) {
            return null;
        }
    }
}
