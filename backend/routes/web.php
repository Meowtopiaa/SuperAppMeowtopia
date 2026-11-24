<?php

use Illuminate\Support\Facades\Route;
use App\Modules\FeedingSpot\Controllers\AdminFeedingSpotController;

Route::get('/', function () {
    return response()->json([
        'message' => 'Welcome to Meowtopia API Backend',
        'api_docs' => '/api/v1',
    ]);
});

Route::get('/admin/login', [AdminFeedingSpotController::class, 'adminLogin'])->name('login');
Route::post('/admin/login', [AdminFeedingSpotController::class, 'adminAuthenticate'])->name('admin.login.submit');
Route::get('/admin', fn () => redirect('/admin/feeding'))->middleware('auth')->name('admin.home');

Route::middleware('auth')->prefix('admin/feeding')->group(function () {
    Route::post('/logout', [AdminFeedingSpotController::class, 'adminLogout'])->name('admin.logout');
    Route::get('/', [AdminFeedingSpotController::class, 'adminPreviewPanel']);

    Route::middleware('can:spot.manage')->group(function () {
        Route::post('/spots', [AdminFeedingSpotController::class, 'adminPreviewStoreSpot']);
        Route::post('/spots/{id}/update', [AdminFeedingSpotController::class, 'adminPreviewUpdateSpot']);
        Route::post('/spots/{id}/qr', [AdminFeedingSpotController::class, 'adminPreviewRegenerateQr']);
        Route::post('/spots/{id}/cats', [AdminFeedingSpotController::class, 'adminPreviewAttachCat']);
        Route::post('/spots/{id}/cats/{catId}/detach', [AdminFeedingSpotController::class, 'adminPreviewDetachCat']);
        Route::get('/qr-sheet', [AdminFeedingSpotController::class, 'adminPreviewAllQrSheets']);
        Route::get('/spots/{id}/qr-sheet', [AdminFeedingSpotController::class, 'adminPreviewQrSheet']);
        Route::get('/spots/{id}/qr-download', [AdminFeedingSpotController::class, 'downloadSpotQr']);
    });

    Route::middleware('can:feeding.review')->group(function () {
        Route::get('/reviews/{id}', [AdminFeedingSpotController::class, 'adminPreviewReview']);
        Route::post('/activities/{id}/review', [AdminFeedingSpotController::class, 'adminPreviewSubmitReview']);
    });
});
