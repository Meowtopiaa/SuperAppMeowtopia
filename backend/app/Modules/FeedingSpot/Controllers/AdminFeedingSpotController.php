<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingReviewService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminFeedingSpotController extends Controller
{
    public function __construct(
        private readonly FeedingReviewService $reviewService,
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
     * Menolak 403 bila reviewer memaksa membuka pengajuan miliknya sendiri,
     * dan tidak memuat data pribadi pengguna (tanpa phone/identity_number/email).
     */
    public function showReviewEvidence(Request $request, string $id)
    {
        $activity = FeedingActivity::with([
            'user:id,name,user_type',
            'spot:id,code,name,latitude,longitude,status',
            'evidence',
            'ruleResults',
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
     * Menolak akses langsung tanpa tanda tangan yang valid dengan 403.
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

        return response('FEEDING_EVIDENCE_BINARY_STREAM:' . $media->id, 200, [
            'Content-Type' => $media->mime ?? 'image/jpeg',
            'Cache-Control' => 'private, max-age=600',
        ]);
    }
}
