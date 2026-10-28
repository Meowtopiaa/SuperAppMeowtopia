<?php

use Illuminate\Support\Facades\Route;
use App\Modules\IncidentReport\Controllers\IncidentReportController;

Route::prefix('incidents')->group(function () {
    Route::get('/', [IncidentReportController::class, 'index']);
    Route::get('/{id}', [IncidentReportController::class, 'show']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/', [IncidentReportController::class, 'store']);
        Route::patch('/{id}/status', [IncidentReportController::class, 'updateStatus']);
    });
});
