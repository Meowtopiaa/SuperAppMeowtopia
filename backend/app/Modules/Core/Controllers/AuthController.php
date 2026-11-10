<?php

namespace App\Modules\Core\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Core\Requests\LoginRequest;
use App\Modules\Core\Requests\RegisterRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * User registration with automated campus user_type mapping & OTP generation.
     * Role from request is strictly ignored (Fixes FIX-01 & CORE-01).
     */
    public function register(RegisterRequest $request)
    {
        $validated = $request->validated();
        $email = strtolower(trim($validated['email']));

        // 1. Determine user_type from email domain
        $parts = explode('@', $email);
        $domain = end($parts);
        $userType = 'MAHASISWA';
        if (str_contains($domain, 'student')) {
            $userType = 'MAHASISWA';
        } elseif (str_contains($domain, 'telkomuniversity')) {
            $userType = 'DOSEN';
        }

        // 2. Create User with ULID and baseline role
        $userId = (string) Str::ulid();
        $user = User::create([
            'id' => $userId,
            'name' => $validated['name'],
            'email' => $email,
            'password' => Hash::make($validated['password']),
            'identity_number' => $validated['identity_number'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'is_active' => true,
        ]);

        // Explicitly set user_type (protected from mass-assignment)
        $user->user_type = $userType;
        $user->save();

        // Assign basic 'user' role
        $user->assignRole('user');

        // Initialize Point Balance Cache
        DB::table('point_balances')->updateOrInsert(
            ['user_id' => $user->id],
            ['total_points' => 0, 'updated_at' => now()]
        );

        // 3. Generate 6-digit OTP (CORE-02)
        $otp = sprintf('%06d', mt_rand(100000, 999999));
        DB::table('email_otps')->insert([
            'id' => (string) Str::ulid(),
            'user_id' => $user->id,
            'code_hash' => hash('sha256', $otp),
            'expires_at' => now()->addMinutes(15),
            'attempts' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Issue temporary token for verification flow
        $token = $user->createToken('auth_token')->plainTextToken;

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

        // In dev or testing, expose OTP in response for testing convenience
        if (app()->environment('local', 'testing')) {
            $data['dev_otp'] = $otp;
        }

        return ApiResponse::created(
            $data,
            'Registrasi berhasil. Kode OTP verifikasi telah dikirim ke email Anda.'
        );
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
            ->where('used_at', null)
            ->where('expires_at', '>', now())
            ->latest('created_at')
            ->first();

        if (!$otpRecord || $otpRecord->code_hash !== $codeHash) {
            return ApiResponse::error(
                'Kode OTP salah atau telah kedaluwarsa.',
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

        $otp = sprintf('%06d', mt_rand(100000, 999999));
        DB::table('email_otps')->insert([
            'id' => (string) Str::ulid(),
            'user_id' => $user->id,
            'code_hash' => hash('sha256', $otp),
            'expires_at' => now()->addMinutes(15),
            'attempts' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $data = ['resent' => true];
        if (app()->environment('local', 'testing')) {
            $data['dev_otp'] = $otp;
        }

        return ApiResponse::success($data, 'Kode OTP baru telah dikirimkan ke email Anda.');
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

        return ApiResponse::success([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'user_type' => $user->user_type,
                'email_verified' => $user->email_verified_at !== null,
                'roles' => $user->getRoleNames(),
                'permissions' => $user->getAllPermissions()->pluck('name'),
            ],
            'token' => $token,
        ], 'Login berhasil.');
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
}
