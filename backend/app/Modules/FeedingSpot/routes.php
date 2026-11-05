<?php

use App\Modules\FeedingSpot\Controllers\FeedingSpotController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Adopt Feeding Spot (AFS) Routes — /api/v1/feeding/*
|--------------------------------------------------------------------------
*/

Route::prefix('feeding')->group(function () {
    // Public / Read Endpoints (MEOW-6)
    Route::get('/spots', [FeedingSpotController::class, 'listSpots']);
    Route::get('/spots/{id}', [FeedingSpotController::class, 'showSpot']);
});

// Backward-compatible legacy alias (/api/v1/feeding-spots)
Route::prefix('feeding-spots')->group(function () {
    Route::get('/', [FeedingSpotController::class, 'listSpots']);
    Route::get('/{id}', [FeedingSpotController::class, 'showSpot']);
});
