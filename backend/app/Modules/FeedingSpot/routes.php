<?php

use App\Modules\Core\Middleware\RequireIdempotencyKey;
use App\Modules\FeedingSpot\Controllers\AdminFeedingSpotController;
use App\Modules\FeedingSpot\Controllers\FeedingSpotController;
use Illuminate\Support\Facades\Route;

if (empty(config('permission.column_names.role_pivot_key'))) {
    config([
        'permission.column_names.role_pivot_key' => 'role_id',
        'permission.column_names.permission_pivot_key' => 'permission_id',
    ]);
}

/*
|--------------------------------------------------------------------------
| Adopt Feeding Spot (AFS) Routes — /api/v1/feeding/* & /api/v1/admin/feeding/*
|--------------------------------------------------------------------------
*/

Route::prefix('feeding')->group(function () {
    // Public / Read Endpoints (MEOW-6, MEOW-13)
    Route::get('/spots', [FeedingSpotController::class, 'listSpots']);
    Route::get('/spots/{id}', [FeedingSpotController::class, 'showSpot']);
    Route::get('/spots/{id}/photo', [FeedingSpotController::class, 'serveSpotPhoto'])->name('feeding.spots.photo');
    Route::get('/heatmap', [FeedingSpotController::class, 'heatmap']);

    // Public logo asset used by the browser admin panel.
    Route::get('/assets/logo.jpg', [AdminFeedingSpotController::class, 'serveLogoAsset']);

    // Authenticated User Endpoints
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/activities/mine', [FeedingSpotController::class, 'myActivities']);

        // Idempotent Write Endpoints (†) (MEOW-8, MEOW-9, MEOW-11)
        Route::middleware(RequireIdempotencyKey::class)->group(function () {
            Route::post('/activities', [FeedingSpotController::class, 'startSession']);
            Route::post('/activities/{id}/intent', [FeedingSpotController::class, 'confirmIntent']);
            Route::post('/activities/{id}/finalize', [FeedingSpotController::class, 'finalizeSession']);
        });
    });
});

// Signed URL endpoint (10 menit) untuk foto bukti pakan privat (CORE-05, MEOW-22)
Route::get('/admin/feeding/evidence/{mediaId}/file', [AdminFeedingSpotController::class, 'streamEvidenceMedia'])
    ->name('admin.feeding.evidence.file');

// Admin Endpoints — /api/v1/admin/feeding/*
// Memakai permission spot.manage dan feeding.review (bukan pengecekan string role).
// Tidak ada DELETE spot: menonaktifkan spot dilakukan dengan PATCH status menjadi INACTIVE.
Route::prefix('admin/feeding')->middleware('auth:sanctum')->group(function () {
    // Kelola Spot & QR (Permission: spot.manage) (AFS-01, Bagian 8.4, MEOW-7, MEOW-21, MEOW-23)
    Route::middleware('can:spot.manage')->group(function () {
        Route::get('/spots', [AdminFeedingSpotController::class, 'indexSpots']);
        Route::get('/spots/qr-sheet', [AdminFeedingSpotController::class, 'printAllQrSheets'])->name('admin.feeding.spots.qr-sheet.all');
        Route::get('/spots/{id}', [AdminFeedingSpotController::class, 'showSpot']);
        Route::post('/spots', [AdminFeedingSpotController::class, 'storeSpot']);
        Route::patch('/spots/{id}', [AdminFeedingSpotController::class, 'updateSpot']);
        Route::post('/spots/{id}/qr', [AdminFeedingSpotController::class, 'regenerateQr']);
        Route::post('/spots/{id}/qr/regenerate', [AdminFeedingSpotController::class, 'regenerateQr']);
        Route::get('/spots/{id}/qr-sheet', [AdminFeedingSpotController::class, 'printQrSheet'])->name('admin.feeding.spots.qr-sheet');
        Route::get('/spots/{id}/qr-download', [AdminFeedingSpotController::class, 'downloadSpotQr'])->name('admin.feeding.spots.qr-download');
        Route::get('/spots/{id}/cats', [AdminFeedingSpotController::class, 'getSpotCats']);
        Route::post('/spots/{id}/cats', [AdminFeedingSpotController::class, 'attachCats']);
        Route::delete('/spots/{id}/cats/{catId}', [AdminFeedingSpotController::class, 'detachCat']);
    });

    // Antrean Review & Keputusan Reviewer (Permission: feeding.review) (MEOW-12, MEOW-22)
    Route::middleware('can:feeding.review')->group(function () {
        Route::get('/review-queue', [AdminFeedingSpotController::class, 'reviewQueue']);
        Route::get('/reviews/{id}', [AdminFeedingSpotController::class, 'showReviewEvidence'])->name('admin.feeding.reviews.show');
        Route::post('/activities/{id}/review', [AdminFeedingSpotController::class, 'reviewActivity']);
    });
});

// Backward-compatible legacy alias (/api/v1/feeding-spots)
Route::prefix('feeding-spots')->group(function () {
    Route::get('/', [FeedingSpotController::class, 'listSpots']);
    Route::get('/{id}', [FeedingSpotController::class, 'showSpot']);
});

// Console Commands Registration (MEOW-24)
if (app()->runningInConsole()) {
    \Illuminate\Console\Application::starting(function ($artisan) {
        $artisan->resolve(\App\Modules\FeedingSpot\Commands\ExpireFeedingSessionsCommand::class);
        $artisan->resolve(\App\Modules\FeedingSpot\Commands\RefreshFeedingAggregatesCommand::class);
        $artisan->resolve(\App\Modules\FeedingSpot\Commands\CleanupFeedingMediaRetentionCommand::class);
        $artisan->resolve(\App\Modules\FeedingSpot\Commands\SetupLocalFeedingEnvironmentCommand::class);
        $artisan->resolve(\App\Modules\FeedingSpot\Commands\GenerateSampleSpotQrCommand::class);
    });
}

// Views Registration (MEOW-21, MEOW-22)
if (function_exists('view')) {
    view()->addNamespace('feeding-spot', __DIR__ . '/resources/views');
}
