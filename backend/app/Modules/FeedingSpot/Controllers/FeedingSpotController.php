<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Services\ScanResolver;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class FeedingSpotController extends Controller
{
    public function __construct(
        private readonly ScanResolver $scanResolver,
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
