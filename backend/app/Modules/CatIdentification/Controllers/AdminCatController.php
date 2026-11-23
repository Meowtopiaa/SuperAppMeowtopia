<?php

namespace App\Modules\CatIdentification\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatIdentification\Models\CatPhoto;
use App\Modules\CatIdentification\Policies\CatPolicy;
use App\Modules\CatIdentification\Requests\ImportCatsRequest;
use App\Modules\CatIdentification\Requests\MergeCatRequest;
use App\Modules\CatIdentification\Requests\RegenerateQrRequest;
use App\Modules\CatIdentification\Requests\StoreCatRequest;
use App\Modules\CatIdentification\Requests\UpdateCatRequest;
use App\Modules\CatIdentification\Requests\UpdateCatTraitsRequest;
use App\Modules\CatIdentification\Resources\CatAdminResource;
use App\Modules\CatIdentification\Services\CatImportService;
use App\Modules\CatIdentification\Services\CatMergeService;
use App\Modules\CatIdentification\Services\CatQrService;
use App\Modules\Core\Services\CatStatusService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class AdminCatController extends Controller
{
    public function __construct(
        protected CatQrService $catQrService,
        protected CatStatusService $catStatusService,
        protected CatMergeService $catMergeService,
        protected CatImportService $catImportService,
        protected CatPolicy $catPolicy
    ) {}

    public function store(StoreCatRequest $request)
    {
        $validated = $request->validated();
        $actor = $request->user();

        $cat = DB::transaction(function () use ($validated, $actor) {
            $uniqueCode = !empty($validated['unique_code'])
                ? strtoupper($validated['unique_code'])
                : $this->catQrService->generateUniqueCode();

            $cat = Cat::create([
                'unique_code' => $uniqueCode,
                'name' => $validated['name'],
                'gender' => $validated['gender'] ?? 'UNKNOWN',
                'color_pattern' => $validated['color_pattern'] ?? null,
                'age_group' => $validated['age_group'] ?? 'UNKNOWN',
                'is_sterilized' => $validated['is_sterilized'] ?? null,
                'description' => $validated['description'] ?? null,
                'traits' => $validated['traits'] ?? null,
                'territory_id' => $validated['territory_id'] ?? null,
                'primary_photo_media_id' => $validated['primary_photo_media_id'] ?? null,
                'presence_status' => 'ON_CAMPUS',
                'health_status' => 'HEALTHY',
                'adoption_status' => 'UNREVIEWED',
                'verification_status' => $validated['verification_status'] ?? 'VERIFIED',
            ]);

            if (!empty($validated['photos'])) {
                foreach ($validated['photos'] as $index => $photo) {
                    CatPhoto::create([
                        'cat_id' => $cat->id,
                        'media_id' => $photo['media_id'],
                        'angle' => $photo['angle'] ?? null,
                        'sort_order' => $photo['sort_order'] ?? $index,
                    ]);
                }
            }

            $this->catQrService->issueInitialToken($cat, $actor);

            DB::table('audit_logs')->insert([
                'id' => (string) Str::ulid(),
                'actor_id' => $actor->id,
                'action' => 'cat.created',
                'subject_type' => Cat::class,
                'subject_id' => $cat->id,
                'result' => 'SUCCESS',
                'reason' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return $cat;
        });

        $cat->load('activeQrToken');

        return ApiResponse::created(
            (new CatAdminResource($cat))->resolve($request),
            'Profil kucing berhasil dibuat.'
        );
    }

    public function update(UpdateCatRequest $request, string $id)
    {
        $cat = Cat::find($id);
        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $validated = $request->validated();
        $actor = $request->user();

        if (array_key_exists('presence_status', $validated) && !$this->catPolicy->curate($actor, $cat)) {
            return ApiResponse::error(
                'Anda tidak memiliki izin cat.curate untuk mengubah presence_status kucing.',
                403,
                'FORBIDDEN'
            );
        }

        $editableFields = [
            'unique_code',
            'name',
            'gender',
            'color_pattern',
            'age_group',
            'is_sterilized',
            'description',
            'traits',
            'territory_id',
            'primary_photo_media_id',
            'verification_status',
        ];

        try {
            DB::transaction(function () use ($cat, $validated, $editableFields, $actor) {
                $updates = [];
                foreach ($editableFields as $field) {
                    if (array_key_exists($field, $validated)) {
                        $updates[$field] = $field === 'unique_code' && $validated[$field] !== null
                            ? strtoupper($validated[$field])
                            : $validated[$field];
                    }
                }

                if (!empty($updates)) {
                    $cat->fill($updates);
                    $cat->save();
                }

                if (array_key_exists('presence_status', $validated)) {
                    $this->catStatusService->change(
                        $cat,
                        'presence_status',
                        $validated['presence_status'],
                        $actor,
                        'Cat',
                        $validated['status_reason']
                    );
                }

                DB::table('audit_logs')->insert([
                    'id' => (string) Str::ulid(),
                    'actor_id' => $actor->id,
                    'action' => 'cat.updated',
                    'subject_type' => Cat::class,
                    'subject_id' => $cat->id,
                    'result' => 'SUCCESS',
                    'reason' => $validated['status_reason'] ?? null,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            });
        } catch (ConflictHttpException $e) {
            return ApiResponse::error($e->getMessage(), 409, 'CONFLICT');
        }

        $cat->refresh()->load('activeQrToken');

        return ApiResponse::success(
            (new CatAdminResource($cat))->resolve($request),
            'Profil kucing berhasil diperbarui.'
        );
    }

    public function import(ImportCatsRequest $request)
    {
        $file = $request->file('file');
        $summary = $this->catImportService->importFromPath($file->getRealPath(), $request->user());

        return ApiResponse::success($summary, 'Proses impor CSV kucing selesai.');
    }

    public function regenerateQr(RegenerateQrRequest $request, string $id)
    {
        $cat = Cat::find($id);
        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $newToken = $this->catQrService->regenerateToken(
            $cat,
            $request->user(),
            $request->validated()['reason']
        );

        return ApiResponse::success([
            'cat_id' => $cat->id,
            'unique_code' => $cat->unique_code,
            'token_id' => $newToken->id,
            'status' => $newToken->status,
            'qr_payload' => $this->catQrService->formatQrPayload($newToken->token),
            'issued_at' => $newToken->issued_at?->toIso8601String(),
        ], 'Token QR kucing berhasil diperbarui. Token lama telah dicabut.');
    }

    public function qrSheet(Request $request)
    {
        if (!$this->catPolicy->viewQrSheet($request->user())) {
            return ApiResponse::error('Anda tidak memiliki izin untuk mengakses lembar cetak QR.', 403, 'FORBIDDEN');
        }

        $query = Cat::query()->with('activeQrToken');

        if ($request->filled('territory_id')) {
            $query->where('territory_id', $request->query('territory_id'));
        }

        if ($request->filled('cat_ids')) {
            $ids = is_array($request->query('cat_ids'))
                ? $request->query('cat_ids')
                : explode(',', (string) $request->query('cat_ids'));
            $query->whereIn('id', array_filter($ids));
        }

        $cats = $query->orderBy('unique_code')->get();

        $sheet = $cats->map(function (Cat $cat) {
            $token = $cat->activeQrToken;
            return [
                'cat_id' => $cat->id,
                'name' => $cat->name,
                'unique_code' => $cat->unique_code,
                'territory_id' => $cat->territory_id,
                'has_active_qr' => $token !== null,
                'qr_payload' => $token ? $this->catQrService->formatQrPayload($token->token) : null,
                'issued_at' => $token?->issued_at?->toIso8601String(),
            ];
        })->values()->all();

        return ApiResponse::success([
            'generated_at' => now()->toIso8601String(),
            'total' => count($sheet),
            'items' => $sheet,
        ], 'Data lembar cetak QR berhasil diambil.');
    }

    public function updateTraits(UpdateCatTraitsRequest $request, string $id)
    {
        $cat = Cat::find($id);
        if (!$cat) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $traits = $request->validated()['traits'];
        $now = now();

        DB::transaction(function () use ($cat, $traits, $now) {
            foreach ($traits as $item) {
                DB::table('cat_trait_answers')->updateOrInsert(
                    [
                        'cat_id' => $cat->id,
                        'question_id' => $item['question_id'],
                    ],
                    [
                        'answer' => $item['answer'],
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]
                );
            }
        });

        $saved = DB::table('cat_trait_answers')
            ->where('cat_id', $cat->id)
            ->get(['question_id', 'answer']);

        return ApiResponse::success([
            'cat_id' => $cat->id,
            'traits' => $saved,
        ], 'Atribut ciri fisik kucing berhasil diperbarui.');
    }

    public function merge(MergeCatRequest $request, string $id)
    {
        $primaryCat = Cat::find($id);
        if (!$primaryCat) {
            return ApiResponse::error('Profil kucing utama tidak ditemukan.', 404, 'NOT_FOUND');
        }

        $validated = $request->validated();
        $duplicateCat = Cat::find($validated['duplicate_cat_id']);
        if (!$duplicateCat) {
            return ApiResponse::error('Profil kucing duplikat tidak ditemukan.', 404, 'NOT_FOUND');
        }

        try {
            $result = $this->catMergeService->merge(
                $primaryCat,
                $duplicateCat,
                $request->user(),
                $validated['reason']
            );
        } catch (ConflictHttpException $e) {
            return ApiResponse::error($e->getMessage(), 409, 'CONFLICT');
        }

        return ApiResponse::success($result, 'Profil kucing duplikat berhasil digabungkan.');
    }
}
