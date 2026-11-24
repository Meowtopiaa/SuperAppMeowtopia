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

# 3. Jalankan setup database lokal & data demo awal
Write-Host "[INFO] Memastikan skema database dan data demo backend siap..." -ForegroundColor Yellow
Push-Location "backend"
php artisan feeding:setup-local 2>$null | Out-Null
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
Start-Process cmd -ArgumentList "/k title Meowtopia Backend (Port 8000) && color 0A && cd /d `"$rootDir\backend`" && echo Panel Admin AFS : http://127.0.0.1:8000/api/v1/feeding/admin-preview && echo Endpoint API    : http://127.0.0.1:8000/api/v1/feeding/spots && echo. && php artisan serve --host=127.0.0.1 --port=8000"

if ($flutterAvailable) {
    if (-not (Test-Path "$rootDir\frontend\web\index.html")) {
        Write-Host "[INFO] Menginisialisasi dukungan Flutter Web lokal..." -ForegroundColor Yellow
        Push-Location "$rootDir\frontend"
        flutter create --platforms=web . 2>$null | Out-Null
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue .gitignore, README.md, .metadata, test
        Pop-Location
    }
    Write-Host "[2/2] Menjalankan Aplikasi Frontend (Flutter Web di http://127.0.0.1:3000)..." -ForegroundColor Cyan
    Start-Process cmd -ArgumentList "/k title Meowtopia Frontend (Flutter :3000) && color 0B && cd /d `"$rootDir\frontend`" && echo URL Frontend: http://127.0.0.1:3000 && echo. && set `"PATH=$rootDir\.tools\flutter\bin;%PATH%`" && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3000"
} else {
    Write-Host ""
    Write-Host "[PERINGATAN] Flutter SDK belum terdeteksi." -ForegroundColor Yellow
    Write-Host "Backend tetap berjalan normal di http://127.0.0.1:8000."
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[SUKSES] Backend dan Frontend Meowtopia sedang berjalan!" -ForegroundColor Green
Write-Host "  1. Aplikasi Flutter (Frontend) : http://127.0.0.1:3000"
Write-Host "  2. Panel Admin Review (MEOW-22): http://127.0.0.1:8000/api/v1/feeding/admin-preview"
Write-Host "  3. Endpoint JSON Spot Pakan    : http://127.0.0.1:8000/api/v1/feeding/spots"
Write-Host ""
Write-Host "Akun Demo Seeder:"
Write-Host "  - Mahasiswa  : mahasiswa@student.telkomuniversity.ac.id (password: password)"
Write-Host "  - Spot Admin : spotadmin@telkomuniversity.ac.id         (password: password)"
Write-Host "======================================================================" -ForegroundColor Green
