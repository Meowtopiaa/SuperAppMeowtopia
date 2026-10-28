<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Route;

class ModuleServiceProvider extends ServiceProvider
{
    /**
     * Order of module loading to ensure dependencies (e.g., Cat & Core master data)
     * are migrated and registered before consumer modules.
     */
    protected array $moduleOrder = [
        'Core',
        'Cat',
        'FeedingSpot',
        'CatHunter',
        'CatAdoption',
        'IncidentReport',
        'CatIdentification',
    ];

    /**
     * Register any module services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any module migrations and routes.
     */
    public function boot(): void
    {
        $modulesPath = app_path('Modules');

        if (!is_dir($modulesPath)) {
            return;
        }

        // Get all module directory names
        $directories = array_map('basename', glob($modulesPath . '/*', GLOB_ONLYDIR));

        // Sort by defined order, any remaining modules appended
        $sortedModules = array_unique(array_merge(
            array_intersect($this->moduleOrder, $directories),
            $directories
        ));

        foreach ($sortedModules as $module) {
            $moduleDir = $modulesPath . '/' . $module;

            // 1. Load Migrations
            $migrationPath = $moduleDir . '/Database/Migrations';
            if (is_dir($migrationPath)) {
                $this->loadMigrationsFrom($migrationPath);
            }

            // 2. Load API Routes
            $routesFile = $moduleDir . '/routes.php';
            if (file_exists($routesFile)) {
                Route::prefix('api/v1')
                    ->middleware('api')
                    ->group($routesFile);
            }
        }
    }
}
