<?php

use App\Modules\CatAdoption\Controllers\AdoptionApplicationController;
use App\Modules\CatAdoption\Controllers\AdoptionController;
use App\Modules\CatAdoption\Middleware\EnsureVerifiedStudent;
use App\Modules\Core\Middleware\RequireIdempotencyKey;
use Illuminate\Support\Facades\Route;

// PRD 8.6. EnsureVerifiedStudent (ADP-01) berjalan sebelum Idempotency-Key agar 403 tidak tersimpan sebagai cache.
Route::prefix('adoption')->middleware(['auth:sanctum', EnsureVerifiedStudent::class])->group(function () {
    Route::get('cats', [AdoptionController::class, 'cats']);
    Route::get('mine', [AdoptionController::class, 'mine']);

    Route::post('applications', [AdoptionApplicationController::class, 'store'])->middleware(RequireIdempotencyKey::class);
    Route::get('applications/mine', [AdoptionApplicationController::class, 'mine']);
    Route::put('applications/{id}', [AdoptionApplicationController::class, 'update']);
    Route::post('applications/{id}/submit', [AdoptionApplicationController::class, 'submit'])->middleware(RequireIdempotencyKey::class);
});
