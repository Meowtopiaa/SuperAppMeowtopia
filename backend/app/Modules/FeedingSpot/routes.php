<?php

use App\Modules\Core\Middleware\RequireIdempotencyKey;
use App\Modules\FeedingSpot\Controllers\AdminFeedingSpotController;
use App\Modules\FeedingSpot\Controllers\FeedingSpotController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Adopt Feeding Spot (Acumalaka) API Routes — PRD v1.1 Section 8.4
|--------------------------------------------------------------------------
| Loaded automatically under prefix '/api/v1' by ModuleServiceProvider.
*/

// Legacy read alias for compatibility
Route::prefix('feeding-spots')->group(function () {
    Route::get('/', [FeedingSpotController::class, 'index']);
    Route::get('/{id}', [FeedingSpotController::class, 'show']);
});

// Official PRD Section 8.4 User Endpoints (/api/v1/feeding/...)
Route::prefix('feeding')->middleware('auth:sanctum')->group(function () {
    // Spots & 14-day Aggregates + last_fed_at (AFS-01, AFS-02, AFS-09)
    Route::get('/spots', [FeedingSpotController::class, 'index']);
    Route::get('/spots/{id}', [FeedingSpotController::class, 'show']);

    // Feeding Session Flow (DRAFT -> Intent -> Finalize) with Idempotency-Key (†)
    Route::post('/activities', [FeedingSpotController::class, 'startSession'])
        ->middleware(RequireIdempotencyKey::class);

    Route::post('/activities/{id}/intent', [FeedingSpotController::class, 'confirmIntent'])
        ->middleware(RequireIdempotencyKey::class);

    Route::post('/activities/{id}/finalize', [FeedingSpotController::class, 'finalizeSession'])
        ->middleware(RequireIdempotencyKey::class);

    // User's Own Feeding History & Reward Status (AFS-08)
    Route::get('/activities/mine', [FeedingSpotController::class, 'myActivities']);

    // 14-Day Coverage Heatmap per Spot & Campus Zone (AFS-09)
    Route::get('/heatmap', [FeedingSpotController::class, 'heatmap']);
});

// Official PRD Section 8.4 Admin Endpoints (/api/v1/admin/feeding/...)
Route::prefix('admin/feeding')->middleware('auth:sanctum')->group(function () {
    // Spot & QR Management (requires 'spot.manage' permission)
    Route::get('/spots/qr-sheet', [AdminFeedingSpotController::class, 'qrSheet']);
    Route::get('/spots', [AdminFeedingSpotController::class, 'indexSpots']);
    Route::post('/spots', [AdminFeedingSpotController::class, 'storeSpot']);
    Route::patch('/spots/{id}', [AdminFeedingSpotController::class, 'updateSpot']);
    Route::put('/spots/{id}', [AdminFeedingSpotController::class, 'updateSpot']);
    Route::delete('/spots/{id}', [AdminFeedingSpotController::class, 'destroySpot']);
    Route::post('/spots/{id}/qr/regenerate', [AdminFeedingSpotController::class, 'regenerateQr']);

    // Review Queue & Reviewer Decision (requires 'feeding.review' permission)
    Route::get('/review-queue', [AdminFeedingSpotController::class, 'reviewQueue']);
    Route::post('/activities/{id}/review', [AdminFeedingSpotController::class, 'reviewActivity']);
    Route::post('/activities/{id}/reverse', [AdminFeedingSpotController::class, 'reverseActivity']);

    // Feeding Module Settings (requires 'spot.manage' permission)
    Route::get('/settings', [AdminFeedingSpotController::class, 'getSettings']);
    Route::put('/settings', [AdminFeedingSpotController::class, 'updateSettings']);
});
