<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\FeedingSpot\Filament\Resources\FeedingReviewQueueResource;
use App\Modules\FeedingSpot\Filament\Resources\FeedingSpotResource;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingReviewService;
use App\Modules\FeedingSpot\Services\FeedingSpotManagementService;
use App\Modules\FeedingSpot\Services\FeedingSpotQrCodeService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class AdminFeedingSpotController extends Controller
{
    public function __construct(
        private readonly FeedingReviewService $reviewService,
        private readonly FeedingSpotManagementService $spotService,
        private readonly FeedingSpotQrCodeService $qrService,
    ) {}

    /**
     * GET /api/v1/admin/feeding/spots
     * Daftar seluruh feeding spot untuk admin (termasuk INACTIVE),
     * dengan filter status, pencarian nama/kode, dan paginasi (AFS-01, Bagian 8.4).
     * Permission: spot.manage
     */
    public function indexSpots(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['nullable', 'string', Rule::in(FeedingSpotManagementService::ALLOWED_STATUSES)],
            'territory_id' => ['nullable', 'string', 'size:26'],
            'search' => ['nullable', 'string', 'max:255'],
            'q' => ['nullable', 'string', 'max:255'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $perPage = (int) ($validated['per_page'] ?? 15);
        $paginator = $this->spotService->paginateAdminSpots($validated, $perPage);

        return ApiResponse::paginated($paginator, 'Daftar titik feeding spot admin berhasil diambil.');
    }

    /**
     * GET /api/v1/admin/feeding/spots/{id}
     * Detail lengkap feeding spot untuk admin, termasuk status_reason,
     * token QR aktif, kucing terkait, dan log audit (AFS-01, Bagian 8.4).
     * Permission: spot.manage
     */
    public function showSpot(string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $detail = $this->spotService->getAdminSpotDetail($spot);

        return ApiResponse::success($detail, 'Detail titik feeding spot berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/spots
     * Buat titik feeding spot baru beserta token QR resmi (AFS-01, MEOW-7).
     * Permission: spot.manage
     */
    public function storeSpot(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => ['nullable', 'string', 'max:64', 'unique:feeding_spots,code'],
            'name' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'status' => ['nullable', 'string', Rule::in(FeedingSpotManagementService::ALLOWED_STATUSES)],
            'status_reason' => [
                'nullable',
                'string',
                'max:500',
                Rule::requiredIf(fn () => strtoupper((string) $request->input('status', 'ACTIVE')) === 'TEMPORARILY_UNAVAILABLE'),
            ],
            'photo' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'photo_media_id' => ['nullable', 'string', 'size:26', 'exists:media_files,id'],
        ]);

        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo');
        }

        $spot = $this->spotService->createSpot($validated, $request->user());

        return ApiResponse::created(
            $this->spotService->formatAdminSpot($spot),
            'Titik feeding spot berhasil dibuat.'
        );
    }

    /**
     * PATCH /api/v1/admin/feeding/spots/{id}
     * Perbarui data, koordinat, atau status feeding spot (ACTIVE, MAINTENANCE, TEMPORARILY_UNAVAILABLE, INACTIVE).
     * Tidak ada DELETE: menonaktifkan spot dilakukan dengan PATCH status ke INACTIVE (AFS-01, Bagian 8.4).
     * Permission: spot.manage
     */
    public function updateSpot(Request $request, string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $validated = $request->validate([
            'code' => ['sometimes', 'required', 'string', 'max:64', Rule::unique('feeding_spots', 'code')->ignore($spot->id)],
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'latitude' => ['sometimes', 'required', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'required', 'numeric', 'between:-180,180'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'status' => ['sometimes', 'required', 'string', Rule::in(FeedingSpotManagementService::ALLOWED_STATUSES)],
            'status_reason' => [
                'nullable',
                'string',
                'max:500',
                Rule::requiredIf(function () use ($request, $spot) {
                    $targetStatus = strtoupper((string) ($request->input('status') ?? $spot->status));
                    if ($targetStatus !== 'TEMPORARILY_UNAVAILABLE') {
                        return false;
                    }

                    return $request->has('status') || $request->has('status_reason') || empty($spot->status_reason);
                }),
            ],
            'photo' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'photo_media_id' => ['nullable', 'string', 'size:26', 'exists:media_files,id'],
            'remove_photo' => ['nullable', 'boolean'],
        ]);

        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo');
        }
        if ($request->boolean('remove_photo')) {
            $validated['remove_photo'] = true;
        }

        $updated = $this->spotService->updateSpot($spot, $validated, $request->user());

        return ApiResponse::success(
            $this->spotService->formatAdminSpot($updated),
            'Titik feeding spot berhasil diperbarui.'
        );
    }

    /**
     * POST /api/v1/admin/feeding/spots/{id}/qr
     * POST /api/v1/admin/feeding/spots/{id}/qr/regenerate
     * Regenerate token QR feeding spot, cabut token lama, dan catat ke audit_logs (AFS-01, MEOW-7).
     * Permission: spot.manage
     */
    public function regenerateQr(Request $request, string $id): JsonResponse
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $updated = $this->spotService->regenerateQr($spot, $request->user());

        return ApiResponse::success([
            'spot_id' => $updated->id,
            'code' => $updated->code,
            'qr_token' => $updated->qr_token,
            'qr_payload' => "MTP1.S.{$updated->qr_token}",
        ], 'Token QR feeding spot berhasil diperbarui.');
    }

    /**
     * GET /api/v1/admin/feeding/review-queue
     * Daftar antrean pengajuan pemberian makan berstatus UNDER_REVIEW (AFS-07, MEOW-12, MEOW-22).
     * Permission: feeding.review
     */
    public function reviewQueue(Request $request): JsonResponse
    {
        $status = $request->filled('status')
            ? $request->string('status')->upper()->toString()
            : 'UNDER_REVIEW';

        $excludeSelf = $request->boolean('exclude_self', false);

        $items = $this->reviewService
            ->getReviewQueueQuery($request->user(), excludeSelf: $excludeSelf, status: $status)
            ->orderBy('finalized_at')
            ->get()
            ->map(fn (FeedingActivity $a) => $this->reviewService->formatQueueItem($a))
            ->values();

        return ApiResponse::success($items, 'Antrean review pemberian pakan berhasil diambil.');
    }

    /**
     * POST /api/v1/admin/feeding/activities/{id}/review
     * Simpan keputusan reviewer (VERIFIED atau REJECTED) dengan larangan self-review (AFS-07, AFS-10, MEOW-12, MEOW-22).
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
            'notes' => ['required_without:reason', 'nullable', 'string', 'max:1000'],
            'reason' => ['required_without:notes', 'nullable', 'string', 'max:1000'],
        ]);

        if (!in_array($activity->status, ['UNDER_REVIEW', 'SUBMITTED', 'VERIFIED', 'REJECTED'], true)) {
            return ApiResponse::error(
                "Aktivitas berstatus {$activity->status} tidak dapat direview.",
                422,
                'INVALID_ACTIVITY_STATUS'
            );
        }

        $decision = $validated['decision'];
        $reason = $validated['notes'] ?? $validated['reason'] ?? null;

        $payload = $this->reviewService->reviewActivity($activity, $reviewer, $decision, $reason);

        return ApiResponse::success($payload, 'Keputusan review berhasil disimpan.');
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
     * Tampilkan lembar cetak QR resmi untuk satu spot pakan (MEOW-21, MEOW-28).
     */
    public function printQrSheet(string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $payload = $this->qrService->formatSpotPayload($spot->qr_token);
        $campusLoc = FeedingSpotManagementService::resolveCampusLocation(
            (float) $spot->latitude,
            (float) $spot->longitude,
            $spot->code,
            $spot->name
        );

        $spotItem = [
            'spot' => $spot,
            'payload' => $payload,
            'qr_svg' => $this->qrService->renderSvg($payload, 240, 4),
            'location_name' => $campusLoc['name'],
            'location_number' => $campusLoc['number'],
        ];

        return view('feeding-spot::filament.qr-sheet', [
            'spot' => $spot,
            'spotItems' => [$spotItem],
            'qrSvg' => $spotItem['qr_svg'],
            'qrPayload' => $payload,
            'locationName' => $campusLoc['name'],
            'isMulti' => false,
        ]);
    }

    /**
     * GET /api/v1/admin/feeding/spots/qr-sheet
     * Tampilkan lembar cetak QR resmi untuk beberapa/seluruh spot pakan aktif (MEOW-7, MEOW-21).
     */
    public function printAllQrSheets(Request $request)
    {
        $query = FeedingSpot::query()->orderBy('code');

        if ($request->filled('ids')) {
            $ids = array_filter(array_map('trim', explode(',', (string) $request->query('ids'))));
            if (!empty($ids)) {
                $query->where(function ($q) use ($ids) {
                    $q->whereIn('id', $ids)->orWhereIn('code', $ids);
                });
            }
        } else {
            $query->where('status', '!=', 'INACTIVE');
        }

        $spots = $query->get();
        if ($spots->isEmpty()) {
            $spots = FeedingSpot::query()->orderBy('code')->get();
        }

        $spotItems = $spots->map(function (FeedingSpot $s) {
            $payload = $this->qrService->formatSpotPayload($s->qr_token);
            $campusLoc = FeedingSpotManagementService::resolveCampusLocation(
                (float) $s->latitude,
                (float) $s->longitude,
                $s->code,
                $s->name
            );

            return [
                'spot' => $s,
                'payload' => $payload,
                'qr_svg' => $this->qrService->renderSvg($payload, 220, 4),
                'location_name' => $campusLoc['name'],
                'location_number' => $campusLoc['number'],
            ];
        })->values()->all();

        $firstSpot = $spots->first();

        return view('feeding-spot::filament.qr-sheet', [
            'spot' => $firstSpot,
            'spotItems' => $spotItems,
            'qrSvg' => $spotItems[0]['qr_svg'] ?? '',
            'qrPayload' => $spotItems[0]['payload'] ?? '',
            'locationName' => $spotItems[0]['location_name'] ?? 'Area Kampus Telkom University',
            'isMulti' => count($spotItems) > 1,
        ]);
    }

    /**
     * GET /api/v1/admin/feeding/spots/{id}/qr-download?format=png|svg
     * GET /api/v1/feeding/admin-preview/spots/{id}/qr-download?format=png|svg
     * Unduh berkas gambar QR Code spot dalam format PNG atau SVG siap cetak (MEOW-21, MEOW-28).
     */
    public function downloadSpotQr(Request $request, string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->first();
        if (!$spot) {
            return ApiResponse::error('Titik feeding spot tidak ditemukan.', 404, 'SPOT_NOT_FOUND');
        }

        $payload = $this->qrService->formatSpotPayload($spot->qr_token);
        $format = strtolower((string) $request->query('format', 'png'));
        $safeCode = preg_replace('/[^A-Za-z0-9\-_]/', '_', $spot->code);

        if ($format === 'svg') {
            $svg = $this->qrService->renderSvg($payload, 512, 4);
            return response($svg, 200, [
                'Content-Type' => 'image/svg+xml; charset=utf-8',
                'Content-Disposition' => "attachment; filename=\"QR-{$safeCode}.svg\"",
            ]);
        }

        $png = $this->qrService->renderPng($payload, 12, 4);
        return response($png, 200, [
            'Content-Type' => 'image/png',
            'Content-Disposition' => "attachment; filename=\"QR-{$safeCode}.png\"",
        ]);
    }

    /**
     * GET /api/v1/admin/feeding/reviews/{id}
     * Halaman inspeksi bukti foto & hasil rule engine untuk reviewer (MEOW-22).
     */
    public function showReviewEvidence(Request $request, string $id)
    {
        $activity = FeedingActivity::with([
            'user:id,name,user_type',
            'spot:id,code,name,latitude,longitude,status',
            'cat:id,unique_code,name',
            'evidence',
            'ruleResults',
            'latestReview.reviewer:id,name',
            'reviews.reviewer:id,name',
        ])
            ->where('id', $id)
            ->orWhere('feeding_record_ref', $id)
            ->first();

        if (!$activity) {
            return ApiResponse::error('Aktivitas pemberian pakan tidak ditemukan.', 404, 'ACTIVITY_NOT_FOUND');
        }

        if ($request->user() && $activity->user_id === $request->user()->id) {
            return ApiResponse::error(
                'Reviewer tidak diperbolehkan memeriksa pengajuan pemberian pakan miliknya sendiri.',
                403,
                'SELF_REVIEW_FORBIDDEN'
            );
        }

        return view('feeding-spot::filament.review-evidence', [
            'activity' => $activity,
        ]);
    }

    /**
     * GET /api/v1/admin/feeding/evidence/{mediaId}/file
     * Stream foto bukti pakan hanya melalui URL bertanda tangan (berlaku 10 menit) (CORE-05, MEOW-22).
     */
    public function streamEvidenceMedia(Request $request, string $mediaId)
    {
        if (!$request->hasValidSignature()) {
            return ApiResponse::error(
                'Akses ditolak. Foto bukti hanya dapat dibuka melalui URL bertanda tangan yang valid (berlaku 10 menit).',
                403,
                'INVALID_SIGNATURE'
            );
        }

        $media = DB::table('media_files')->where('id', $mediaId)->first();
        if (!$media) {
            return ApiResponse::error('Berkas media bukti pakan tidak ditemukan.', 404, 'MEDIA_NOT_FOUND');
        }

        $disk = Storage::disk($media->disk ?? 'local');
        if (!empty($media->path) && $disk->exists($media->path)) {
            return response($disk->get($media->path), 200, [
                'Content-Type' => $media->mime ?? 'image/jpeg',
                'Cache-Control' => 'private, max-age=600',
            ]);
        }

        $svg = '<svg xmlns="http://www.w3.org/2000/svg" width="480" height="320" viewBox="0 0 480 320">'
            . '<rect width="480" height="320" fill="#1E293B"/>'
            . '<circle cx="240" cy="145" r="70" fill="#F59E0B" opacity="0.2"/>'
            . '<text x="240" y="135" text-anchor="middle" fill="#F8FAFC" font-family="sans-serif" font-size="18" font-weight="bold">Foto Bukti Pakan (Signed 10m)</text>'
            . '<text x="240" y="165" text-anchor="middle" fill="#94A3B8" font-family="monospace" font-size="12">Media ID: ' . htmlspecialchars((string) $media->id) . '</text>'
            . '<text x="240" y="190" text-anchor="middle" fill="#38BDF8" font-family="monospace" font-size="11">SHA-256: ' . substr((string) ($media->sha256 ?? ''), 0, 24) . '...</text>'
            . '</svg>';

        return response($svg, 200, [
            'Content-Type' => 'image/svg+xml',
            'Cache-Control' => 'private, max-age=600',
        ]);
    }

    /**
     * GET /api/v1/feeding/admin-preview
     * Halaman web Dashboard Admin (MEOW-21 & MEOW-22) dengan CRUD Lokasi Spot,
     * filter status, pencarian nama, paginasi, audit log, dan antrean review.
     */
    public function adminPreviewPanel(Request $request)
    {
        $reviewer = User::where('email', 'spotadmin@telkomuniversity.ac.id')->first();
        $pendingActivities = FeedingReviewQueueResource::getEloquentQuery($reviewer)
            ->orderByDesc('finalized_at')
            ->get();

        $reviewedActivities = FeedingActivity::query()
            ->whereIn('status', ['VERIFIED', 'REJECTED'])
            ->with([
                'user:id,name,user_type',
                'spot:id,code,name',
                'latestReview.reviewer:id,name',
                'reviews.reviewer:id,name',
            ])
            ->orderByDesc('updated_at')
            ->limit(30)
            ->get();

        $filters = [
            'status' => $request->query('status', ''),
            'search' => $request->query('search', $request->query('q', '')),
        ];
        $perPage = (int) $request->query('per_page', 10);

        $spotsPaginator = FeedingSpotResource::paginateRecords($filters, $perPage);
        $spotsPaginator->appends($request->query());

        $statusCounts = FeedingSpot::query()
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status')
            ->all();

        $allSpotsCount = array_sum($statusCounts);
        $auditLogs = $this->spotService->getSpotAuditLogs(null, 40);
        $existingSpotCodes = FeedingSpot::query()->pluck('code')->all();
        $availableCats = DB::table('cats')
            ->select(['id', 'unique_code', 'name', 'presence_status', 'health_status'])
            ->orderBy('name')
            ->get();

        return view('feeding-spot::filament.admin-panel', [
            'pendingActivities' => $pendingActivities,
            'reviewedActivities' => $reviewedActivities,
            'spots' => collect($spotsPaginator->items()),
            'spotsPaginator' => $spotsPaginator,
            'statusCounts' => $statusCounts,
            'allSpotsCount' => $allSpotsCount,
            'auditLogs' => $auditLogs,
            'existingSpotCodes' => $existingSpotCodes,
            'availableCats' => $availableCats,
            'telkomBoundary' => FeedingSpotManagementService::TELKOM_BOUNDARY,
            'campusLocations' => FeedingSpotManagementService::CAMPUS_LOCATIONS,
            'filters' => $filters,
            'activeTab' => $request->query('tab', 'spots'),
        ]);
    }

    /**
     * GET /api/v1/feeding/assets/logo.jpg
     * Serve logo resmi aplikasi Meowtopia untuk Sidebar & Lembar Cetak QR.
     */
    public function serveLogoAsset()
    {
        $path = __DIR__ . '/../resources/assets/meowtopia-logo.jpg';
        if (!file_exists($path)) {
            abort(404);
        }

        return response(file_get_contents($path), 200, [
            'Content-Type' => 'image/jpeg',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    /**
     * POST /api/v1/feeding/admin-preview/spots
     * Buat spot baru melalui Dashboard Admin Web dengan validasi poligon wilayah Telkom University.
     */
    public function adminPreviewStoreSpot(Request $request)
    {
        $actor = User::where('email', 'spotadmin@telkomuniversity.ac.id')->first();

        try {
            $validated = $request->validate([
                'code' => ['nullable', 'string', 'max:64'],
                'name' => ['required', 'string', 'max:255'],
                'description' => ['nullable', 'string', 'max:1000'],
                'latitude' => ['required', 'numeric', 'between:-90,90'],
                'longitude' => ['required', 'numeric', 'between:-180,180'],
                'status' => ['nullable', 'string', Rule::in(FeedingSpotManagementService::ALLOWED_STATUSES)],
                'status_reason' => [
                    'nullable',
                    'string',
                    'max:500',
                    Rule::requiredIf(fn () => strtoupper((string) $request->input('status', 'ACTIVE')) === 'TEMPORARILY_UNAVAILABLE'),
                ],
                'photo' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            $msg = collect($e->errors())->flatten()->implode(' ');
            return redirect('/api/v1/feeding/admin-preview?tab=spots&error=' . urlencode($msg));
        }

        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo');
        }

        if (!FeedingSpotManagementService::isPointInsideTelkomCampus((float) $validated['latitude'], (float) $validated['longitude'])) {
            return redirect('/api/v1/feeding/admin-preview?tab=spots&error=' . urlencode('Titik lokasi ditolak: Koordinat berada di luar batas wilayah Kampus Telkom University.'));
        }

        // Jika kode tidak diisi atau sudah terpakai, hasilkan otomatis di backend (MEOW-29)
        $submittedCode = isset($validated['code']) ? strtoupper(trim((string) $validated['code'])) : '';
        if ($submittedCode === '' || FeedingSpot::query()->where('code', $submittedCode)->exists()) {
            $validated['auto_code'] = true;
            unset($validated['code']);
        } else {
            $validated['code'] = $submittedCode;
        }

        if ($request->filled('territory_code')) {
            $territoryId = DB::table('territories')
                ->where('code', strtoupper((string) $request->input('territory_code')))
                ->value('id');
            if ($territoryId) {
                $validated['territory_id'] = $territoryId;
            }
        }

        $spot = FeedingSpotResource::createRecord($validated, $actor);

        if ($request->filled('cat_id')) {
            $catId = (string) $request->input('cat_id');
            if (DB::table('cats')->where('id', $catId)->exists()) {
                $spot->cats()->sync([$catId]);
            }
        }

        return redirect('/api/v1/feeding/admin-preview?tab=spots&notice=' . urlencode("Spot {$spot->code} ({$spot->name}) berhasil ditambahkan."));
    }

    /**
     * POST /api/v1/feeding/admin-preview/spots/{id}/update
     * Perbarui spot atau nonaktifkan ke INACTIVE melalui Dashboard Admin Web.
     */
    public function adminPreviewUpdateSpot(Request $request, string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->firstOrFail();
        $actor = User::where('email', 'spotadmin@telkomuniversity.ac.id')->first();

        try {
            $validated = $request->validate([
                'code' => ['sometimes', 'required', 'string', 'max:64', Rule::unique('feeding_spots', 'code')->ignore($spot->id)],
                'name' => ['sometimes', 'required', 'string', 'max:255'],
                'description' => ['nullable', 'string', 'max:1000'],
                'latitude' => ['sometimes', 'required', 'numeric', 'between:-90,90'],
                'longitude' => ['sometimes', 'required', 'numeric', 'between:-180,180'],
                'status' => ['sometimes', 'required', 'string', Rule::in(FeedingSpotManagementService::ALLOWED_STATUSES)],
                'status_reason' => [
                    'nullable',
                    'string',
                    'max:500',
                    Rule::requiredIf(function () use ($request, $spot) {
                        $targetStatus = strtoupper((string) ($request->input('status') ?? $spot->status));
                        return $targetStatus === 'TEMPORARILY_UNAVAILABLE';
                    }),
                ],
                'photo' => ['nullable', 'file', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
                'remove_photo' => ['nullable', 'boolean'],
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            $msg = collect($e->errors())->flatten()->implode(' ');
            return redirect('/api/v1/feeding/admin-preview?tab=spots&error=' . urlencode($msg));
        }

        if ($request->hasFile('photo')) {
            $validated['photo'] = $request->file('photo');
        }
        if ($request->boolean('remove_photo')) {
            $validated['remove_photo'] = true;
        }

        if (isset($validated['latitude'], $validated['longitude'])) {
            if (!FeedingSpotManagementService::isPointInsideTelkomCampus((float) $validated['latitude'], (float) $validated['longitude'])) {
                return redirect('/api/v1/feeding/admin-preview?tab=spots&error=' . urlencode('Titik lokasi ditolak: Koordinat berada di luar batas wilayah Kampus Telkom University.'));
            }
        }

        if ($request->filled('territory_code')) {
            $territoryId = DB::table('territories')
                ->where('code', strtoupper((string) $request->input('territory_code')))
                ->value('id');
            if ($territoryId) {
                $validated['territory_id'] = $territoryId;
            }
        }

        $updated = FeedingSpotResource::updateRecord($spot, $validated, $actor);

        if ($request->has('cat_id')) {
            $catId = trim((string) $request->input('cat_id', ''));
            if ($catId === '') {
                $updated->cats()->detach();
            } elseif (DB::table('cats')->where('id', $catId)->exists()) {
                $updated->cats()->sync([$catId]);
            }
        }

        return redirect('/api/v1/feeding/admin-preview?tab=spots&notice=' . urlencode("Spot {$updated->code} berhasil diperbarui."));
    }

    /**
     * POST /api/v1/feeding/admin-preview/spots/{id}/cats
     * Simpan pilihan dropdown informasi kucing pada spot pakan (MEOW-23).
     */
    public function adminPreviewAttachCat(Request $request, string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->firstOrFail();

        $catId = trim((string) $request->input('cat_id', ''));
        if ($catId === '') {
            $spot->cats()->detach();
            if ($request->expectsJson()) {
                return ApiResponse::success(['spot_id' => $spot->id, 'cat_id' => null], 'Pilihan kucing pada spot dikosongkan.');
            }
            return redirect('/api/v1/feeding/admin-preview?tab=spots&notice=' . urlencode("Informasi kucing pada spot {$spot->code} diperbarui."));
        }

        if (!DB::table('cats')->where('id', $catId)->exists()) {
            if ($request->expectsJson()) {
                return ApiResponse::error('Pilih data kucing kampus yang valid.', 422, 'INVALID_CAT');
            }
            return redirect('/api/v1/feeding/admin-preview?tab=spots&error=' . urlencode('Pilih data kucing kampus yang valid.'));
        }

        $spot->cats()->sync([$catId]);

        if ($request->expectsJson()) {
            return ApiResponse::success(['spot_id' => $spot->id, 'cat_id' => $catId], 'Informasi kucing pada spot berhasil diperbarui.');
        }

        return redirect('/api/v1/feeding/admin-preview?tab=spots&notice=' . urlencode("Informasi kucing pada spot {$spot->code} berhasil diperbarui."));
    }

    /**
     * POST /api/v1/feeding/admin-preview/spots/{id}/cats/{catId}/detach
     * Lepas asosiasi kucing dari spot pakan melalui Dashboard Admin Web (MEOW-23).
     */
    public function adminPreviewDetachCat(string $id, string $catId)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->firstOrFail();
        $spot->cats()->detach($catId);

        return redirect('/api/v1/feeding/admin-preview?tab=spots&notice=' . urlencode("Asosiasi kucing pada spot {$spot->code} berhasil dilepas."));
    }

    /**
     * POST /api/v1/feeding/admin-preview/spots/{id}/qr
     * Regenerasi token QR spot dari Dashboard Admin Web.
     */
    public function adminPreviewRegenerateQr(string $id)
    {
        $spot = FeedingSpot::where('id', $id)->orWhere('code', $id)->firstOrFail();
        $actor = User::where('email', 'spotadmin@telkomuniversity.ac.id')->first();

        $updated = FeedingSpotResource::regenerateQrToken($spot, $actor);

        return redirect('/api/v1/feeding/admin-preview?tab=spots&regenerated_spot=' . urlencode($updated->id) . '&notice=' . urlencode("Token QR untuk {$updated->code} ({$updated->name}) berhasil diganti. QR Code sebelumnya telah dinonaktifkan."));
    }

    /**
     * GET /api/v1/feeding/admin-preview/reviews/{id}
     * Halaman web inspeksi bukti foto dari Panel Admin browser.
     */
    public function adminPreviewReview(string $id)
    {
        $activity = FeedingActivity::with([
            'user:id,name,user_type',
            'spot:id,code,name,latitude,longitude,status',
            'cat:id,unique_code,name',
            'evidence',
            'ruleResults',
            'latestReview.reviewer:id,name',
            'reviews.reviewer:id,name',
        ])
            ->where('id', $id)
            ->orWhere('feeding_record_ref', $id)
            ->firstOrFail();

        return view('feeding-spot::filament.review-evidence', [
            'activity' => $activity,
            'backUrl' => '/api/v1/feeding/admin-preview?tab=reviews',
            'reviewActionUrl' => "/api/v1/feeding/admin-preview/activities/{$activity->id}/review",
        ]);
    }

    /**
     * POST /api/v1/feeding/admin-preview/activities/{id}/review
     * Submit keputusan VERIFIED / REJECTED dari Panel Admin browser.
     */
    public function adminPreviewSubmitReview(Request $request, string $id)
    {
        if (empty(config('permission.column_names.role_pivot_key'))) {
            config([
                'permission.column_names.role_pivot_key' => 'role_id',
                'permission.column_names.permission_pivot_key' => 'permission_id',
            ]);
        }

        $activity = FeedingActivity::with(['user', 'spot'])->findOrFail($id);
        $reviewer = User::where('email', 'spotadmin@telkomuniversity.ac.id')->firstOrFail();

        if (!$reviewer->can('feeding.review')) {
            \Spatie\Permission\Models\Permission::firstOrCreate(['name' => 'feeding.review', 'guard_name' => 'web']);
            \Spatie\Permission\Models\Permission::firstOrCreate(['name' => 'feeding.review', 'guard_name' => 'sanctum']);
            $roleWeb = \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'spot_admin', 'guard_name' => 'web']);
            $roleWeb->givePermissionTo('feeding.review');
            $reviewer->assignRole($roleWeb);
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
            $reviewer->unsetRelation('roles')->unsetRelation('permissions');
        }

        $decision = strtoupper(trim((string) $request->input('decision', 'VERIFIED')));
        $reason = trim((string) ($request->input('reason') ?? $request->input('notes') ?? ''));

        if ($reason === '') {
            return redirect("/api/v1/feeding/admin-preview/reviews/{$activity->id}?error=" . urlencode('Alasan keputusan review wajib diisi sebelum menyetujui atau menolak pengajuan.'));
        }

        try {
            $result = FeedingReviewQueueResource::submitDecision(
                $activity,
                $reviewer,
                $decision,
                $reason
            );
        } catch (\Illuminate\Validation\ValidationException $e) {
            $msg = collect($e->errors())->flatten()->implode(' ');
            return redirect("/api/v1/feeding/admin-preview/reviews/{$activity->id}?error=" . urlencode($msg));
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return redirect("/api/v1/feeding/admin-preview/reviews/{$activity->id}?error=" . urlencode($e->getMessage()));
        }

        if ($decision === 'REJECTED') {
            $notice = "Pengajuan {$activity->feeding_record_ref} berhasil DITOLAK (REJECTED), dikeluarkan dari Antrean Review aktif, dan tercatat di Riwayat Audit.";
        } else {
            $pts = (int) ($result['points_awarded'] ?? 0);
            $notice = "Pengajuan {$activity->feeding_record_ref} berhasil DISETUJUI (VERIFIED, +{$pts} poin), dikeluarkan dari Antrean Review aktif, dan tercatat di Riwayat Audit.";
        }

        return redirect('/api/v1/feeding/admin-preview?tab=reviews&notice=' . urlencode($notice));
    }

    /**
     * GET /api/v1/feeding/admin-preview/spots/{id}/qr-sheet
     * Lembar cetak QR dari Panel Admin browser.
     */
    public function adminPreviewQrSheet(string $id)
    {
        return $this->printQrSheet($id);
    }

    /**
     * GET /api/v1/feeding/admin-preview/qr-sheet
     * Lembar cetak seluruh QR spot aktif dari Panel Admin browser.
     */
    public function adminPreviewAllQrSheets(Request $request)
    {
        return $this->printAllQrSheets($request);
    }
}
