# ============================================================
#  PLASVORA — Script Run Development (USB via ADB Reverse)
#  Jalankan di PowerShell dari folder C:\Project\Plasvora_app
#  Perintah: powershell -ExecutionPolicy Bypass -File run_dev.ps1
# ============================================================

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  PLASVORA Dev Launcher" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Cek dan jalankan MySQL (XAMPP) ──────────────────────
Write-Host "[1/4] Mengecek MySQL..." -ForegroundColor Yellow
$mysqlRunning = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue
if ($mysqlRunning) {
    Write-Host "      MySQL sudah berjalan." -ForegroundColor Green
} else {
    Write-Host "      Menjalankan MySQL..." -ForegroundColor Yellow
    Start-Process "C:\xampp\mysql\bin\mysqld.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    Write-Host "      MySQL dijalankan." -ForegroundColor Green
}

# ── 2. Jalankan Laravel Backend ────────────────────────────
Write-Host "[2/4] Menjalankan Laravel backend di port 8000..." -ForegroundColor Yellow
$laravelRunning = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
if ($laravelRunning) {
    Write-Host "      Laravel sudah berjalan di port 8000." -ForegroundColor Green
} else {
    Start-Process -FilePath "C:\xampp\php\php.exe" `
        -ArgumentList "C:\xampp\htdocs\backend_plasvora\artisan", "serve", "--host=0.0.0.0", "--port=8000" `
        -WindowStyle Normal
    Start-Sleep -Seconds 3
    Write-Host "      Laravel dijalankan di http://0.0.0.0:8000" -ForegroundColor Green
}

# ── 3. ADB Reverse (USB) ───────────────────────────────────
Write-Host "[3/4] Mengatur ADB reverse (USB)..." -ForegroundColor Yellow
$devices = & adb devices 2>&1
if ($devices -match "device$") {
    & adb reverse tcp:8000 tcp:8000
    Write-Host "      ADB reverse tcp:8000 -> tcp:8000 aktif." -ForegroundColor Green
} else {
    Write-Host "      PERINGATAN: Tidak ada perangkat USB terdeteksi." -ForegroundColor Red
    Write-Host "      Pastikan HP tersambung via USB dan USB Debugging aktif." -ForegroundColor Red
}

# ── 4. Jalankan Flutter di HP ──────────────────────────────
Write-Host "[4/4] Menjalankan Flutter app di HP..." -ForegroundColor Yellow
Write-Host ""
Write-Host "      Tekan Ctrl+C untuk menghentikan Flutter." -ForegroundColor DarkGray
Write-Host ""

flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api

