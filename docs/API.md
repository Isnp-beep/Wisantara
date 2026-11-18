# API Wisantara

Base URL: `http://localhost/Wisantara/api`. Autentikasi: header `Authorization: Bearer <token>`. 🔒 = wajib login.

| Method | Path | Keterangan |
| --- | --- | --- |
| POST | `/auth/register` | name, email, password, role (`turis`/`lokal`) |
| POST | `/auth/login` | email, password, mengembalikan `token` dan `user` |
| POST | `/auth/logout` | 🔒 |
| POST | `/auth/forgot` | email |
| GET/PUT | `/me` | 🔒 profil, ubah name/role/language |
| GET | `/me/stats` | 🔒 jumlah perjalanan, tersimpan, posting, rencana |
| GET | `/destinations` | q, category, region, max_price, lat, lng, lang |
| GET | `/destinations/{id}` | detail lengkap + ringkasan rating |
| POST | `/destinations/{id}/favorite` | 🔒 toggle |
| GET | `/favorites` | 🔒 |
| GET | `/destinations/{id}/reviews` | ringkasan rating dan postingan |
| GET | `/guides` | lang, region |
| GET | `/phrases` | lang |
| POST | `/recommend` | prompt, budget, days, people, interests[] |
| POST | `/bookings` | 🔒 destination_id, visit_date, qty, guide_id |
| GET | `/bookings`, `/bookings/{id}` | 🔒 |
| POST | `/bookings/{id}/pay` | 🔒 method: `qris`/`va`/`ewallet`/`card` |
| POST | `/bookings/{id}/cancel` | 🔒 hanya yang belum bayar |
| GET | `/posts` | tab=`all`/`following`, destination_id, guide_id |
| POST | `/posts` | 🔒 multipart: destination_id, rating_place, guide_id, rating_guide, caption, image |
| POST | `/posts/{id}/like` | 🔒 toggle |
| GET/POST | `/posts/{id}/comments` | POST 🔒 |
| POST | `/users/{id}/follow` | 🔒 toggle |
| GET/POST | `/plans` | 🔒 |
| GET/PUT/DELETE | `/plans/{id}` | 🔒 |
| POST | `/plans/{id}/items` | 🔒 title, time_label, day_no, kind |
| PATCH/DELETE | `/plans/{id}/items/{item}` | 🔒 |
| POST | `/plans/{id}/expenses` | 🔒 title, amount |
| DELETE | `/plans/{id}/expenses/{eid}` | 🔒 |
| POST | `/plans/{id}/packing` | 🔒 label |
| PATCH/DELETE | `/plans/{id}/packing/{pid}` | 🔒 |
| POST | `/plans/{id}/add-destination` | 🔒 destination_id, day_no, with_guide |
| GET | `/notifications` | 🔒 sekaligus membuat pengingat |
| POST | `/notifications/read-all`, `/notifications/{id}/read` | 🔒 |
