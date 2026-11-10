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
start "Meowtopia - Backend (Laravel API :8000)" cmd /k "cd /d "%ROOT_DIR%backend" && title Meowtopia Backend (Port 8000) && color 0A && echo ======================================== && echo       MEOWTOPIA BACKEND (LARAVEL)       && echo ======================================== && echo URL: http://127.0.0.1:8000 && echo API: http://127.0.0.1:8000/api/v1 && echo. && php artisan serve --host=127.0.0.1 --port=8000"

if "%FLUTTER_AVAILABLE%"=="1" (
    echo [2/2] Menjalankan Aplikasi Frontend (Flutter)...
    start "Meowtopia - Frontend (Flutter)" cmd /k "cd /d "%ROOT_DIR%frontend" && title Meowtopia Frontend (Flutter) && color 0B && echo ======================================== && echo       MEOWTOPIA FRONTEND (FLUTTER)       && echo ======================================== && echo Petunjuk: && echo   - Tekan 'r' untuk Hot Reload && echo   - Tekan 'R' untuk Hot Restart && echo   - Tekan 'q' untuk keluar && echo. && flutter run"
) else (
    echo.
    echo [PERINGATAN] Flutter SDK belum terdeteksi.
    echo Backend tetap berjalan normal.
)

echo.
echo ======================================================================
echo [SUKSES] Backend dan Frontend Meowtopia siap digunakan!
echo.
echo   - Backend API : http://127.0.0.1:8000/api/v1
echo   - Admin Panel : http://127.0.0.1:8000/admin
echo   - Frontend UI : Jendela terminal Flutter (Hot Reload: 'r')
echo.
echo Anda dapat menutup jendela launcher ini kapan saja.
echo ======================================================================
echo.
pause
