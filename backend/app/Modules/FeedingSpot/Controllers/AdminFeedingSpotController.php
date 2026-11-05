<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AdminFeedingSpotController extends Controller
{
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
}
