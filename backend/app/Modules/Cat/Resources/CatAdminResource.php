<?php

namespace App\Modules\Cat\Resources;

use App\Modules\Cat\Services\QrCodeService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Admin representation of a Cat for authorized data curators.
 */
class CatAdminResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $base = (new CatPublicResource($this->resource))->toArray($request);
        $qrService = app(QrCodeService::class);

        $activeToken = $this->relationLoaded('activeQrToken')
            ? $this->activeQrToken
            : $this->activeQrToken()->first();

        return array_merge($base, [
            'active_qr' => $activeToken ? [
                'token_id' => $activeToken->id,
                'status' => $activeToken->status,
                'qr_payload' => $qrService->formatQrPayload($activeToken->token),
                'issued_at' => $activeToken->issued_at?->toIso8601String(),
            ] : null,
            'deleted_at' => $this->deleted_at?->toIso8601String(),
        ]);
    }
}

