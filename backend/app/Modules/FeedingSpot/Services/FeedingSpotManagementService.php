<?php

namespace App\Modules\FeedingSpot\Services;

use App\Models\User;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FeedingSpotManagementService
{
    public const ALLOWED_STATUSES = [
        'ACTIVE',
        'MAINTENANCE',
        'TEMPORARILY_UNAVAILABLE',
        'INACTIVE',
    ];

    /**
     * Polygon Perimeter Resmi Wilayah Kampus Telkom University Bandung
     * (76 titik presisi OSM Way 557649490 + Kantin Teknik, sinkron dengan Flutter CampusSpotMap).
     */
    public const TELKOM_BOUNDARY = [
        [-6.9697046, 107.6307312],
        [-6.9702850, 107.6309752],
        [-6.9703549, 107.6310401],
        [-6.9704453, 107.6311774],
        [-6.9709586, 107.6319851],
        [-6.9714512, 107.6326704],
        [-6.9720409, 107.6335066],
        [-6.9721221, 107.6334442],
        [-6.9721713, 107.6335354],
        [-6.9730965, 107.6334992],
        [-6.9731498, 107.6334415],
        [-6.9732669, 107.6333047],
        [-6.9739019, 107.6326382],
        [-6.9739511, 107.6326248],
        [-6.9740250, 107.6326088],
        [-6.9740603, 107.6325980],
        [-6.9744437, 107.6325403],
        [-6.9747597, 107.6324340],
        [-6.9748191, 107.6324698],
        [-6.9750573, 107.6325926],
        [-6.9752184, 107.6326986],
        [-6.9754460, 107.6329333],
        [-6.9755306, 107.6329688],
        [-6.9756371, 107.6329654],
        [-6.9760504, 107.6329319],
        [-6.9761877, 107.6328865],
        [-6.9762394, 107.6327978],
        [-6.9774654, 107.6315466],
        [-6.9776200, 107.6313900],
        [-6.9779500, 107.6317500],
        [-6.9786500, 107.6310800],
        [-6.9778500, 107.6306200],
        [-6.9777357, 107.6305917],
        [-6.9776897, 107.6301411],
        [-6.9776505, 107.6299500],
        [-6.9776405, 107.6298387],
        [-6.9776425, 107.6297320],
        [-6.9776837, 107.6294491],
        [-6.9777157, 107.6292425],
        [-6.9777250, 107.6290642],
        [-6.9771872, 107.6290481],
        [-6.9756444, 107.6290561],
        [-6.9753076, 107.6290521],
        [-6.9752314, 107.6290444],
        [-6.9752204, 107.6290434],
        [-6.9751658, 107.6289844],
        [-6.9748710, 107.6287074],
        [-6.9743039, 107.6282313],
        [-6.9738060, 107.6277861],
        [-6.9732909, 107.6282461],
        [-6.9731484, 107.6283976],
        [-6.9719577, 107.6283936],
        [-6.9719437, 107.6284074],
        [-6.9719344, 107.6284312],
        [-6.9719360, 107.6284644],
        [-6.9719360, 107.6284781],
        [-6.9713819, 107.6284996],
        [-6.9713727, 107.6281416],
        [-6.9713512, 107.6280972],
        [-6.9712548, 107.6268379],
        [-6.9712235, 107.6267521],
        [-6.9707124, 107.6267702],
        [-6.9702045, 107.6267943],
        [-6.9696254, 107.6275329],
        [-6.9696164, 107.6275597],
        [-6.9694956, 107.6277231],
        [-6.9685079, 107.6275742],
        [-6.9684786, 107.6280342],
        [-6.9684853, 107.6284620],
        [-6.9692014, 107.6286001],
        [-6.9696267, 107.6303470],
        [-6.9697046, 107.6307312],
    ];

    /**
     * Ray-casting algorithm untuk memvalidasi apakah titik koordinat berada di dalam poligon Telkom University.
     */
    public static function isPointInsideTelkomCampus(float $latitude, float $longitude): bool
    {
        $inside = false;
        $boundary = self::TELKOM_BOUNDARY;
        $count = count($boundary);

        for ($i = 0, $j = $count - 1; $i < $count; $j = $i++) {
            $xi = $boundary[$i][0];
            $yi = $boundary[$i][1];
            $xj = $boundary[$j][0];
            $yj = $boundary[$j][1];

            $intersect = (($yi > $longitude) !== ($yj > $longitude))
                && ($latitude < ($xj - $xi) * ($longitude - $yi) / (($yj - $yi) ?: 1e-12) + $xi);

            if ($intersect) {
                $inside = !$inside;
            }
        }

        return $inside;
    }

    /**
     * Daftar spot untuk admin (termasuk INACTIVE), mendukung filter status,
     * pencarian nama/kode, dan paginasi (AFS-01, Bagian 8.4).
     */
    public function paginateAdminSpots(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $perPage = max(1, min(100, $perPage));

        $query = FeedingSpot::query()
            ->with(['latestAggregate', 'cats:id,unique_code,name,presence_status,health_status'])
            ->withCount('cats')
            ->orderBy('code');

        if (!empty($filters['status'])) {
            $status = strtoupper(trim((string) $filters['status']));
            if (in_array($status, self::ALLOWED_STATUSES, true)) {
                $query->where('status', $status);
            }
        }

        if (!empty($filters['territory_id'])) {
            $query->where('territory_id', trim((string) $filters['territory_id']));
        }

        $search = trim((string) ($filters['search'] ?? $filters['q'] ?? ''));
        if ($search !== '') {
            $needle = '%' . mb_strtolower($search) . '%';
            $query->where(function ($q) use ($needle) {
                $q->whereRaw('LOWER(name) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(code) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(COALESCE(description, \'\')) LIKE ?', [$needle]);
            });
        }

        $paginator = $query->paginate($perPage);
        $spots = collect($paginator->items());

        if ($spots->isNotEmpty()) {
            $spotIds = $spots->pluck('id');

            $latestVerifiedMap = FeedingActivity::query()
                ->whereIn('spot_id', $spotIds)
                ->where('status', 'VERIFIED')
                ->selectRaw('spot_id, MAX(COALESCE(finalized_at, updated_at)) as last_fed_at')
                ->groupBy('spot_id')
                ->pluck('last_fed_at', 'spot_id');

            $pendingSpotIds = FeedingActivity::query()
                ->whereIn('spot_id', $spotIds)
                ->where('status', 'UNDER_REVIEW')
                ->pluck('spot_id')
                ->unique()
                ->flip();

            $territoryIds = $spots->pluck('territory_id')->filter()->unique()->values();
            $territoryMap = $territoryIds->isNotEmpty()
                ? DB::table('territories')
                    ->whereIn('id', $territoryIds)
                    ->select(['id', 'code', 'name'])
                    ->get()
                    ->keyBy('id')
                : collect();

            $paginator->setCollection(
                $spots->map(function (FeedingSpot $spot) use ($latestVerifiedMap, $pendingSpotIds, $territoryMap) {
                    $territoryRow = $spot->territory_id ? ($territoryMap[$spot->territory_id] ?? null) : null;
                    $hasPending = isset($pendingSpotIds[$spot->id]) || (($spot->latestAggregate?->pending_count ?? 0) > 0);

                    return $this->formatAdminSpot(
                        $spot,
                        $latestVerifiedMap[$spot->id] ?? null,
                        $territoryRow ? (array) $territoryRow : null,
                        $hasPending
                    );
                })
            );
        }

        return $paginator;
    }

    /**
     * Detail lengkap spot untuk admin, termasuk status_reason, token QR aktif,
     * kucing terkait, riwayat aktivitas, dan log audit perubahan (AFS-01, Bagian 8.4).
     */
    public function getAdminSpotDetail(FeedingSpot $spot): array
    {
        $spot->loadMissing(['latestAggregate']);
        $spot->loadCount('cats');

        $latestVerified = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->where('status', 'VERIFIED')
            ->selectRaw('MAX(COALESCE(finalized_at, updated_at)) as last_fed_at')
            ->value('last_fed_at');

        $hasPending = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->where('status', 'UNDER_REVIEW')
            ->exists() || (($spot->latestAggregate?->pending_count ?? 0) > 0);

        $detail = $this->formatAdminSpot(
            $spot,
            $latestVerified ? (string) $latestVerified : null,
            $spot->territory_data,
            $hasPending
        );

        $detail['cats'] = $spot->cats()
            ->select(['cats.id', 'cats.unique_code', 'cats.name', 'cats.presence_status', 'cats.health_status'])
            ->get()
            ->map(fn ($c) => [
                'id' => $c->id,
                'unique_code' => $c->unique_code,
                'name' => $c->name,
                'presence_status' => $c->presence_status,
                'health_status' => $c->health_status,
            ])
            ->values()
            ->all();

        $detail['activities_count'] = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->count();

        $detail['recent_activities'] = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->with(['user:id,name', 'cat:id,unique_code,name'])
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->map(fn (FeedingActivity $a) => [
                'id' => $a->id,
                'feeding_record_ref' => $a->feeding_record_ref,
                'status' => $a->status,
                'reward_status' => $a->reward_status,
                'food_type' => $a->food_type,
                'food_amount' => $a->food_amount,
                'feeder_name' => $a->user?->name ?? 'Relawan Kampus',
                'cat_name' => $a->cat?->name,
                'scanned_at' => $a->scanned_at?->toIso8601String(),
                'finalized_at' => $a->finalized_at?->toIso8601String(),
            ])
            ->values()
            ->all();

        $detail['audit_logs'] = $this->getSpotAuditLogs($spot->id, 15);

        return $detail;
    }

    /**
     * Buat titik feeding spot baru dan catat di audit_logs.
     */
    public function createSpot(array $data, ?User $actor = null): FeedingSpot
    {
        return DB::transaction(function () use ($data, $actor) {
            $status = strtoupper(trim((string) ($data['status'] ?? 'ACTIVE')));
            $statusReason = isset($data['status_reason']) && trim((string) $data['status_reason']) !== ''
                ? trim((string) $data['status_reason'])
                : null;

            $spot = FeedingSpot::create([
                'code' => strtoupper(trim((string) $data['code'])),
                'name' => trim((string) $data['name']),
                'description' => isset($data['description']) && trim((string) $data['description']) !== ''
                    ? trim((string) $data['description'])
                    : null,
                'latitude' => (float) $data['latitude'],
                'longitude' => (float) $data['longitude'],
                'territory_id' => !empty($data['territory_id']) ? (string) $data['territory_id'] : null,
                'qr_token' => Str::random(32),
                'status' => $status,
                'status_reason' => $status === 'ACTIVE' ? null : $statusReason,
            ]);

            $this->recordAuditLog(
                actor: $actor,
                action: 'SPOT_CREATED',
                spotId: $spot->id,
                oldValues: null,
                newValues: $this->extractSnapshot($spot)
            );

            return $spot;
        });
    }

    /**
     * Perbarui lokasi, informasi, atau status spot (termasuk nonaktifkan ke INACTIVE tanpa hapus)
     * serta catat perubahan (aktor, waktu, nilai lama dan baru) di audit_logs.
     */
    public function updateSpot(FeedingSpot $spot, array $data, ?User $actor = null): FeedingSpot
    {
        return DB::transaction(function () use ($spot, $data, $actor) {
            $oldValues = $this->extractSnapshot($spot);

            $updates = [];

            if (array_key_exists('code', $data)) {
                $updates['code'] = strtoupper(trim((string) $data['code']));
            }
            if (array_key_exists('name', $data)) {
                $updates['name'] = trim((string) $data['name']);
            }
            if (array_key_exists('description', $data)) {
                $updates['description'] = $data['description'] !== null && trim((string) $data['description']) !== ''
                    ? trim((string) $data['description'])
                    : null;
            }
            if (array_key_exists('latitude', $data)) {
                $updates['latitude'] = (float) $data['latitude'];
            }
            if (array_key_exists('longitude', $data)) {
                $updates['longitude'] = (float) $data['longitude'];
            }
            if (array_key_exists('territory_id', $data)) {
                $updates['territory_id'] = !empty($data['territory_id']) ? (string) $data['territory_id'] : null;
            }
            if (array_key_exists('status', $data)) {
                $updates['status'] = strtoupper(trim((string) $data['status']));
            }

            if (array_key_exists('status_reason', $data)) {
                $updates['status_reason'] = $data['status_reason'] !== null && trim((string) $data['status_reason']) !== ''
                    ? trim((string) $data['status_reason'])
                    : null;
            } elseif (($updates['status'] ?? null) === 'ACTIVE') {
                $updates['status_reason'] = null;
            }

            $spot->update($updates);
            $spot->refresh();

            $newValues = $this->extractSnapshot($spot);

            $statusChanged = $oldValues['status'] !== $newValues['status'];
            $locationChanged = (float) $oldValues['latitude'] !== (float) $newValues['latitude']
                || (float) $oldValues['longitude'] !== (float) $newValues['longitude'];

            $action = match (true) {
                $statusChanged && $locationChanged => 'SPOT_LOCATION_AND_STATUS_CHANGED',
                $statusChanged => 'SPOT_STATUS_CHANGED',
                $locationChanged => 'SPOT_LOCATION_CHANGED',
                default => 'SPOT_UPDATED',
            };

            $this->recordAuditLog(
                actor: $actor,
                action: $action,
                spotId: $spot->id,
                oldValues: $oldValues,
                newValues: $newValues
            );

            return $spot;
        });
    }

    /**
     * Regenerasi token QR spot dan catat di audit_logs.
     */
    public function regenerateQr(FeedingSpot $spot, ?User $actor = null): FeedingSpot
    {
        return DB::transaction(function () use ($spot, $actor) {
            $oldToken = $spot->qr_token;
            $newToken = Str::random(32);

            $spot->update(['qr_token' => $newToken]);
            $spot->refresh();

            $this->recordAuditLog(
                actor: $actor,
                action: 'SPOT_QR_REGENERATED',
                spotId: $spot->id,
                oldValues: ['qr_token' => $oldToken],
                newValues: ['qr_token' => $newToken]
            );

            return $spot;
        });
    }

    /**
     * Format representasi spot untuk endpoint Admin (menyertakan status_reason & qr_token aktif).
     */
    public function formatAdminSpot(
        FeedingSpot $spot,
        ?string $fallbackLastFedAt = null,
        ?array $territory = null,
        bool $hasPendingReview = false
    ): array {
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
            'status_reason' => $spot->status_reason,
            'qr_token' => $spot->qr_token,
            'qr_payload' => "MTP1.S.{$spot->qr_token}",
            'cats_count' => (int) ($spot->cats_count ?? ($spot->relationLoaded('cats') ? $spot->cats->count() : 0)),
            'cats' => $spot->relationLoaded('cats')
                ? $spot->cats->map(fn ($c) => [
                    'id' => $c->id,
                    'unique_code' => $c->unique_code,
                    'name' => $c->name,
                    'presence_status' => $c->presence_status,
                    'health_status' => $c->health_status,
                ])->values()->all()
                : [],
            'last_fed_at' => $lastFedIso,
            'has_pending_review' => $hasPendingReview,
            'aggregate' => [
                'window_days' => 14,
                'total_feedings' => $verifiedCount,
                'verified_count' => $verifiedCount,
                'pending_count' => (int) ($agg?->pending_count ?? 0),
                'need_score' => $needScore,
                'last_fed_at' => $lastFedIso,
                'computed_at' => $agg?->computed_at ? Carbon::parse($agg->computed_at)->toIso8601String() : null,
                'is_stale' => $agg ? Carbon::parse($agg->computed_at)->lt(now()->subHours(1)) : true,
            ],
            'created_at' => $spot->created_at?->toIso8601String(),
            'updated_at' => $spot->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Ambil daftar audit_logs terbaru untuk spot tertentu atau seluruh modul FeedingSpot
     * (mencakup perubahan lokasi/status spot dan keputusan review pemberian pakan).
     */
    public function getSpotAuditLogs(?string $spotId = null, int $limit = 30): array
    {
        $query = DB::table('audit_logs')
            ->leftJoin('users', 'audit_logs.actor_id', '=', 'users.id')
            ->select([
                'audit_logs.id',
                'audit_logs.actor_id',
                'users.name as actor_name',
                'audit_logs.action',
                'audit_logs.subject_type',
                'audit_logs.subject_id',
                'audit_logs.result',
                'audit_logs.reason',
                'audit_logs.created_at',
            ])
            ->orderByDesc('audit_logs.created_at')
            ->limit($limit);

        if ($spotId !== null) {
            $query->where('audit_logs.subject_type', 'feeding_spot')
                ->where('audit_logs.subject_id', $spotId);
        } else {
            $query->whereIn('audit_logs.subject_type', ['feeding_spot', 'feeding_activity']);
        }

        return $query->get()->map(function ($row) {
            $decoded = is_string($row->reason) ? json_decode($row->reason, true) : null;

            return [
                'id' => $row->id,
                'actor_id' => $row->actor_id,
                'actor_name' => $row->actor_name ?? 'Sistem / Admin',
                'action' => $row->action,
                'subject_type' => $row->subject_type,
                'subject_id' => $row->subject_id,
                'result' => $row->result,
                'changes' => is_array($decoded) ? $decoded : ['raw' => $row->reason],
                'created_at' => $row->created_at,
            ];
        })->all();
    }

    private function extractSnapshot(FeedingSpot $spot): array
    {
        return [
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'status' => $spot->status,
            'status_reason' => $spot->status_reason,
        ];
    }

    private function recordAuditLog(
        ?User $actor,
        string $action,
        string $spotId,
        ?array $oldValues,
        array $newValues
    ): void {
        $changedFields = [];
        if ($oldValues !== null) {
            foreach ($newValues as $key => $val) {
                if (($oldValues[$key] ?? null) !== $val) {
                    $changedFields[] = $key;
                }
            }
        } else {
            $changedFields = array_keys($newValues);
        }

        DB::table('audit_logs')->insert([
            'id' => (string) Str::ulid(),
            'actor_id' => $actor?->id,
            'action' => $action,
            'subject_type' => 'feeding_spot',
            'subject_id' => $spotId,
            'result' => 'SUCCESS',
            'reason' => json_encode([
                'old' => $oldValues,
                'new' => $newValues,
                'changed_fields' => $changedFields,
            ], JSON_UNESCAPED_UNICODE),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

