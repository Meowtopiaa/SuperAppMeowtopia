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

:: 3. Jalankan setup database lokal & data demo awal
echo [INFO] Memastikan skema database dan data demo backend siap...
cd /d "%ROOT_DIR%backend"
php artisan feeding:setup-local >nul 2>&1
cd /d "%ROOT_DIR%"

:: 4. Deteksi Flutter SDK (Sistem PATH atau SDK Lokal di .tools\flutter)
set "FLUTTER_AVAILABLE=0"
where flutter >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "FLUTTER_AVAILABLE=1"
) else (
    if exist "%ROOT_DIR%.tools\flutter\bin\flutter.bat" (
        set "PATH=%ROOT_DIR%.tools\flutter\bin;%PATH%"
        set "FLUTTER_AVAILABLE=1"
        echo [INFO] Menggunakan Flutter SDK lokal terisolasi (.tools\flutter)
    )
)

echo.
echo [1/2] Menjalankan Server Backend (Laravel API di http://127.0.0.1:8000)...
start "Meowtopia - Backend (Laravel API :8000)" cmd /k "cd /d "%ROOT_DIR%backend" && title Meowtopia Backend (Port 8000) && color 0A && echo ======================================== && echo       MEOWTOPIA BACKEND (LARAVEL)       && echo ======================================== && echo Panel Admin AFS : http://127.0.0.1:8000/api/v1/feeding/admin-preview && echo Endpoint API    : http://127.0.0.1:8000/api/v1/feeding/spots && echo. && php artisan serve --host=127.0.0.1 --port=8000"

if "%FLUTTER_AVAILABLE%"=="1" (
    if not exist "%ROOT_DIR%frontend\web\index.html" (
        echo [INFO] Menginisialisasi dukungan Flutter Web lokal...
        cd /d "%ROOT_DIR%frontend"
        call flutter create --platforms=web . >nul 2>&1
        if exist ".gitignore" del /f /q ".gitignore" >nul 2>&1
        if exist "README.md" del /f /q "README.md" >nul 2>&1
        if exist ".metadata" del /f /q ".metadata" >nul 2>&1
        if exist "test\widget_test.dart" rmdir /s /q "test" >nul 2>&1
        cd /d "%ROOT_DIR%"
    )
    echo [2/2] Menjalankan Aplikasi Frontend (Flutter Web di http://127.0.0.1:3000)...
    start "Meowtopia - Frontend (Flutter :3000)" cmd /k "cd /d "%ROOT_DIR%frontend" && title Meowtopia Frontend (Flutter :3000) && color 0B && echo ======================================== && echo       MEOWTOPIA FRONTEND (FLUTTER)       && echo ======================================== && echo URL Frontend: http://127.0.0.1:3000 && echo Petunjuk: && echo   - Tekan 'r' untuk Hot Reload && echo   - Tekan 'R' untuk Hot Restart && echo   - Tekan 'q' untuk keluar && echo. && flutter run -d web-server --web-hostname=127.0.0.1 --web-port=3000"
) else (
    echo.
    echo [PERINGATAN] Flutter SDK belum terdeteksi.
    echo Backend tetap berjalan normal.
)

echo.
echo ======================================================================
echo [SUKSES] Backend dan Frontend Meowtopia sedang berjalan!
echo.
echo   1. Aplikasi Flutter (Frontend) : http://127.0.0.1:3000
echo   2. Panel Admin Review (MEOW-22): http://127.0.0.1:8000/api/v1/feeding/admin-preview
echo   3. Endpoint JSON Spot Pakan    : http://127.0.0.1:8000/api/v1/feeding/spots
echo.
echo Akun Demo Seeder:
echo   - Mahasiswa  : mahasiswa@student.telkomuniversity.ac.id (password: password)
echo   - Spot Admin : spotadmin@telkomuniversity.ac.id         (password: password)
echo ======================================================================
echo.
pause
