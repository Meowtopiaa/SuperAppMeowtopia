<?php

namespace App\Modules\Cat\Services;

use Illuminate\Support\Str;

class QrCodeService
{
    /**
     * Generate unique collar QR code token for a cat
     */
    public function generateCatQrToken(string $prefix = 'MEOW-CAT'): string
    {
        return $prefix . '-' . strtoupper(Str::random(10));
    }

    /**
     * Verify or parse a QR code string
     */
    public function parseCatQr(string $qrContent): ?string
    {
        if (str_starts_with($qrContent, 'MEOW-CAT-')) {
            return trim($qrContent);
        }
        return null;
    }
}
