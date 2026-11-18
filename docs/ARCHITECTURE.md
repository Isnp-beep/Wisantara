# Arsitektur

```
Flutter app  --HTTP/JSON, Bearer token-->  PHP API (Apache)  --PDO-->  MySQL
   |                                           |
   +-- foto komunitas (multipart) ------------> api/uploads/posts
```

## Aplikasi (app/lib)

- `core/` : tema, format, klien REST (`api.dart`), terjemahan (`i18n.dart`), state sesi (`state.dart`, Provider)
- `widgets/common.dart` : ikon Lucide (SVG), maskot, kartu, rating, `FutureView` untuk loading/error/coba lagi
- `screens/` : satu file per layar. Navigasi memakai `Navigator` biasa, jadi tombol kembali selalu kembali ke layar sebelumnya.
- Tab bawah (Beranda, Jelajah, Komunitas, Pesanan, Profil) hidup di `shell.dart`. Perubahan data (`AppState.bump()`) membuat tab me-refresh.

## API (api/)

- `lib/core.php` : koneksi PDO, helper query, router berbasis regex, autentikasi token (`api_tokens`)
- `routes/*.php` : satu file per domain
- Respons selalu JSON. Error berbentuk `{"error": "pesan"}` dengan kode HTTP yang sesuai.

## Alur utama

1. **Rekomendasi**: `POST /recommend` mengurai budget, jumlah hari, dan minat dari kalimat, menilai tiap destinasi (minat, budget, rating), lalu mengembalikan 3 teratas.
2. **Pemesanan**: `POST /bookings` membuat pesanan `pending`; `POST /bookings/{id}/pay` mengubahnya menjadi `paid`, membuat notifikasi, lalu menyinkronkan ke rencana (centang tiket dan pemandu, catat pengeluaran).
3. **Planner**: `POST /plans/{id}/add-destination` menambah jadwal otomatis (tiba, tiket, pemandu, jelajah, makan siang).
4. **Pengingat**: `GET /notifications` membuat notifikasi H-3 (barang bawaan) dan H-1 (berangkat) bila belum ada, dideduplikasi lewat kolom `ref`.
