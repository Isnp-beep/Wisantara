# Setup Wisantara (Windows + Laragon + Android SDK)

## Prasyarat

- Laragon (Apache + MySQL) menyala, folder proyek di `C:\laragon\www\Wisantara`
- Flutter SDK dan Android SDK (emulator atau HP asli)
- VS Code dengan ekstensi Flutter dan Dart
- Git, dengan `user.name` dan `user.email` milikmu

## 1. Database dan platform Android

```powershell
cd C:\laragon\www\Wisantara
powershell -ExecutionPolicy Bypass -File tools\setup.ps1
```

Skrip ini mengimpor `database/schema.sql` dan `seed.sql`, membuat folder `app/android`, menambah izin internet dan lokasi, lalu menjalankan `flutter pub get`.

Secara manual: impor dua file SQL lewat HeidiSQL (bawaan Laragon) atau `mysql -u root < database\schema.sql`.

## 2. Tes API

Buka `http://localhost/Wisantara/api/` di browser. Harus muncul `{"name":"Wisantara API","status":"ok"}`.

Jika semua route selain `/` memberi 404, aktifkan `mod_rewrite` di Apache Laragon dan pastikan `AllowOverride All`.

## 3. Jalankan aplikasi

```powershell
cd app
flutter run
```

Alamat API bawaan untuk emulator: `http://10.0.2.2/Wisantara/api`.

Untuk HP asli: samakan Wi-Fi dengan laptop, ketuk ikon roda gigi di layar masuk, isi `http://IP-LAPTOP/Wisantara/api` (cek `ipconfig`), dan izinkan Apache di firewall Windows.

## 4. Variabel lingkungan (opsional)

| Variabel | Fungsi |
| --- | --- |
| `DB_DSN`, `DB_USER`, `DB_PASS` | Koneksi database (bawaan: root tanpa kata sandi) |
| `ANTHROPIC_API_KEY` | Mengaktifkan penjelasan rekomendasi oleh Claude API |
| `ANTHROPIC_MODEL` | Model yang dipakai (bawaan `claude-haiku-5-5`) |

## Masalah umum

- **Tidak bisa terhubung ke server**: Laragon belum menyala, atau URL API salah.
- **Foto tidak muncul**: pastikan `api/uploads/seed` ada dan URL API memakai host yang bisa dijangkau perangkat.
- **Peta kosong**: butuh internet untuk tile OpenStreetMap.
