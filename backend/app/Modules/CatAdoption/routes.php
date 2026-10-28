<?php

use Illuminate\Support\Facades\Route;
use App\Modules\CatAdoption\Controllers\AdoptionController;

Route::prefix('adoption')->group(function () {
    Route::get('catalog', [AdoptionController::class, 'readyCats']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('apply', [AdoptionController::class, 'apply']);
        Route::get('my-cats', [AdoptionController::class, 'myCats']);
        Route::post('my-cats/{id}/followup', [AdoptionController::class, 'submitFollowup']);
    });
});
