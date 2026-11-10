<?php

namespace App\Modules\Core\Services;

use App\Modules\Cat\Models\Cat;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;

class ScanResolver
{
    /**
     * Resolve scanned QR payload or manual collar code.
     * Raw QR formats:
     * - MTP1.C.<token> for cats
     * - MTP1.S.<token> for feeding spots
     * Manual input fallback: unique_code (e.g., CAT001, SPOT-TULT-01)
     */
    public function resolve(string $rawCode): array
    {
        $code = trim($rawCode);
        $parts = explode('.', $code);

        // 1. Standard QR Format: MTP1.<Type>.<Token>
        if (count($parts) === 3 && $parts[0] === 'MTP1') {
            $kind = $parts[1];
            $token = $parts[2];

            if ($kind === 'C') {
                return $this->resolveCatByQrToken($token);
            } elseif ($kind === 'S') {
                return $this->resolveSpotByQrToken($token);
            } else {
                throw new BadRequestHttpException("QR_INVALID: Format tipe QR tidak dikenali.");
            }
        }

        // 2. Manual Backup Code Fallback
        // Check if matches cat unique_code
        $cat = Cat::where('unique_code', $code)->first();
        if ($cat) {
            return [
                'type' => 'cat',
                'id' => $cat->id,
                'code' => $cat->unique_code,
                'name' => $cat->name,
                'is_manual' => true,
            ];
        }

        // Check if matches feeding spot code
        $spot = DB::table('feeding_spots')->where('code', $code)->first();
        if ($spot) {
            return [
                'type' => 'spot',
                'id' => $spot->id,
                'code' => $spot->code,
                'name' => $spot->name,
                'is_manual' => true,
            ];
        }

        throw new NotFoundHttpException("QR_INVALID: Kode QR atau kode manual tidak terdaftar.");
    }

    protected function resolveCatByQrToken(string $token): array
    {
        $qrRecord = DB::table('cat_qr_tokens')
            ->where('token', $token)
            ->first();

        if (!$qrRecord) {
            throw new NotFoundHttpException("QR_INVALID: Token QR kucing tidak ditemukan.");
        }

        if ($qrRecord->status === 'REVOKED') {
            throw new BadRequestHttpException("QR_REVOKED: Kalung QR ini telah dicabut/diganti. Gunakan kode cadangan kalung.");
        }

        $cat = Cat::find($qrRecord->cat_id);
        if (!$cat) {
            throw new NotFoundHttpException("CAT_NOT_FOUND: Data kucing tidak ditemukan.");
        }

        return [
            'type' => 'cat',
            'id' => $cat->id,
            'code' => $cat->unique_code,
            'name' => $cat->name,
            'is_manual' => false,
        ];
    }

    protected function resolveSpotByQrToken(string $token): array
    {
        $spot = DB::table('feeding_spots')
            ->where('qr_token', $token)
            ->first();

        if (!$spot) {
            throw new NotFoundHttpException("QR_INVALID: Token QR spot pakan tidak ditemukan.");
        }

        return [
            'type' => 'spot',
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'status' => $spot->status,
            'is_manual' => false,
        ];
    }
}

