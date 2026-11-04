<?php

namespace App\Modules\Core\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Core\Services\MediaService;
use App\Modules\Core\Services\ScanResolver;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CoreController extends Controller
{
    /**
     * Resolve scanned QR or manual collar code.
     * GET /api/v1/scan/resolve?code=...
     */
    public function resolveScan(Request $request, ScanResolver $resolver)
    {
        $code = $request->query('code');
        if (!$code) {
            return ApiResponse::error('Parameter query "code" diperlukan.', 400, 'VALIDATION_ERROR');
        }

        try {
            $result = $resolver->resolve($code);
            return ApiResponse::success($result, 'Kode berhasil diidentifikasi.');
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return ApiResponse::error($e->getMessage(), $e->getStatusCode(), 'QR_INVALID');
        } catch (\Throwable $e) {
            return ApiResponse::error($e->getMessage(), 500, 'SERVER_ERROR');
        }
    }

    /**
     * Upload media file (photo/video).
     * POST /api/v1/media (with Idempotency-Key)
     */
    public function uploadMedia(Request $request, MediaService $mediaService)
    {
        $request->validate([
            'file' => ['required', 'file', 'max:5120'], // Max 5MB
            'purpose' => ['required', 'string', 'in:avatar,feeding_proof,adoption_evidence,incident_media,cat_photo'],
        ]);

        try {
            $user = $request->user();
            $uploaded = $mediaService->store(
                $request->file('file'),
                $request->input('purpose'),
                $user
            );

            return ApiResponse::created($uploaded, 'Media berhasil diunggah.');
        } catch (\Throwable $e) {
            return ApiResponse::error($e->getMessage(), 422, 'VALIDATION_ERROR');
        }
    }

    /**
     * Get temporary signed URL for a media file.
     * GET /api/v1/media/{id}/url
     */
    public function getMediaUrl(string $id, MediaService $mediaService)
    {
        $url = $mediaService->getUrl($id);
        if (!$url) {
            return ApiResponse::error('Berkas media tidak ditemukan.', 404, 'NOT_FOUND');
        }

        return ApiResponse::success(['url' => $url], 'URL media berhasil diambil.');
    }

    /**
     * Get current user points and recent transactions.
     * GET /api/v1/points/me
     */
    public function myPoints(Request $request)
    {
        $user = $request->user();

        $balance = DB::table('point_balances')
            ->where('user_id', $user->id)
            ->value('total_points') ?? 0;

        $transactions = DB::table('point_transactions')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(20)
            ->get();

        return ApiResponse::success([
            'total_points' => (int) $balance,
            'recent_transactions' => $transactions,
        ], 'Data poin berhasil diambil.');
    }
}

