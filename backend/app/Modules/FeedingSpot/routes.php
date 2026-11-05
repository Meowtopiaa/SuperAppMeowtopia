<?php

use App\Modules\Core\Middleware\RequireIdempotencyKey;
use App\Modules\FeedingSpot\Controllers\AdminFeedingSpotController;
use App\Modules\FeedingSpot\Controllers\FeedingSpotController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Adopt Feeding Spot (AFS) Routes — /api/v1/feeding/* & /api/v1/admin/feeding/*
|--------------------------------------------------------------------------
*/

Route::prefix('feeding')->group(function () {
    // Public / Read Endpoints (MEOW-6)
    Route::get('/spots', [FeedingSpotController::class, 'listSpots']);
    Route::get('/spots/{id}', [FeedingSpotController::class, 'showSpot']);

    // Authenticated User Endpoints
    Route::middleware('auth:sanctum')->group(function () {
        // Idempotent Write Endpoints (†) (MEOW-8, MEOW-9, MEOW-11)
        Route::middleware(RequireIdempotencyKey::class)->group(function () {
            Route::post('/activities', [FeedingSpotController::class, 'startSession']);
            Route::post('/activities/{id}/intent', [FeedingSpotController::class, 'confirmIntent']);
            Route::post('/activities/{id}/finalize', [FeedingSpotController::class, 'finalizeSession']);
        });
    });
});

// Admin Endpoints — /api/v1/admin/feeding/*
Route::prefix('admin/feeding')->middleware('auth:sanctum')->group(function () {
    // Kelola Spot & QR (Permission: spot.manage) (MEOW-7)
    Route::middleware('can:spot.manage')->group(function () {
        Route::post('/spots', [AdminFeedingSpotController::class, 'storeSpot']);
        Route::patch('/spots/{id}', [AdminFeedingSpotController::class, 'updateSpot']);
        Route::post('/spots/{id}/qr', [AdminFeedingSpotController::class, 'regenerateQr']);
    });

    // Antrean Review & Keputusan Reviewer (Permission: feeding.review) (MEOW-12)
    Route::middleware('can:feeding.review')->group(function () {
        Route::get('/review-queue', [AdminFeedingSpotController::class, 'reviewQueue']);
        Route::post('/activities/{id}/review', [AdminFeedingSpotController::class, 'reviewActivity']);
    });
});

// Backward-compatible legacy alias (/api/v1/feeding-spots)
Route::prefix('feeding-spots')->group(function () {
    Route::get('/', [FeedingSpotController::class, 'listSpots']);
    Route::get('/{id}', [FeedingSpotController::class, 'showSpot']);
});
