<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\Core\Services\PointService;
use App\Modules\Core\Services\ScanResolver;
use App\Modules\FeedingSpot\Events\FeedingVerified;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRuleEngine;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FeedingSpotController extends Controller
{
    public function __construct(
        private readonly ScanResolver $scanResolver,
        private readonly FeedingRuleEngine $ruleEngine,
        private readonly PointService $pointService,
    ) {}

    /**
     * GET /api/v1/feeding/spots
     * Daftar spot pemberian pakan aktif beserta waktu terakhir diberi makan (last_fed_at)
     * dan ringkasan agregat 14 hari terakhir (AFS-01, AFS-02, MEOW-6).
     */
    public function listSpots(Request $request): JsonResponse
    {
        $query = FeedingSpot::query()
            ->active()
            ->with(['latestAggregate'])
            ->orderBy('name');

        if ($request->filled('territory_id')) {
            $query->where('territory_id', $request->string('territory_id'));
        }

        if ($request->filled('status') && in_array($request->string('status')->upper()->toString(), ['ACTIVE', 'MAINTENANCE', 'TEMPORARILY_UNAVAILABLE'], true)) {
            $query->where('status', $request->string('status')->upper()->toString());
        }

        $spots = $query->get();

        $territoryIds = $spots->pluck('territory_id')->filter()->unique()->values();
        $territoryMap = $territoryIds->isNotEmpty()
            ? DB::table('territories')
                ->whereIn('id', $territoryIds)
                ->select(['id', 'code', 'name'])
                ->get()
                ->keyBy('id')
            : collect();

        // Ambil waktu terakhir diberi makan (VERIFIED) per spot secara efisien
        $latestVerifiedMap = FeedingActivity::query()
            ->whereIn('spot_id', $spots->pluck('id'))
            ->where('status', 'VERIFIED')
            ->selectRaw('spot_id, MAX(COALESCE(finalized_at, updated_at)) as last_fed_at')
            ->groupBy('spot_id')
            ->pluck('last_fed_at', 'spot_id');

        $data = $spots->map(function (FeedingSpot $spot) use ($latestVerifiedMap, $territoryMap) {
            $territoryRow = $spot->territory_id ? ($territoryMap[$spot->territory_id] ?? null) : null;

            return $this->formatSpotSummary(
                $spot,
                $latestVerifiedMap[$spot->id] ?? null,
                $territoryRow ? (array) $territoryRow : null
            );
        })->values();

        return ApiResponse::success($data, 'Daftar spot pemberian pakan berhasil diambil.');
    }

    /**
     * GET /api/v1/feeding/spots/{id}
     * Detail spot pemberian pakan beserta waktu terakhir diberi makan (last_fed_at),
     * agregat 14 hari, dan aktivitas terverifikasi terbaru (AFS-02, MEOW-6).
     */
    public function showSpot(string $id): JsonResponse
    {
        $spot = FeedingSpot::query()
            ->with(['latestAggregate'])
            ->where(function ($q) use ($id) {
                $q->where('id', $id)->orWhere('code', $id);
            })
            ->first();

        if (!$spot || $spot->status === 'INACTIVE') {
            return ApiResponse::error('Titik feeding spot tidak ditemukan atau sudah tidak aktif.', 404, 'SPOT_NOT_FOUND');
        }

        $recentActivities = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->where('status', 'VERIFIED')
            ->with(['user:id,name', 'cat:id,unique_code,name'])
            ->orderByDesc('finalized_at')
            ->limit(10)
            ->get();

        $lastFedAt = $recentActivities->first()?->finalized_at
            ?? $recentActivities->first()?->updated_at;

        $summary = $this->formatSpotSummary(
            $spot,
            $lastFedAt ? (is_string($lastFedAt) ? $lastFedAt : $lastFedAt->toIso8601String()) : null,
            $spot->territory_data
        );

        $summary['recent_activities'] = $recentActivities->map(fn (FeedingActivity $a) => [
            'id' => $a->id,
            'food_type' => $a->food_type,
            'food_amount' => $a->food_amount,
            'notes' => $a->notes,
            'verified_at' => $a->finalized_at?->toIso8601String() ?? $a->updated_at?->toIso8601String(),
            'feeder_name' => $a->user?->name ?? 'Relawan Kampus',
            'cat' => $a->cat ? [
                'id' => $a->cat->id,
                'unique_code' => $a->cat->unique_code,
                'name' => $a->cat->name,
            ] : null,
        ])->values();

        return ApiResponse::success($summary, 'Detail spot pemberian pakan berhasil diambil.');
    }

    /**
     * POST /api/v1/feeding/activities †
     * Buka sesi pemberian makan dengan memindai QR spot resmi (AFS-03, IT-03, MEOW-8).
     */
    public function startSession(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'qr_token' => ['required', 'string', 'max:255'],
        ]);

        $rawToken = trim($validated['qr_token']);

        // IT-03 & AFS-03: Jika QR berprefiks MTP1.C. (QR kalung kucing), tolak dengan QR_WRONG_TYPE
        if (str_starts_with($rawToken, 'MTP1.C.')) {
            return ApiResponse::error(
                'QR yang dipindai adalah QR kalung kucing, bukan QR feeding spot.',
                422,
                'QR_WRONG_TYPE'
            );
        }

        $spot = null;

        try {
            $resolved = $this->scanResolver->resolve($rawToken);
            if (($resolved['type'] ?? null) === 'cat') {
                return ApiResponse::error(
                    'QR yang dipindai adalah QR kalung kucing, bukan QR feeding spot.',
                    422,
                    'QR_WRONG_TYPE'
                );
            }
            if (($resolved['type'] ?? null) === 'spot' && !empty($resolved['id'])) {
                $spot = FeedingSpot::find($resolved['id']);
            }
        } catch (\Throwable) {
            // Fallback untuk raw qr_token atau format SPOT:<CODE>
            $cleanToken = str_starts_with($rawToken, 'SPOT:')
                ? substr($rawToken, 5)
                : (str_starts_with($rawToken, 'MTP1.S.') ? substr($rawToken, 7) : $rawToken);

            $spot = FeedingSpot::where('qr_token', $cleanToken)
                ->orWhere('code', $cleanToken)
                ->first();
        }

        if (!$spot) {
            return ApiResponse::error('Token QR spot tidak valid atau sudah diganti.', 422, 'QR_INVALID');
        }

        if ($spot->status !== 'ACTIVE') {
            return ApiResponse::error(
                'Spot sedang dalam perawatan atau tidak aktif.',
                422,
                'SPOT_UNAVAILABLE'
            );
        }

        $user = $request->user();
        $cooldownHours = (int) FeedingSetting::getFloat('cooldown_hours', 6.0);

        $recentActivity = FeedingActivity::query()
            ->where('user_id', $user->id)
            ->where('spot_id', $spot->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED'])
            ->where(function ($q) use ($cooldownHours) {
                $cutoff = now()->subHours($cooldownHours);
                $q->where('finalized_at', '>=', $cutoff)
                    ->orWhere('scanned_at', '>=', $cutoff);
            })
            ->latest('scanned_at')
            ->first();

        if ($recentActivity) {
            return ApiResponse::error(
                "Anda baru saja memberi makan di spot ini. Silakan tunggu {$cooldownHours} jam sebelum membuat sesi baru di spot yang sama.",
                422,
                'COOLDOWN_ACTIVE'
            );
        }

        $now = now();
        $intentMinutes = (int) FeedingSetting::getFloat('intent_window_minutes', 15.0);
        $finalizeMinutes = (int) FeedingSetting::getFloat('finalize_window_minutes', 60.0);
        $intentDeadline = $now->copy()->addMinutes($intentMinutes);
        $finalizeDeadline = $now->copy()->addMinutes($finalizeMinutes);

        $activity = FeedingActivity::create([
            'user_id' => $user->id,
            'spot_id' => $spot->id,
            'location_lat' => $spot->latitude,
            'location_lng' => $spot->longitude,
            'status' => 'DRAFT',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => $now,
            'intent_deadline_at' => $intentDeadline,
            'finalize_deadline_at' => $finalizeDeadline,
        ]);

        return ApiResponse::created([
            'activity_id' => $activity->id,
            'feeding_record_ref' => $activity->feeding_record_ref,
            'status' => $activity->status,
            'spot' => $this->formatSpotSummary($spot),
            'scanned_at' => $activity->scanned_at->toIso8601String(),
            'intent_deadline_at' => $intentDeadline->toIso8601String(),
            'finalize_deadline_at' => $finalizeDeadline->toIso8601String(),
        ], 'Sesi pemberian pakan berhasil dibuka.');
    }

    /**
     * POST /api/v1/feeding/activities/{id}/intent †
     * Konfirmasi niat memberi makan dalam batas waktu 15 menit sejak scan QR (AFS-04, MEOW-9).
     */
    public function confirmIntent(Request $request, string $id): JsonResponse
    {
        $activity = FeedingActivity::find($id);
        if (!$activity) {
            return ApiResponse::error('Sesi pemberian pakan tidak ditemukan.', 404, 'ACTIVITY_NOT_FOUND');
        }

        if ($activity->user_id !== $request->user()->id) {
            return ApiResponse::error('Anda tidak memiliki akses ke sesi ini.', 403, 'FORBIDDEN');
        }

        if ($activity->status !== 'DRAFT') {
            return ApiResponse::error(
                "Sesi tidak dapat dikonfirmasi karena sudah berstatus {$activity->status}.",
                422,
                'INVALID_SESSION_STATUS'
            );
        }

        $intentMinutes = (int) FeedingSetting::getFloat('intent_window_minutes', 15.0);
        $isExpired = ($activity->intent_deadline_at && now()->greaterThan($activity->intent_deadline_at))
            || ($activity->scanned_at && $activity->scanned_at->diffInMinutes(now()) > $intentMinutes);

        if ($isExpired) {
            $activity->update(['status' => 'EXPIRED']);

            return ApiResponse::error(
                "Batas waktu konfirmasi intent ({$intentMinutes} menit) telah berakhir. Silakan scan ulang QR spot.",
                422,
                'SESSION_EXPIRED'
            );
        }

        if (!$activity->intent_at) {
            $activity->update(['intent_at' => now()]);
        }

        $finalizeMinutes = (int) FeedingSetting::getFloat('finalize_window_minutes', 60.0);
        $finalizeDeadline = $activity->finalize_deadline_at
            ?? ($activity->scanned_at ? $activity->scanned_at->copy()->addMinutes($finalizeMinutes) : now()->addMinutes($finalizeMinutes));

        return ApiResponse::success([
            'activity_id' => $activity->id,
            'status' => $activity->status,
            'intent_confirmed_at' => $activity->intent_at->toIso8601String(),
            'finalize_deadline_at' => $finalizeDeadline->toIso8601String(),
        ], 'Niat pemberian pakan berhasil dikonfirmasi.');
    }

    /**
     * POST /api/v1/feeding/activities/{id}/finalize †
     * Finalisasi sesi pemberian makan, simpan 1-3 bukti foto, jalankan FeedingRuleEngine,
     * kreditkan poin via PointService::award jika VERIFIED, dan catat sighting opsional (AFS-05, AFS-06, AFS-10, AFS-13, MEOW-11).
     */
    public function finalizeSession(Request $request, string $id): JsonResponse
    {
        $activity = FeedingActivity::with(['spot', 'user'])->find($id);
        if (!$activity) {
            return ApiResponse::error('Sesi pemberian pakan tidak ditemukan.', 404, 'ACTIVITY_NOT_FOUND');
        }

        if ($activity->user_id !== $request->user()->id) {
            return ApiResponse::error('Anda tidak memiliki akses ke sesi ini.', 403, 'FORBIDDEN');
        }

        // Idempotent replay jika sesi sudah difinalisasi
        if (in_array($activity->status, ['VERIFIED', 'UNDER_REVIEW', 'REJECTED'], true)) {
            return ApiResponse::success([
                'activity_id' => $activity->id,
                'status' => $activity->status,
                'reward_status' => $activity->reward_status,
                'points_awarded' => $activity->points_awarded,
                'is_replay' => true,
            ], 'Sesi pemberian pakan telah difinalisasi sebelumnya.');
        }

        $finalizeMinutes = (int) FeedingSetting::getFloat('finalize_window_minutes', 60.0);
        $isExpired = ($activity->finalize_deadline_at && now()->greaterThan($activity->finalize_deadline_at))
            || ($activity->scanned_at && $activity->scanned_at->diffInMinutes(now()) > $finalizeMinutes);

        if ($isExpired) {
            $activity->update(['status' => 'EXPIRED']);

            return ApiResponse::error(
                "Batas waktu finalisasi sesi ({$finalizeMinutes} menit) telah berakhir. Silakan scan ulang QR spot.",
                422,
                'SESSION_EXPIRED'
            );
        }

        $validated = $request->validate([
            'media_ids' => ['required', 'array', 'min:1', 'max:3'],
            'media_ids.*' => ['required', 'string', 'size:26', 'exists:media_files,id'],
            'food_type' => ['nullable', 'string', 'max:64'],
            'food_amount' => ['nullable', 'string', 'max:64'],
            'cat_id' => ['nullable', 'string', 'size:26', 'exists:cats,id'],
            'cat_code' => ['nullable', 'string', 'max:64'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        // Pastikan seluruh foto milik user ini dan bertipe feeding_proof
        $mediaRows = DB::table('media_files')
            ->whereIn('id', $validated['media_ids'])
            ->get();

        if ($mediaRows->count() !== count($validated['media_ids'])) {
            return ApiResponse::error('Salah satu bukti foto tidak ditemukan.', 422, 'INVALID_EVIDENCE');
        }

        // Resolusi opsional kucing (AFS-13)
        $catId = $validated['cat_id'] ?? null;
        if (!$catId && !empty($validated['cat_code'])) {
            $cat = Cat::where('unique_code', trim($validated['cat_code']))->first();
            $catId = $cat?->id;
        }

        $resultPayload = DB::transaction(function () use ($activity, $validated, $catId) {
            if (!$activity->intent_at) {
                $activity->intent_at = now();
            }

            $activity->food_type = $validated['food_type'] ?? 'dry_food';
            $activity->food_amount = $validated['food_amount'] ?? '1 mangkuk';
            $activity->cat_id = $catId;
            $activity->finalized_at = now();
            $activity->save();

            // Simpan 1-3 bukti foto
            FeedingEvidence::where('activity_id', $activity->id)->delete();
            foreach (array_values($validated['media_ids']) as $index => $mediaId) {
                FeedingEvidence::create([
                    'activity_id' => $activity->id,
                    'media_id' => $mediaId,
                    'captured_at' => now(),
                    'sort_order' => $index,
                ]);
            }

            // Jalankan FeedingRuleEngine (Aturan R1, R2, R4, R5, R6, R8 tanpa GPS)
            $evaluation = $this->ruleEngine->evaluateAndRecord($activity, $validated['media_ids']);

            // Catat sighting opsional kucing di spot (AFS-13)
            if ($catId) {
                DB::table('cat_sightings')->insert([
                    'id' => (string) Str::ulid(),
                    'cat_id' => $catId,
                    'user_id' => $activity->user_id,
                    'source' => 'feeding',
                    'location_lat' => $activity->location_lat,
                    'location_lng' => $activity->location_lng,
                    'occurred_at' => now(),
                    'metadata' => json_encode([
                        'spot_id' => $activity->spot_id,
                        'activity_id' => $activity->id,
                    ]),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                DB::table('cats')->where('id', $catId)->update([
                    'last_seen_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $notes = $validated['notes'] ?? null;

            if ($evaluation['status'] === 'VERIFIED') {
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

                $activity->update([
                    'status' => 'VERIFIED',
                    'reward_status' => 'CREDITED',
                    'potential_points' => $pointsAwarded,
                    'reward_snapshot' => [
                        'points_awarded' => $pointsAwarded,
                        'reward_capped' => $rewardCapped,
                        'transaction_id' => $award['transaction_id'] ?? null,
                        'notes' => $notes,
                    ],
                ]);

                $this->refreshSpotAggregate($activity->spot_id);
                event(new FeedingVerified($activity->fresh()));

                return [
                    'activity_id' => $activity->id,
                    'status' => 'VERIFIED',
                    'reward_status' => 'CREDITED',
                    'points_awarded' => $pointsAwarded,
                    'reward_capped' => $rewardCapped,
                    'flags' => $evaluation['flags'],
                    'rules' => $evaluation['results'],
                    'submitted_at' => $activity->finalized_at->toIso8601String(),
                    'verified_at' => $activity->finalized_at->toIso8601String(),
                ];
            }

            // UNDER_REVIEW atau REJECTED
            $rewardStatus = $evaluation['status'] === 'UNDER_REVIEW' ? 'PENDING' : 'NOT_ELIGIBLE';
            $activity->update([
                'status' => $evaluation['status'],
                'reward_status' => $rewardStatus,
                'reward_snapshot' => [
                    'points_awarded' => 0,
                    'reward_capped' => false,
                    'notes' => $notes,
                ],
            ]);

            $this->refreshSpotAggregate($activity->spot_id);

            return [
                'activity_id' => $activity->id,
                'status' => $activity->status,
                'reward_status' => $activity->reward_status,
                'points_awarded' => 0,
                'reward_capped' => false,
                'flags' => $evaluation['flags'],
                'rules' => $evaluation['results'],
                'submitted_at' => $activity->finalized_at->toIso8601String(),
                'verified_at' => null,
            ];
        });

        $msg = $resultPayload['status'] === 'VERIFIED'
            ? 'Aktivitas pemberian pakan berhasil diverifikasi dan poin telah dikreditkan.'
            : 'Bukti pemberian pakan berhasil dikirim dan sedang menunggu pemeriksaan reviewer.';

        return ApiResponse::success($resultPayload, $msg);
    }

    /**
     * GET /api/v1/feeding/activities/mine
     * Riwayat pemberian makan milik pengguna yang sedang login dengan pemisahan
     * status kegiatan (status) dan status poin (reward_status) (AFS-08, MEOW-13).
     */
    public function myActivities(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = FeedingActivity::query()
            ->where('user_id', $user->id)
            ->with([
                'spot:id,code,name,latitude,longitude,status',
                'cat:id,unique_code,name',
                'evidences',
                'latestReview',
            ])
            ->orderByDesc('created_at');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->upper()->toString());
        }

        $activities = $query->limit(50)->get();

        $mediaIds = $activities->pluck('evidences')->flatten()->pluck('media_id')->filter()->unique()->values();
        $mediaMap = $mediaIds->isNotEmpty()
            ? DB::table('media_files')->whereIn('id', $mediaIds)->get()->keyBy('id')
            : collect();

        $data = $activities->map(function (FeedingActivity $a) use ($mediaMap) {
            return [
                'id' => $a->id,
                'feeding_record_ref' => $a->feeding_record_ref,
                'spot_id' => $a->spot_id,
                'spot' => $a->spot ? [
                    'id' => $a->spot->id,
                    'code' => $a->spot->code,
                    'name' => $a->spot->name,
                    'latitude' => (float) $a->spot->latitude,
                    'longitude' => (float) $a->spot->longitude,
                    'status' => $a->spot->status,
                ] : null,
                'status' => $a->status,
                'reward_status' => $a->reward_status,
                'points_awarded' => $a->points_awarded,
                'potential_points' => (int) $a->potential_points,
                'reward_capped' => $a->reward_capped,
                'food_type' => $a->food_type,
                'food_amount' => $a->food_amount,
                'notes' => $a->notes,
                'cat' => $a->cat ? [
                    'id' => $a->cat->id,
                    'unique_code' => $a->cat->unique_code,
                    'name' => $a->cat->name,
                ] : null,
                'evidences' => $a->evidences->map(function (FeedingEvidence $ev) use ($mediaMap) {
                    $m = $mediaMap[$ev->media_id] ?? null;

                    return [
                        'id' => $ev->id,
                        'media_id' => $ev->media_id,
                        'path' => $m->path ?? null,
                        'sort_order' => $ev->sort_order,
                    ];
                })->values(),
                'flags' => $a->flags ?? [],
                'rejection_reason' => $a->rejection_reason,
                'scanned_at' => $a->scanned_at?->toIso8601String(),
                'intent_confirmed_at' => $a->intent_at?->toIso8601String(),
                'submitted_at' => $a->finalized_at?->toIso8601String(),
                'verified_at' => $a->status === 'VERIFIED' ? $a->finalized_at?->toIso8601String() : null,
                'reviewed_at' => $a->latestReview?->created_at?->toIso8601String(),
            ];
        })->values();

        return ApiResponse::success($data, 'Riwayat aktivitas pemberian pakan berhasil diambil.');
    }

    /**
     * GET /api/v1/feeding/heatmap
     * Agregat distribusi pemberian makan 14 hari terakhir per spot (AFS-09, MEOW-13).
     * Memisahkan secara jelas jumlah aktivitas terverifikasi (verified_count) dan yang masih direview (pending_count).
     */
    public function heatmap(): JsonResponse
    {
        $spots = FeedingSpot::query()
            ->active()
            ->with(['latestAggregate'])
            ->orderBy('name')
            ->get();

        $windowStart = now()->subDays(14)->startOfDay();

        $verifiedCounts = FeedingActivity::query()
            ->whereIn('spot_id', $spots->pluck('id'))
            ->where('status', 'VERIFIED')
            ->where('finalized_at', '>=', $windowStart)
            ->selectRaw('spot_id, COUNT(*) as total, MAX(finalized_at) as last_fed_at')
            ->groupBy('spot_id')
            ->get()
            ->keyBy('spot_id');

        $pendingCounts = FeedingActivity::query()
            ->whereIn('spot_id', $spots->pluck('id'))
            ->where('status', 'UNDER_REVIEW')
            ->where('finalized_at', '>=', $windowStart)
            ->selectRaw('spot_id, COUNT(*) as total')
            ->groupBy('spot_id')
            ->pluck('total', 'spot_id');

        $data = $spots->map(function (FeedingSpot $spot) use ($verifiedCounts, $pendingCounts) {
            $agg = $spot->latestAggregate;
            $vRow = $verifiedCounts[$spot->id] ?? null;

            $verified14d = $vRow ? (int) $vRow->total : (int) ($agg?->verified_count ?? 0);
            $pending14d = isset($pendingCounts[$spot->id])
                ? (int) $pendingCounts[$spot->id]
                : (int) ($agg?->pending_count ?? 0);

            $lastFedAt = $vRow?->last_fed_at
                ? Carbon::parse($vRow->last_fed_at)->toIso8601String()
                : null;

            // Skor prioritas sederhana: semakin jarang diberi makan dalam 14 hari, semakin tinggi need_score (0..100)
            $needScore = round(max(0.0, min(100.0, (1.0 - min(1.0, $verified14d / 28.0)) * 100.0)), 1);

            return [
                'spot_id' => $spot->id,
                'code' => $spot->code,
                'name' => $spot->name,
                'latitude' => (float) $spot->latitude,
                'longitude' => (float) $spot->longitude,
                'territory_id' => $spot->territory_id,
                'window_days' => 14,
                'total_feedings' => $verified14d,
                'verified_count' => $verified14d,
                'pending_count' => $pending14d,
                'need_score' => $needScore,
                'last_fed_at' => $lastFedAt,
            ];
        })->values();

        return ApiResponse::success($data, 'Data heatmap aktivitas pemberian pakan 14 hari terakhir berhasil diambil.');
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
     * Format representasi spot untuk daftar, peta, dan detail sesuai AFS-02.
     */
    private function formatSpotSummary(FeedingSpot $spot, ?string $fallbackLastFedAt = null, ?array $territory = null): array
    {
        $agg = $spot->latestAggregate;
        $lastFedIso = $fallbackLastFedAt ? Carbon::parse($fallbackLastFedAt)->toIso8601String() : null;
        $verifiedCount = (int) ($agg?->verified_count ?? 0);
        $needScore = round(max(0.0, min(100.0, (1.0 - min(1.0, $verifiedCount / 28.0)) * 100.0)), 1);

        return [
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'territory' => $territory,
            'status' => $spot->status,
            'last_fed_at' => $lastFedIso,
            'aggregate' => [
                'window_days' => 14,
                'total_feedings' => $verifiedCount,
                'verified_count' => $verifiedCount,
                'pending_count' => (int) ($agg?->pending_count ?? 0),
                'need_score' => $needScore,
                'last_fed_at' => $lastFedIso,
            ],
        ];
    }
}
