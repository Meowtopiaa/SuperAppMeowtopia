<?php

namespace App\Modules\Cat\Services;

use Illuminate\Support\Str;

class QrCodeService
{
    /**
     * Generate 32-character random token for a cat collar.
     * Raw QR string in the collar tag is: MTP1.C.<token>
     */
    public function generateToken(): string
    {
        return Str::random(32);
    }

    /**
     * Format full QR payload string
     */
    public function formatQrPayload(string $token): string
    {
        return 'MTP1.C.' . $token;
    }

    /**
     * Parse raw QR content. Returns the token if valid, null otherwise.
     */
    public function parseCatQr(string $qrContent): ?string
    {
        $parts = explode('.', trim($qrContent));
        if (count($parts) === 3 && $parts[0] === 'MTP1' && $parts[1] === 'C') {
            return $parts[2];
        }
        return null;
    }
}
