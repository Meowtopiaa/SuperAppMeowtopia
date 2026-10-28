<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'message' => 'Welcome to Meowtopia API Backend',
        'api_docs' => '/api/v1',
    ]);
});
