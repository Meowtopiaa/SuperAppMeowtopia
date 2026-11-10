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

# 3. Jalankan migrasi backend jika diperlukan
Write-Host "[INFO] Memeriksa migrasi backend database..." -ForegroundColor Yellow
Push-Location "backend"
php artisan migrate --graceful 2>$null | Out-Null
Pop-Location

Write-Host ""
Write-Host "[1/2] Menjalankan Server Backend (Laravel API di http://127.0.0.1:8000)..." -ForegroundColor Green
Start-Process cmd -ArgumentList "/k title Meowtopia Backend (Port 8000) && color 0A && cd /d `"$rootDir\backend`" && php artisan serve --host=127.0.0.1 --port=8000"

# 4. Verifikasi Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "[PERINGATAN] Perintah 'flutter' belum terdeteksi di PATH sistem Anda!" -ForegroundColor Yellow
    Write-Host "Backend (Laravel API) tetap berjalan normal di http://127.0.0.1:8000."
    Write-Host ""
    Write-Host "Solusi:" -ForegroundColor Cyan
    Write-Host "1. Jika Flutter SDK sudah ada di komputer Anda, tambahkan folder 'flutter\bin' ke Environment Variables PATH."
    Write-Host "2. Jika belum terinstal, pasang melalui: winget install Google.Flutter"
    Write-Host "   atau unduh dari https://docs.flutter.dev/get-started/install/windows"
    Write-Host ""
} else {
    Write-Host "[2/2] Menjalankan Aplikasi Frontend (Flutter)..." -ForegroundColor Cyan
    Start-Process cmd -ArgumentList "/k title Meowtopia Frontend (Flutter) && color 0B && cd /d `"$rootDir\frontend`" && flutter run"
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "[INFO] Status Layanan:" -ForegroundColor Green
Write-Host "  - Backend API : http://127.0.0.1:8000/api/v1"
Write-Host "  - Admin Panel : http://127.0.0.1:8000/admin"
Write-Host "======================================================================" -ForegroundColor Green
