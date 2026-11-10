@echo off
chcp 65001 >nul
title Meowtopia - Launcher

echo ======================================================================
echo                     MEOWTOPIA SUPER APP LAUNCHER                     
echo ======================================================================
echo.

set "ROOT_DIR=%~dp0"
cd /d "%ROOT_DIR%"

:: 1. Verifikasi PHP
where php >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] PHP tidak ditemukan di PATH sistem!
    echo Pastikan PHP sudah terinstal dan terdaftar di Environment Variables PATH.
    pause
    exit /b 1
)

:: 2. Pastikan file database SQLite & .env backend siap
if not exist "backend\database\database.sqlite" (
    echo [INFO] Membuat database/database.sqlite...
    type nul > "backend\database\database.sqlite"
)

if not exist "backend\.env" (
    if exist "backend\.env.example" (
        echo [INFO] Menyalin backend\.env dari .env.example...
        copy "backend\.env.example" "backend\.env" >nul
        cd /d "%ROOT_DIR%backend"
        php artisan key:generate
        cd /d "%ROOT_DIR%"
    )
)

:: 3. Jalankan migrasi backend jika diperlukan
echo [INFO] Memeriksa migrasi backend database...
cd /d "%ROOT_DIR%backend"
php artisan migrate --graceful >nul 2>&1
cd /d "%ROOT_DIR%"

echo.
echo [1/2] Menjalankan Server Backend (Laravel API di http://127.0.0.1:8000)...
start "Meowtopia - Backend (Laravel API :8000)" cmd /k "cd /d "%ROOT_DIR%backend" && title Meowtopia Backend (Port 8000) && color 0A && echo ======================================== && echo       MEOWTOPIA BACKEND (LARAVEL)       && echo ======================================== && echo URL: http://127.0.0.1:8000 && echo API: http://127.0.0.1:8000/api/v1 && echo. && php artisan serve --host=127.0.0.1 --port=8000"

:: 4. Verifikasi ketersediaan Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo [PERINGATAN] Perintah 'flutter' belum terdeteksi di PATH sistem Anda!
    echo Backend (Laravel API) tetap berjalan normal di http://127.0.0.1:8000.
    echo.
    echo Solusi:
    echo 1. Jika Flutter SDK sudah diunduh, tambahkan folder 'flutter\bin' ke Environment Variables PATH.
    echo 2. Jika belum terinstal, pasang melalui https://docs.flutter.dev/get-started/install/windows
    echo    atau jalankan: winget install Google.Flutter
    echo.
) else (
    echo [2/2] Menjalankan Aplikasi Frontend (Flutter)...
    start "Meowtopia - Frontend (Flutter)" cmd /k "cd /d "%ROOT_DIR%frontend" && title Meowtopia Frontend (Flutter) && color 0B && echo ======================================== && echo       MEOWTOPIA FRONTEND (FLUTTER)       && echo ======================================== && echo Petunjuk: && echo   - Tekan 'r' untuk Hot Reload && echo   - Tekan 'R' untuk Hot Restart && echo   - Tekan 'q' untuk keluar && echo. && flutter run"
)

echo.
echo ======================================================================
echo [INFO] Status Layanan:
echo   - Backend API : http://127.0.0.1:8000/api/v1
echo   - Admin Panel : http://127.0.0.1:8000/admin
echo.
echo Anda dapat menutup jendela launcher ini kapan saja.
echo ======================================================================
echo.
pause
