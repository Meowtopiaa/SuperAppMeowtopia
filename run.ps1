# ======================================================================
#                     MEOWTOPIA SUPER APP LAUNCHER (PowerShell)
# ======================================================================

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                    MEOWTOPIA SUPER APP LAUNCHER                     " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot
Set-Location $rootDir

# 1. Verifikasi PHP
if (-not (Get-Command php -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] PHP tidak ditemukan di PATH sistem!" -ForegroundColor Red
    Write-Host "Pastikan PHP sudah terinstal dan terdaftar di Environment Variables PATH."
    exit 1
}

# 2. Pastikan file database SQLite & .env backend siap
if (-not (Test-Path "backend\database\database.sqlite")) {
    Write-Host "[INFO] Membuat database/database.sqlite..." -ForegroundColor Yellow
    New-Item -ItemType File -Path "backend\database\database.sqlite" -Force | Out-Null
}

if (-not (Test-Path "backend\.env")) {
    if (Test-Path "backend\.env.example") {
        Write-Host "[INFO] Menyalin backend\.env dari .env.example..." -ForegroundColor Yellow
        Copy-Item "backend\.env.example" "backend\.env"
        Push-Location "backend"
        php artisan key:generate
        Pop-Location
    }
}

# 3. Jalankan migrasi, tabel sessions/cache, dan seeder awal jika belum ada
Write-Host "[INFO] Memastikan skema database dan data awal backend siap..." -ForegroundColor Yellow
Push-Location "backend"
php -r 'require "vendor/autoload.php"; $app = require "bootstrap/app.php"; $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap(); config(["permission.column_names.role_pivot_key" => "role_id", "permission.column_names.permission_pivot_key" => "permission_id"]); Illuminate\Support\Facades\Artisan::call("migrate", ["--force" => true]); if (!Illuminate\Support\Facades\Schema::hasTable("sessions")) { Illuminate\Support\Facades\Schema::create("sessions", function ($t) { $t->string("id")->primary(); $t->string("user_id", 26)->nullable()->index(); $t->string("ip_address", 45)->nullable(); $t->text("user_agent")->nullable(); $t->longText("payload"); $t->integer("last_activity")->index(); }); } if (!Illuminate\Support\Facades\Schema::hasTable("cache")) { Illuminate\Support\Facades\Schema::create("cache", function ($t) { $t->string("key")->primary(); $t->mediumText("value"); $t->integer("expiration"); }); Illuminate\Support\Facades\Schema::create("cache_locks", function ($t) { $t->string("key")->primary(); $t->string("owner"); $t->integer("expiration"); }); } if (Illuminate\Support\Facades\DB::table("users")->count() === 0) { Illuminate\Support\Facades\Artisan::call("db:seed", ["--force" => true]); Illuminate\Support\Facades\Artisan::call("db:seed", ["--class" => "App\\Modules\\FeedingSpot\\Database\\Seeders\\FeedingSettingSeeder", "--force" => true]); }' 2>$null | Out-Null
Pop-Location

# 4. Deteksi Flutter SDK (Sistem PATH atau SDK Lokal di .tools\flutter)
$flutterAvailable = $false
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutterAvailable = $true
} elseif (Test-Path "$rootDir\.tools\flutter\bin\flutter.bat") {
    $env:Path = "$rootDir\.tools\flutter\bin;$env:Path"
    $flutterAvailable = $true
    Write-Host "[INFO] Menggunakan Flutter SDK lokal terisolasi (.tools\flutter)" -ForegroundColor Green
}

Write-Host ""
Write-Host "[1/2] Menjalankan Server Backend (Laravel API di http://127.0.0.1:8000)..." -ForegroundColor Green
Start-Process cmd -ArgumentList "/k title Meowtopia Backend (Port 8000) && color 0A && cd /d `"$rootDir\backend`" && echo URL Backend: http://127.0.0.1:8000 && echo Endpoint API: http://127.0.0.1:8000/api/v1 && echo. && php artisan serve --host=127.0.0.1 --port=8000"

if ($flutterAvailable) {
    if (-not (Test-Path "$rootDir\frontend\web\index.html")) {
        Write-Host "[INFO] Menginisialisasi dukungan Flutter Web lokal..." -ForegroundColor Yellow
        Push-Location "$rootDir\frontend"
        flutter create --platforms=web . 2>$null | Out-Null
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .gitignore, README.md, .metadata, test
        Pop-Location
    }
    Write-Host "[2/2] Menjalankan Aplikasi Frontend (Flutter Web di http://127.0.0.1:3000)..." -ForegroundColor Cyan
    Start-Process cmd -ArgumentList "/k title Meowtopia Frontend (Flutter :3000) && color 0B && cd /d `"$rootDir\frontend`" && echo URL Frontend: http://127.0.0.1:3000 && echo. && set `"PATH=$rootDir\.tools\flutter\bin;%PATH%`" && flutter run -d chrome --web-hostname=127.0.0.1 --web-port=3000"
} else {
    Write-Host ""
    Write-Host "[PERINGATAN] Flutter SDK belum terdeteksi." -ForegroundColor Yellow
    Write-Host "Backend tetap berjalan normal di http://127.0.0.1:8000."
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[SUKSES] Backend dan Frontend Meowtopia sedang berjalan!" -ForegroundColor Green
Write-Host "  - URL Frontend (Flutter Web) : http://127.0.0.1:3000"
Write-Host "  - URL Backend (Laravel)      : http://127.0.0.1:8000"
Write-Host "  - URL REST API v1            : http://127.0.0.1:8000/api/v1"
Write-Host "  - Daftar Spot Pakan (JSON)   : http://127.0.0.1:8000/api/v1/feeding/spots"
Write-Host "======================================================================" -ForegroundColor Green
