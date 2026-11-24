@echo off
chcp 65001 >nul
title Meowtopia - Stop Services

echo ======================================================================
echo                     MEOWTOPIA - STOP SERVICES                         
echo ======================================================================
echo.

echo [INFO] Menghentikan proses Laravel (php artisan serve)...
taskkill /F /IM php.exe /FI "WINDOWTITLE eq Meowtopia Backend*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq Meowtopia Backend*" >nul 2>&1

echo [INFO] Menghentikan proses Flutter...
taskkill /F /FI "WINDOWTITLE eq Meowtopia Frontend*" >nul 2>&1

echo.
echo [SUKSES] Semua layanan Meowtopia telah dihentikan.
echo.
pause

