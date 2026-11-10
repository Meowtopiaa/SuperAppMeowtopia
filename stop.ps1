# ======================================================================
#                     MEOWTOPIA - STOP SERVICES (PowerShell)
# ======================================================================

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "                    MEOWTOPIA - STOP SERVICES                         " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[INFO] Menghentikan proses Laravel & Flutter..." -ForegroundColor Yellow
taskkill /F /IM php.exe /FI "WINDOWTITLE eq Meowtopia Backend*" 2>$null | Out-Null
taskkill /F /FI "WINDOWTITLE eq Meowtopia Backend*" 2>$null | Out-Null
taskkill /F /FI "WINDOWTITLE eq Meowtopia Frontend*" 2>$null | Out-Null

Write-Host ""
Write-Host "[SUKSES] Semua layanan Meowtopia telah dihentikan." -ForegroundColor Green
Write-Host ""

