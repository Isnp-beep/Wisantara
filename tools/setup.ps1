# Wisantara - setup sekali jalan (Windows PowerShell).
# Jalankan dari folder repo:  powershell -ExecutionPolicy Bypass -File tools\setup.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> 1/3  Import database ke MySQL Laragon" -ForegroundColor Green
& "$PSScriptRoot\import_db.ps1"

Write-Host "==> 2/3  Membuat platform Android Flutter" -ForegroundColor Green
if (-not (Test-Path "$root\app\android")) {
    if (Test-Path "$root\app_tmp") { Remove-Item "$root\app_tmp" -Recurse -Force }
    flutter create --org id.wisantara --project-name wisantara --platforms=android "$root\app_tmp"
    Copy-Item "$root\app_tmp\android" "$root\app\android" -Recurse -Force
    foreach ($f in '.metadata', 'analysis_options.yaml', '.gitignore') {
        if (Test-Path "$root\app_tmp\$f") { Copy-Item "$root\app_tmp\$f" "$root\app\$f" -Force }
    }
    Remove-Item "$root\app_tmp" -Recurse -Force
} else {
    Write-Host "    app\android sudah ada, dilewati."
}

Write-Host "==> 3/3  Menambah izin Android (internet, lokasi) dan akses HTTP lokal" -ForegroundColor Green
$manifest = "$root\app\android\app\src\main\AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch 'ACCESS_FINE_LOCATION') {
    $perms = @"
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
"@
    $xml = $xml -replace '(<manifest[^>]*>)', "`$1`n$perms"
}
if ($xml -notmatch 'usesCleartextTraffic') {
    $xml = $xml -replace '<application', '<application android:usesCleartextTraffic="true"'
}
Set-Content -Path $manifest -Value $xml -Encoding UTF8

Write-Host "==> flutter pub get" -ForegroundColor Green
Set-Location "$root\app"
flutter pub get
Write-Host "`nSelesai. Nyalakan Laragon (Apache + MySQL), lalu jalankan emulator dan: cd app; flutter run" -ForegroundColor Cyan
