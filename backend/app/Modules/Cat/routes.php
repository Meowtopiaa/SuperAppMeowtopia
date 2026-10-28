<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Cat\Controllers\CatController;

Route::prefix('cats')->group(function () {
    Route::get('/', [CatController::class, 'index']);
    Route::get('/qr/{token}', [CatController::class, 'findByQr']);
    Route::get('/{id}', [CatController::class, 'show']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/', [CatController::class, 'store']);
        Route::put('/{id}', [CatController::class, 'update']);
    });
});
