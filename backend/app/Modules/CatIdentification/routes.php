<?php

use Illuminate\Support\Facades\Route;
use App\Modules\CatIdentification\Controllers\IdentificationController;

Route::prefix('identification')->group(function () {
    Route::get('questions', [IdentificationController::class, 'getQuestions']);
    Route::post('identify', [IdentificationController::class, 'identify']);
});
