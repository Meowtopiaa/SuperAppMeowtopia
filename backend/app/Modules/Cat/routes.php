<?php

use Illuminate\Support\Facades\Route;
use App\Modules\Cat\Controllers\AdminCatController;
use App\Modules\Cat\Controllers\CatController;
use App\Modules\Core\Middleware\RequireIdempotencyKey;

// Public / Authenticated Cat Endpoints (PRD 8.3)
Route::prefix('cats')->middleware('auth:sanctum')->group(function () {
    Route::get('/', [CatController::class, 'index']);
    Route::get('/by-code/{unique_code}', [CatController::class, 'findByCode']);
    Route::get('/{id}', [CatController::class, 'show']);
    Route::get('/{id}/actions', [CatController::class, 'actions']);
    Route::post('/{id}/sightings', [CatController::class, 'recordSighting'])
        ->middleware(RequireIdempotencyKey::class);
});

// Admin / Curator Cat Endpoints (PRD 8.3, permissions enforced via CatPolicy)
Route::prefix('admin/cats')->middleware('auth:sanctum')->group(function () {
    Route::post('/', [AdminCatController::class, 'store']);
    Route::post('/import', [AdminCatController::class, 'import']);
    Route::get('/qr-sheet', [AdminCatController::class, 'qrSheet']);
    Route::patch('/{id}', [AdminCatController::class, 'update']);
    Route::post('/{id}/qr/regenerate', [AdminCatController::class, 'regenerateQr']);
    Route::put('/{id}/traits', [AdminCatController::class, 'updateTraits']);
    Route::post('/{id}/merge', [AdminCatController::class, 'merge']);
});
