# Mendorong proyek ke GitHub langkah demi langkah, satu commit per bagian.
# Semua commit memakai identitas git MILIKMU (user.name / user.email di komputer ini).
# Jalankan dari folder repo:  powershell -ExecutionPolicy Bypass -File tools\git_push_steps.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$name = git config user.name; $mail = git config user.email
if (-not $name -or -not $mail) {
    Write-Host "Atur identitas git dulu supaya commit atas namamu:" -ForegroundColor Yellow
    Write-Host '  git config --global user.name "Nama Kamu"'
    Write-Host '  git config --global user.email "email-github-kamu@contoh.com"'
    exit 1
}
Write-Host "Commit akan dibuat sebagai: $name <$mail>" -ForegroundColor Cyan

# --- Langkah 1: persis perintah awal dari GitHub ---
if (-not (Test-Path "$root\.git")) {
    Set-Content -Path README.md -Value "# Wisantara" -Encoding UTF8
    git init
    git add README.md
    git commit -m "first commit"
    git branch -M main
    git remote add origin https://github.com/Isnp-beep/Wisantara.git
    git push -u origin main
}

function Step([string]$message, [string[]]$paths) {
    foreach ($p in $paths) { if (Test-Path $p) { git add -- $p } }
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -q -m $message
        Write-Host "  + $message"
    }
}

# --- Fondasi ---
Step "chore: tambah .gitignore" @('.gitignore')
Step "docs: jelaskan arsitektur dan alur data" @('docs/ARCHITECTURE.md')
Step "docs: dokumentasi endpoint API" @('docs/API.md')
Step "docs: panduan setup Laragon dan Android SDK" @('docs/SETUP.md')

# --- Database ---
Step "feat(db): rancang skema MySQL" @('database/schema.sql')
Step "feat(db): isi data awal destinasi, pemandu, dan komunitas" @('database/seed.sql')

# --- API ---
Step "feat(api): konfigurasi dan rewrite Apache" @('api/config.php', 'api/.htaccess')
Step "feat(api): inti router, database, dan autentikasi token" @('api/lib/core.php')
Step "feat(api): foto destinasi (Wikimedia CC)" @('api/uploads/seed', 'api/uploads/posts/.gitkeep')
Step "feat(api): endpoint register, login, dan profil" @('api/routes/auth.php')
Step "feat(api): endpoint destinasi, favorit, pemandu, dan frasa" @('api/routes/destinations.php')
Step "feat(api): rekomendasi wisata berdasarkan budget, hari, dan minat" @('api/routes/recommend.php')
Step "feat(api): pemesanan dan pembayaran" @('api/routes/bookings.php')
Step "feat(api): komunitas - posting, like, komentar, follow, rating" @('api/routes/community.php')
Step "feat(api): rencana perjalanan, budget, dan barang bawaan" @('api/routes/plans.php')
Step "feat(api): notifikasi dan pengingat H-3 / H-1" @('api/routes/notifications.php')
Step "feat(api): entry point index.php" @('api/index.php')

# --- Aplikasi Flutter ---
Step "chore(app): inisialisasi pubspec dan dependensi" @('app/pubspec.yaml')
Step "chore(app): tambah ikon Lucide" @('app/assets/icons')
Step "chore(app): tambah maskot kadal" @('app/assets/mascots')
Step "feat(app): tema warna Batik Merah Putih" @('app/lib/core/theme.dart')
Step "feat(app): helper format rupiah dan tanggal" @('app/lib/core/format.dart')
Step "feat(app): klien REST API" @('app/lib/core/api.dart')
Step "feat(app): terjemahan antarmuka 5 bahasa" @('app/lib/core/i18n.dart')
Step "feat(app): state global dan sesi login" @('app/lib/core/state.dart')
Step "feat(app): widget umum (ikon, kartu, rating, loader)" @('app/lib/widgets/common.dart')
Step "feat(app): entry point dan animasi splash" @('app/lib/main.dart', 'app/lib/screens/splash.dart')
Step "feat(app): layar masuk dan daftar" @('app/lib/screens/auth.dart')
Step "feat(app): pemilih bahasa" @('app/lib/screens/language.dart')
Step "feat(app): navigasi bawah" @('app/lib/screens/shell.dart')
Step "feat(app): beranda dengan slider foto dan kotak AI" @('app/lib/screens/home.dart')
Step "feat(app): layar rekomendasi AI" @('app/lib/screens/recommend.dart')
Step "feat(app): jelajah dengan pencarian dan filter" @('app/lib/screens/explore.dart')
Step "feat(app): detail wisata - akses, plus minus, perlengkapan, ulasan" @('app/lib/screens/detail.dart')
Step "feat(app): peta wisata terdekat" @('app/lib/screens/map_screen.dart')
Step "feat(app): daftar dan pilih pemandu" @('app/lib/screens/guides.dart')
Step "feat(app): pemesanan, pembayaran, dan tiket QR" @('app/lib/screens/booking.dart')
Step "feat(app): daftar pesanan" @('app/lib/screens/orders.dart')
Step "feat(app): feed komunitas dan komentar" @('app/lib/screens/community.dart')
Step "feat(app): unggah foto dan rating tempat atau pemandu" @('app/lib/screens/post_create.dart')
Step "feat(app): daftar rencana per folder" @('app/lib/screens/plans.dart')
Step "feat(app): detail rencana - jadwal, budget, barang bawaan" @('app/lib/screens/plan_detail.dart')
Step "feat(app): terjemahan frasa" @('app/lib/screens/translate.dart')
Step "feat(app): notifikasi" @('app/lib/screens/notifications.dart')
Step "feat(app): profil dan wisata tersimpan" @('app/lib/screens/profile.dart')

# --- Penutup ---
Step "chore(tools): skrip setup database dan Android" @('tools/setup.ps1', 'tools/import_db.ps1', 'tools/git_push_steps.ps1')
Step "chore(app): platform Android" @('app/android', 'app/.metadata', 'app/analysis_options.yaml', 'app/.gitignore')
if (Test-Path "$root\docs\README.md") {
    Copy-Item "$root\docs\README.md" "$root\README.md" -Force
    Remove-Item "$root\docs\README.md" -Force
    Step "docs: lengkapi README" @('README.md')
}

Write-Host "`nMendorong ke GitHub..." -ForegroundColor Green
git push origin main
Write-Host "Selesai. Cek https://github.com/Isnp-beep/Wisantara" -ForegroundColor Cyan
