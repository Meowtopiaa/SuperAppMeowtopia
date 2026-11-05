<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class FeedingSpotController extends Controller
{
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
