<?php

namespace App\Modules\Cat\Services;

use App\Models\User;
use App\Modules\Cat\Events\CatQrRegenerated;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use Illuminate\Support\Facades\DB;
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
     * Generate unique alphanumeric backup collar code (unique_code).
     */
    public function generateUniqueCode(): string
    {
        do {
            $code = 'CAT-' . strtoupper(Str::random(6));
        } while (Cat::withTrashed()->where('unique_code', $code)->exists());

        return $code;
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

    /**
     * Issue the initial active QR token for a newly created cat.
     */
    public function issueInitialToken(Cat $cat, ?User $actor = null): CatQrToken
    {
        return CatQrToken::create([
            'cat_id' => $cat->id,
            'token' => $this->generateToken(),
            'status' => 'ACTIVE',
            'issued_by' => $actor?->id,
            'issued_at' => now(),
        ]);
    }

    /**
     * Revoke any active QR token(s) for the cat and issue a fresh ACTIVE token.
     * Preserves cat_id and tag history, records audit log, and dispatches CatQrRegenerated.
     */
    public function regenerateToken(Cat $cat, User $actor, string $reason): CatQrToken
    {
        $newToken = DB::transaction(function () use ($cat, $actor, $reason) {
            CatQrToken::where('cat_id', $cat->id)
                ->where('status', 'ACTIVE')
                ->update([
                    'status' => 'REVOKED',
                    'revoked_at' => now(),
                    'revoked_reason' => $reason,
                    'updated_at' => now(),
                ]);

            $token = CatQrToken::create([
                'cat_id' => $cat->id,
                'token' => $this->generateToken(),
                'status' => 'ACTIVE',
                'issued_by' => $actor->id,
                'issued_at' => now(),
            ]);

            DB::table('audit_logs')->insert([
                'id' => (string) Str::ulid(),
                'actor_id' => $actor->id,
                'action' => 'cat.qr.regenerated',
                'subject_type' => Cat::class,
                'subject_id' => $cat->id,
                'result' => 'SUCCESS',
                'reason' => $reason,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return $token;
        });

        CatQrRegenerated::dispatch($cat, $newToken, $actor->id, $reason);

        return $newToken;
    }
}
