# Backend (PHP API)

Folder `klinik_api/` menyimpan endpoint ringan yang diakses oleh Flutter (`lib/services/api_service.dart`). API ini memakai PHP 8 + PDO dan tersambung ke database MySQL/MariaDB `klinik_rawat_jalan` yang ada di `db/klinik_rawat_jalan.sql`.

## Prasyarat

- PHP 8.1+ dengan ekstensi `pdo_mysql`
- MySQL/MariaDB 10.4+
- Web server (Apache/Nginx) **atau** PHP built-in server untuk pengembangan

## Langkah Setup

1. Import database:
   ```sh
   mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS klinik_rawat_jalan CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
   mariadb -u root -p klinik_rawat_jalan < db/klinik_rawat_jalan.sql
   ```
2. Salin folder backend ke root web server Anda (misal `/var/www/html/klinik_api`).
3. Ubah kredensial database + token/admin credentials jika perlu melalui variabel lingkungan atau langsung di `be/klinik_api/config.php`:
   ```sh
   export DB_HOST=127.0.0.1
   export DB_NAME=klinik_rawat_jalan
   export DB_USER=your_user
   export DB_PASS=your_password
   export ADMIN_TOKEN=super-secret-token
    export ADMIN_USERNAME=admin
    export ADMIN_PASSWORD_HASH='$2y$10$7Kp5bUgHkdjP88Ea49X3Men/C06RaoXu1v1jxENdJqfhwF3EX8G7m' # hash dari admin123
   ```
   > **Catatan:** `ADMIN_PASSWORD_HASH` menerima nilai hasil `password_hash(<password>, PASSWORD_BCRYPT)`.
4. Jalankan server lokal (opsional) dari folder `be/klinik_api`:
   ```sh
   php -S 0.0.0.0:8000
   ```
   Flutter harus diarahkan ke `http://<IP>:8000` (Android emulator memakai `10.0.2.2`).

## Endpoint Singkat

| Endpoint | Method | Deskripsi |
| --- | --- | --- |
| `/login.php` | POST | Login pasien, body `{ "nik": "...", "password": "..." }` |
| `/register.php` | POST | Registrasi pasien baru. Field opsional: `tanggal_lahir`, `alamat`, `no_telepon` |
| `/get_dokter.php` | GET | Mengembalikan daftar dokter (array JSON) |
| `/buat_janji.php` | POST | Membuat janji & nomor antrian. Body wajib `id_pasien`, `id_dokter`, `tanggal`, `jam`. Field opsional `poli`, `catatan` |
| `/get_antrian.php?id_pasien=<id>` | GET | Daftar janji + nomor antrian milik pasien |
| `/admin_login.php` | POST | Tukar `username`/`password` admin menjadi token (gunakan `Authorization: Bearer <token>`) |

### Endpoint Admin (gunakan header `Authorization: Bearer <ADMIN_TOKEN>`)

| Endpoint | Method | Deskripsi |
| --- | --- | --- |
| `/dokter.php` | GET/POST/PUT/DELETE | CRUD dokter, berisi field `nama`, `spesialisasi`, `no_telepon`, `jadwal_praktik` |
| `/pasien.php` | GET/POST/PUT/DELETE | CRUD pasien untuk petugas. GET tidak menampilkan hash password. |
| `/janji.php` | GET/PUT/PATCH/DELETE | Lihat atau ubah janji. Tanpa filter GET membutuhkan token admin. Bisa memperbarui status/waktu/poli/catatan atau menghapus janji. |
| `/antrian.php` | GET/PUT/PATCH | Lihat daftar antrian berdasarkan dokter/tanggal serta ubah nomor/status antrian. |
| `/jadwal.php?id_dokter=<id>&tanggal=YYYY-MM-DD` | GET | Ringkasan jadwal dokter plus booking antara `tanggal_mulai`–`tanggal_selesai`. |
| `/rekam_medis.php` | GET/POST/PUT/DELETE | Data rekam medis per janji. GET bisa difilter `id_rekam_medis`, `id_janji`, `id_pasien`. |
| `/obat.php` | GET/POST/PUT/DELETE | Master obat (nama, jenis, bentuk, stok). |
| `/resep.php` | GET/POST/PUT/DELETE | Kelola relasi `entity_obat` (resep) antara rekam medis dan obat. |
| `/laporan.php` | GET/POST/PUT/DELETE | CRUD laporan periodik (periode, jenis, isi). |
| `/dashboard.php` | GET | Ringkasan metrik (jumlah pasien/dokter, status janji, janji terdekat, stok obat rendah). |

Semua respons menggunakan JSON UTF-8 dan sudah menambahkan header CORS dasar. Sesuaikan lebih lanjut (auth token, validasi tambahan, dsb.) sesuai kebutuhan produksi.
