# Wisantara

Aplikasi mobile yang memperkenalkan Indonesia kepada warga lokal (warlok) dan wisatawan. Maskotnya kadal berblangkon dan batik.

**Stack:** Flutter (Android) · PHP 8 REST API (Laragon/Apache) · MySQL.

## Fitur

- Splash animasi, daftar/masuk, 5 bahasa (Indonesia, English, 中文, 日本語, 한국어)
- Beranda dengan slider foto wisata dan kotak rekomendasi (ketik "budget 2 juta 3 hari gunung")
- Rekomendasi: parser budget/hari/minat, opsional dipercantik Claude API
- Jelajah: cari, filter kategori dan harga, simpan favorit
- Detail wisata: estimasi akses mobil/motor/jalan kaki per kota asal, kelebihan dan kekurangan, perlengkapan, makan di sekitar, ulasan
- Peta OpenStreetMap + wisata terdekat dari lokasimu
- Sewa pemandu, pesan tiket, bayar (simulasi QRIS/VA/e-wallet/kartu), tiket QR
- Komunitas: posting foto, like, komentar, follow, rating tempat dan pemandu
- Planner ala Notion: folder, jadwal per jam, budget, barang bawaan, pengingat H-3 dan H-1
- Bayar tiket otomatis mencentang rencana dan mengurangi budget
- Buku frasa terjemahan, notifikasi, profil

## Struktur

```
api/        REST API PHP (lib/core.php + routes/*.php)
app/        Aplikasi Flutter (lib/core, lib/widgets, lib/screens)
database/   schema.sql dan seed.sql (MySQL)
docs/       ARCHITECTURE.md, API.md, SETUP.md
tools/      setup.ps1, import_db.ps1, git_push_steps.ps1
```

## Menjalankan

Lihat [docs/SETUP.md](docs/SETUP.md). Ringkasnya:

1. Taruh proyek di `C:\laragon\www\Wisantara`, nyalakan Laragon (Apache + MySQL).
2. `powershell -ExecutionPolicy Bypass -File tools\setup.ps1`
3. Jalankan emulator Android, lalu `cd app` dan `flutter run`.

Akun contoh: `raka@wisantara.id` / `password123`.

## Catatan

- Pembayaran masih simulasi; titik sambung gateway ada di `api/routes/bookings.php`.
- Pengingat H-3/H-1 berupa notifikasi dalam aplikasi, dibuat saat daftar notifikasi dibuka.
- Foto destinasi berlisensi Creative Commons dari Wikimedia Commons; kredit ada di data dan ditampilkan di halaman detail.
