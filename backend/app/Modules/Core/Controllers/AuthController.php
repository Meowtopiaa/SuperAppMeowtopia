<?php

namespace App\Modules\Core\Controllers;

use App\Http\Controllers\Controller;
use App\Mail\AuthOtpMail;
use App\Models\User;
use App\Modules\Core\Requests\LoginRequest;
use App\Modules\Core\Requests\RegisterRequest;
use App\Modules\Core\Services\GoogleIdTokenVerifier;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Symfony\Component\Mailer\Exception\TransportExceptionInterface;

class AuthController extends Controller
{
    /**
     * User registration with configured domain mapping and email OTP verification.
     * Role from request is strictly ignored (Fixes FIX-01 & CORE-01).
     */
    public function register(RegisterRequest $request)
    {
        $validated = $request->validated();
        $email = strtolower(trim($validated['email']));

        try {
            [$user, $token] = DB::transaction(function () use ($validated, $email) {
                $user = new User([
                    'name' => $validated['name'],
                    'email' => $email,
                    'password' => Hash::make($validated['password']),
                    'identity_number' => $validated['identity_number'] ?? null,
                    'phone' => $validated['phone'] ?? null,
                    'is_active' => true,
                ]);

                // Explicitly set user_type (protected from mass-assignment)
                $user->user_type = $this->userTypeForEmail($email);
                $user->save();

                // Assign basic 'user' role
                $user->assignRole('user');

                // Initialize Point Balance Cache
                DB::table('point_balances')->updateOrInsert(
                    ['user_id' => $user->id],
                    ['total_points' => 0, 'updated_at' => now()]
                );

                // 3. Generate 6-digit OTP (CORE-02)
                $otp = sprintf('%06d', random_int(100000, 999999));
                DB::table('email_otps')->insert([
                    'id' => (string) Str::ulid(),
                    'user_id' => $user->id,
                    'code_hash' => hash('sha256', $otp),
                    'expires_at' => now()->addMinutes(15),
                    'attempts' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $token = $user->createToken('auth_token')->plainTextToken;
                Mail::to($user->email)->send(new AuthOtpMail($otp, $user->name));

                return [$user, $token];
            });
        } catch (TransportExceptionInterface $exception) {
            report($exception);

            return ApiResponse::error('Email OTP belum dapat dikirim. Coba lagi beberapa saat.', 503, 'SERVICE_UNAVAILABLE');
        }

        $data = [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'user_type' => $user->user_type,
                'email_verified' => false,
            ],
            'token' => $token,
        ];

        return ApiResponse::created(
            $data,
            'Registrasi berhasil. Kode OTP verifikasi telah dikirim ke email Anda.'
        );
    }

    /** Request an email OTP for an existing account without revealing whether it exists. */
    public function requestEmailOtp(Request $request)
    {
        $validated = $request->validate(['email' => ['required', 'email', 'max:255']]);
        $email = strtolower(trim($validated['email']));
        $user = User::where('email', $email)->first();

        if (!$user || !$user->is_active) {
            return ApiResponse::success(['sent' => true], 'Jika akun terdaftar, kode masuk akan dikirim ke email tersebut.');
        }

        $recentCount = DB::table('email_otps')
            ->where('user_id', $user->id)
            ->where('created_at', '>', now()->subHour())
            ->count();
        if ($recentCount >= 3) {
            return ApiResponse::error('Batas permintaan OTP tercapai. Coba lagi dalam 1 jam.', 429, 'RATE_LIMITED');
        }

        $otp = sprintf('%06d', random_int(100000, 999999));
        $otpId = (string) Str::ulid();
        DB::table('email_otps')->insert([
            'id' => $otpId,
            'user_id' => $user->id,
            'code_hash' => hash('sha256', $otp),
            'expires_at' => now()->addMinutes(15),
            'attempts' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::to($user->email)->send(new AuthOtpMail($otp, $user->name));
        } catch (\Throwable $exception) {
            DB::table('email_otps')->where('id', $otpId)->delete();
            report($exception);

            return ApiResponse::error('Email OTP belum dapat dikirim. Coba lagi beberapa saat.', 503, 'SERVICE_UNAVAILABLE');
        }

        return ApiResponse::success(['sent' => true], 'Jika akun terdaftar, kode masuk akan dikirim ke email tersebut.');
    }

    /** Complete passwordless sign-in after verifying the email OTP. */
    public function loginWithEmailOtp(Request $request)
    {
        $validated = $request->validate([
            'email' => ['required', 'email', 'max:255'],
            'otp' => ['required', 'string', 'size:6', 'regex:/^[0-9]{6}$/'],
        ]);
        $user = User::where('email', strtolower(trim($validated['email'])))->first();
        $otpRecord = $user ? DB::table('email_otps')
            ->where('user_id', $user->id)
            ->latest('created_at')
            ->orderByDesc('id')
            ->first() : null;

        if (!$otpRecord || $otpRecord->used_at || $otpRecord->attempts >= 5
            || now()->gte($otpRecord->expires_at)) {
            return ApiResponse::error('Kode OTP salah, kedaluwarsa, atau tidak dapat digunakan.', 422, 'VALIDATION_ERROR');
        }
        if (!hash_equals($otpRecord->code_hash, hash('sha256', $validated['otp']))) {
            DB::table('email_otps')->where('id', $otpRecord->id)->whereNull('used_at')->increment('attempts');

            return ApiResponse::error('Kode OTP salah, kedaluwarsa, atau tidak dapat digunakan.', 422, 'VALIDATION_ERROR');
        }
        if (!$user->is_active) {
            return ApiResponse::error('Akun Anda dinonaktifkan. Hubungi administrator.', 403, 'FORBIDDEN');
        }

        return DB::transaction(function () use ($otpRecord, $user) {
            $claimed = DB::table('email_otps')->where('id', $otpRecord->id)
                ->whereNull('used_at')
                ->where('expires_at', '>', now())
                ->where('attempts', '<', 5)
                ->update(['used_at' => now()]);
            if (!$claimed) {
                return ApiResponse::error('Kode OTP salah, kedaluwarsa, atau tidak dapat digunakan.', 422, 'VALIDATION_ERROR');
            }

            $user->email_verified_at ??= now();
            $user->last_login_at = now();
            $user->save();

            return ApiResponse::success($this->authenticatedUserData($user), 'Login berhasil.');
        });
    }

    /** Exchange a Google ID token for a Meowtopia Sanctum token. */
    public function loginWithGoogle(Request $request, GoogleIdTokenVerifier $verifier)
    {
        $validated = $request->validate(['id_token' => ['required', 'string', 'max:8192']]);
        try {
            $claims = $verifier->verify($validated['id_token']);
        } catch (\Throwable $exception) {
            report($exception);

            return ApiResponse::error('Layanan Google belum dapat dijangkau. Coba lagi.', 503, 'SERVICE_UNAVAILABLE');
        }
        if (!$claims) {
            return ApiResponse::error('Token Google tidak valid atau belum dikonfigurasi.', 401, 'FORBIDDEN');
        }

        return DB::transaction(function () use ($claims) {
            $email = strtolower(trim($claims['email']));
            $googleSub = $claims['sub'];
            $googleOwnsEmail = Str::afterLast($email, '@') === 'gmail.com' || !empty($claims['hd']);
            $user = User::where('google_sub', $googleSub)->lockForUpdate()->first();

            if (!$user) {
                if (!$googleOwnsEmail) {
                    return ApiResponse::error('Gunakan OTP untuk masuk dengan alamat email ini.', 422, 'EMAIL_NOT_VERIFIED');
                }

                $user = User::where('email', $email)->lockForUpdate()->first();
                if ($user && $user->google_sub && !hash_equals($user->google_sub, $googleSub)) {
                    return ApiResponse::error('Email ini sudah terhubung ke akun Google lain.', 409, 'CONFLICT');
                }
                if ($user && !$user->is_active) {
                    return ApiResponse::error('Akun Anda dinonaktifkan. Hubungi administrator.', 403, 'FORBIDDEN');
                }
                if (!$user) {
                    $user = new User([
                        'name' => $claims['name'] ?? Str::before($email, '@'),
                        'email' => $email,
                        'password' => Hash::make(Str::random(64)),
                        'is_active' => true,
                    ]);
                    $user->user_type = $this->userTypeForEmail($email);
                    $user->google_sub = $googleSub;
                    $user->email_verified_at = now();
                    $user->save();
                    $user->assignRole('user');
                    DB::table('point_balances')->insertOrIgnore([
                        'user_id' => $user->id,
                        'total_points' => 0,
                        'updated_at' => now(),
                    ]);
                } else {
                    $user->google_sub = $googleSub;
                }
            }

            if (!$user->is_active) {
                return ApiResponse::error('Akun Anda dinonaktifkan. Hubungi administrator.', 403, 'FORBIDDEN');
            }
            if ($googleOwnsEmail && strcasecmp($user->email, $email) === 0) {
                $user->email_verified_at ??= now();
            }
            $user->last_login_at = now();
            $user->save();

            return ApiResponse::success($this->authenticatedUserData($user), 'Login Google berhasil.');
        });
    }

    /**
     * Verify email via 6-digit OTP code (CORE-02).
     */
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'otp' => ['required', 'string', 'size:6'],
        ]);

        $user = $request->user();
        if (!$user) {
            return ApiResponse::error('Autentikasi diperlukan.', 401, 'FORBIDDEN');
        }

        $codeHash = hash('sha256', trim($request->input('otp')));

        $otpRecord = DB::table('email_otps')
            ->where('user_id', $user->id)
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->where('attempts', '<', 5)
            ->latest('created_at')
            ->first();

        if (!$otpRecord || !hash_equals($otpRecord->code_hash, $codeHash)) {
            if ($otpRecord) {
                DB::table('email_otps')->where('id', $otpRecord->id)->increment('attempts');
            }
            return ApiResponse::error(
                'Kode OTP salah, kedaluwarsa, atau tidak dapat digunakan.',
                422,
                'VALIDATION_ERROR'
            );
        }

        // Mark OTP as used
        DB::table('email_otps')
            ->where('id', $otpRecord->id)
            ->update(['used_at' => now()]);

        // Mark user as verified
        $user->email_verified_at = now();
        $user->save();

        return ApiResponse::success([
            'email_verified' => true,
            'verified_at' => $user->email_verified_at->toIso8601String(),
        ], 'Email berhasil diverifikasi.');
    }

    /**
     * Resend 6-digit email OTP (CORE-02).
     */
    public function resendOtp(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return ApiResponse::error('Autentikasi diperlukan.', 401, 'FORBIDDEN');
        }

        // Rate limit: max 3 per hour
        $recentCount = DB::table('email_otps')
            ->where('user_id', $user->id)
            ->where('created_at', '>', now()->subHour())
            ->count();

        if ($recentCount >= 3) {
            return ApiResponse::error(
                'Batas permintaan OTP tercapai. Coba lagi dalam 1 jam.',
                429,
                'RATE_LIMITED'
            );
        }

        $otp = sprintf('%06d', random_int(100000, 999999));
        $otpId = (string) Str::ulid();
        DB::table('email_otps')->insert([
            'id' => $otpId,
            'user_id' => $user->id,
            'code_hash' => hash('sha256', $otp),
            'expires_at' => now()->addMinutes(15),
            'attempts' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::to($user->email)->send(new AuthOtpMail($otp, $user->name));
        } catch (\Throwable $exception) {
            DB::table('email_otps')->where('id', $otpId)->delete();
            report($exception);

            return ApiResponse::error('Email OTP belum dapat dikirim. Coba lagi beberapa saat.', 503, 'SERVICE_UNAVAILABLE');
        }

        return ApiResponse::success(['resent' => true], 'Kode OTP baru telah dikirimkan ke email Anda.');
    }

    /**
     * User login with Sanctum token.
     */
    public function login(LoginRequest $request)
    {
        $validated = $request->validated();
        $user = User::where('email', strtolower(trim($validated['email'])))->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return ApiResponse::error(
                'Email atau password yang Anda masukkan salah.',
                401,
                'FORBIDDEN'
            );
        }

        if (!$user->is_active) {
            return ApiResponse::error(
                'Akun Anda dinonaktifkan. Hubungi administrator.',
                403,
                'FORBIDDEN'
            );
        }

        $user->last_login_at = now();
        $user->save();

        $token = $user->createToken('auth_token')->plainTextToken;

        return ApiResponse::success($this->authenticatedUserData($user, $token), 'Login berhasil.');
    }

    /**
     * User logout - Revokes active Sanctum token (CORE-01).
     */
    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return ApiResponse::success(null, 'Berhasil logout.');
    }

    /**
     * Current authenticated user profile (GET /api/v1/me).
     */
    public function me(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return ApiResponse::error('Unauthenticated', 401, 'FORBIDDEN');
        }

        $balance = DB::table('point_balances')->where('user_id', $user->id)->value('total_points') ?? 0;

        return ApiResponse::success([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'user_type' => $user->user_type,
            'identity_number' => $user->identity_number,
            'phone' => $user->phone,
            'email_verified' => $user->email_verified_at !== null,
            'points_balance' => (int) $balance,
            'roles' => $user->getRoleNames(),
            'permissions' => $user->getAllPermissions()->pluck('name'),
        ], 'Profil berhasil diambil.');
    }

    private function userTypeForEmail(string $email): string
    {
        $domain = strtolower(substr(strrchr($email, '@'), 1));
        $mapping = [];
        foreach (explode(',', (string) env('EMAIL_DOMAIN_TYPES', '')) as $entry) {
            [$mappedDomain, $type] = array_pad(explode(':', trim($entry), 2), 2, null);
            if ($mappedDomain && $type) {
                $mapping[strtolower($mappedDomain)] = strtoupper($type);
            }
        }

        return $mapping[$domain] ?? 'UMUM';
    }

    private function authenticatedUserData(User $user, ?string $token = null): array
    {
        return [
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'user_type' => $user->user_type,
                'email_verified' => $user->email_verified_at !== null,
                'roles' => $user->getRoleNames(),
                'permissions' => $user->getAllPermissions()->pluck('name'),
            ],
            'token' => $token ?? $user->createToken('auth_token')->plainTextToken,
        ];
    }
}
