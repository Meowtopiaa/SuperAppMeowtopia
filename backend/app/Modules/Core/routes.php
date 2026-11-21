<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Core\Controllers\AuthController;
use App\Modules\Core\Controllers\CoreController;
use App\Modules\Core\Middleware\RequireIdempotencyKey;

// Public Auth Endpoints
Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:10,1');
    Route::post('email/otp/request', [AuthController::class, 'requestEmailOtp'])->middleware('throttle:5,1');
    Route::post('email/otp/login', [AuthController::class, 'loginWithEmailOtp'])->middleware('throttle:10,1');
    Route::post('google', [AuthController::class, 'loginWithGoogle'])->middleware('throttle:10,1');

    // Authenticated Auth Endpoints
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('email/otp/verify', [AuthController::class, 'verifyOtp']);
        Route::post('email/otp/resend', [AuthController::class, 'resendOtp']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

// Authenticated Core Endpoints
Route::middleware('auth:sanctum')->group(function () {
    // Current User Profile
    Route::get('me', [AuthController::class, 'me']);

    // Central Scan Resolver
    Route::get('scan/resolve', [CoreController::class, 'resolveScan']);

    // Media Upload & Signed URL Access
    Route::post('media', [CoreController::class, 'uploadMedia'])->middleware(RequireIdempotencyKey::class);
    Route::get('media/{id}/url', [CoreController::class, 'getMediaUrl']);

    // Points & Ledger
    Route::get('points/me', [CoreController::class, 'myPoints']);
});
