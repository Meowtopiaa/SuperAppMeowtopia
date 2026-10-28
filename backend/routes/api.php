<?php

use Illuminate\Support\Facades\Route;
use App\Support\ApiResponse;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register root API routes for Meowtopia.
| Module-specific routes are automatically loaded via ModuleServiceProvider
| from app/Modules/{ModuleName}/routes.php under the /api/v1 prefix.
|
*/

Route::get('/', function () {
    return ApiResponse::success([
        'app' => 'Meowtopia API',
        'version' => '1.0.0',
        'status' => 'operational',
        'modules' => [
            'Core' => 'Auth & User Management',
            'Cat' => 'Master Data & Collar QR',
            'FeedingSpot' => 'Adopt Feeding Spot (Acumalaka)',
            'CatHunter' => 'Telcat Collection Game (SUPER-SUB)',
            'CatAdoption' => 'Adoption & Rehoming (E-Nigma)',
            'IncidentReport' => 'Emergency Incident Reporting (Optimind)',
            'CatIdentification' => 'Visual & Questionnaire Cat Matcher (Rekans Caps)',
        ]
    ], 'Meowtopia API Gateway is running smoothly');
});
