<?php

namespace App\Modules\Core\Contracts;

use App\Models\User;

interface AuthProviderInterface
{
    /**
     * Authenticate credentials and return token
     */
    public function attempt(array $credentials): array;

    /**
     * Register a new user and dispatch OTP
     */
    public function register(array $data): array;

    /**
     * Verify OTP code for user email
     */
    public function verifyOtp(User $user, string $otp): bool;
}

