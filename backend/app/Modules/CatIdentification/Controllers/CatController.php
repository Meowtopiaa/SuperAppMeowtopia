<?php

namespace App\Modules\CatIdentification\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatIdentification\Requests\RecordSightingRequest;
use App\Modules\CatIdentification\Resources\CatPublicResource;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CatController extends Controller
{
    public function index(Request $request)
    {
        $query = Cat::query();

        if ($request->filled('presence_status')) {
            $query->where('presence_status', $request->query('presence_status'));
        }

        if ($request->filled('adoption_status')) {
            $query->where('adoption_status', $request->query('adoption_status'));
        }

        if ($request->filled('health_status')) {
            $query->where('health_status', $request->query('health_status'));
        }

        if ($request->filled('territory_id')) {
            $query->where('territory_id', $request->query('territory_id'));
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('unique_code', 'like', "%{$search}%")
                    ->orWhere('color_pattern', 'like', "%{$search}%");
            });
        }

        $perPage = min(max((int) $request->query('per_page', 15), 1), 100);
        $paginator = $query->orderBy('name')->paginate($perPage);

        $items = CatPublicResource::collection($paginator->getCollection())->resolve($request);

        return ApiResponse::success($items, 'Daftar kucing berhasil diambil.', 200, [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
            'has_more' => $paginator->hasMorePages(),
        ]);
    }

    public function show(Request $request, string $id)
    {
        $cat = Cat::find($id);

        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        return ApiResponse::success(
            (new CatPublicResource($cat))->resolve($request),
            'Detail profil kucing berhasil diambil.'
        );
    }

    public function findByCode(Request $request, string $uniqueCode)
    {
        $cat = Cat::where('unique_code', strtoupper(trim($uniqueCode)))->first();

        if (!$cat) {
            return ApiResponse::error('Kucing dengan kode tersebut tidak ditemukan.', 404, 'NOT_FOUND');
        }

        return ApiResponse::success(
            (new CatPublicResource($cat))->resolve($request),
            'Kucing berhasil ditemukan.'
        );
    }

    public function actions(Request $request, string $id)
    {
        $cat = Cat::find($id);

        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $user = $request->user();
        $actions = [];

        $canEncounter = ($cat->presence_status === 'ON_CAMPUS') &&
            !in_array($cat->health_status, ['SICK', 'INJURED'], true);
        $actions[] = [
            'id' => 'game.encounter',
            'module' => 'CatHunter',
            'label' => 'Dekati & Elus',
            'enabled' => $canEncounter,
            'reason' => $canEncounter ? null : 'Kucing sedang tidak berada di kampus atau sedang dalam perawatan sakit/terluka.',
        ];

        $canAdopt = ($cat->adoption_status === 'READY') && ($user?->user_type === 'MAHASISWA');
        $actions[] = [
            'id' => 'adoption.apply',
            'module' => 'CatAdoption',
            'label' => 'Ajukan Adopsi',
            'enabled' => $canAdopt,
            'reason' => $canAdopt ? null : ($user?->user_type !== 'MAHASISWA' ? 'Hanya mahasiswa terverifikasi yang dapat mengajukan adopsi.' : 'Kucing ini belum berstatus siap adopsi.'),
        ];

        $actions[] = [
            'id' => 'incident.report',
            'module' => 'IncidentReport',
            'label' => 'Laporkan Insiden/Kondisi',
            'enabled' => true,
            'reason' => null,
        ];

        $actions[] = [
            'id' => 'feeding.start',
            'module' => 'FeedingSpot',
            'label' => 'Beri Makan di Spot',
            'enabled' => $cat->presence_status === 'ON_CAMPUS',
            'reason' => $cat->presence_status === 'ON_CAMPUS' ? null : 'Kucing sedang tidak berada di kampus.',
        ];

        return ApiResponse::success($actions, 'Daftar aksi hub profil kucing berhasil diambil.');
    }

    public function recordSighting(RecordSightingRequest $request, string $id)
    {
        $cat = Cat::find($id);
        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $validated = $request->validated();
        $user = $request->user();
        $source = $validated['source'] ?? 'manual_sighting';

        $recentSighting = DB::table('cat_sightings')
            ->where('cat_id', $cat->id)
            ->where('user_id', $user->id)
            ->where('source', $source)
            ->where('occurred_at', '>=', now()->subMinutes(30))
            ->first();

        if ($recentSighting) {
            return ApiResponse::success([
                'sighting_id' => $recentSighting->id,
                'deduplicated' => true,
            ], 'Perjumpaan sudah tercatat dalam 30 menit terakhir.');
        }

        $sightingId = (string) Str::ulid();
        $now = now();

        DB::transaction(function () use ($sightingId, $cat, $user, $source, $validated, $request, $now) {
            DB::table('cat_sightings')->insert([
                'id' => $sightingId,
                'cat_id' => $cat->id,
                'user_id' => $user->id,
                'source' => $source,
                'request_id' => $request->header('Idempotency-Key'),
                'location_lat' => $validated['location_lat'] ?? null,
                'location_lng' => $validated['location_lng'] ?? null,
                'accuracy_m' => $validated['accuracy_m'] ?? null,
                'metadata' => isset($validated['metadata']) ? json_encode($validated['metadata']) : null,
                'occurred_at' => $now,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $cat->last_seen_at = $now;
            if ($cat->first_seen_at === null) {
                $cat->first_seen_at = $now;
            }
            $cat->save();
        });

        return ApiResponse::created([
            'sighting_id' => $sightingId,
            'deduplicated' => false,
        ], 'Perjumpaan berhasil dicatat.');
    }
}
