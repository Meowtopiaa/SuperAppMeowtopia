<?php

use Illuminate\Support\Facades\Route;
use App\Modules\FeedingSpot\Controllers\FeedingSpotController;

Route::prefix('feeding-spots')->group(function () {
    Route::get('/', [FeedingSpotController::class, 'index']);
    Route::get('/{id}', [FeedingSpotController::class, 'show']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/record', [FeedingSpotController::class, 'recordFeeding']);
    });
});
