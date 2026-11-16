<?php

use App\Modules\CatAdoption\Controllers\AdoptionApplicationController;
use App\Modules\CatAdoption\Controllers\AdoptionController;
use App\Modules\Core\Middleware\RequireIdempotencyKey;
use Illuminate\Support\Facades\Route;

// PRD 8.6. Pengecekan mahasiswa terverifikasi (NOT_STUDENT) menyusul di EN-13.
Route::prefix('adoption')->middleware('auth:sanctum')->group(function () {
    Route::get('cats', [AdoptionController::class, 'cats']);
    Route::get('mine', [AdoptionController::class, 'mine']);

    Route::post('applications', [AdoptionApplicationController::class, 'store'])->middleware(RequireIdempotencyKey::class);
    Route::get('applications/mine', [AdoptionApplicationController::class, 'mine']);
});
