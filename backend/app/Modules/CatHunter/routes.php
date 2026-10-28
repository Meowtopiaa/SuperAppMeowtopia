<?php

use Illuminate\Support\Facades\Route;
use App\Modules\CatHunter\Controllers\CatHunterController;

Route::prefix('cat-hunter')->group(function () {
    Route::get('leaderboard', [CatHunterController::class, 'leaderboard']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('encounter', [CatHunterController::class, 'startEncounter']);
        Route::get('my-dex', [CatHunterController::class, 'myDex']);
    });
});
