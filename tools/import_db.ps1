# Mengimpor database/schema.sql dan database/seed.sql ke MySQL Laragon (user root tanpa password).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mysql = Get-ChildItem "C:\laragon\bin\mysql" -Recurse -Filter mysql.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $mysql) { throw "mysql.exe tidak ditemukan di C:\laragon\bin\mysql. Pastikan Laragon terpasang dan MySQL aktif." }
foreach ($f in 'schema.sql', 'seed.sql') {
    Write-Host "    mengimpor $f"
    Get-Content "$root\database\$f" -Raw -Encoding UTF8 | & $mysql.FullName -u root --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw "Gagal mengimpor $f" }
}
Write-Host "    database 'wisantara' siap."
