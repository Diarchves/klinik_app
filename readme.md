Cara running proyek

1. mysql(db): mariadb klinik_rawat_jalan < klinik_rawat_jalan.sql
2. php(be): php -S 0.0.0.0:8000 -t klinik_api
3. flutter(fe): flutter run -d chrome -v --dart-define=API_URL=http://127.0.0.1:8000


Jalankan Backend (PHP + MySQL)

Siapkan database: import dump klinik_rawat_jalan.sql ke MySQL/MariaDB (mysql -u root -p < db/klinik_rawat_jalan.sql). Pastikan nama DB tetap klinik_rawat_jalan.
Konfigurasi kredensial: jika host/db/user/password beda, ubah konstanta di config.php atau gunakan environment variable DB_HOST, DB_NAME, DB_USER, DB_PASS.
Jalankan server PHP: dari folder be, jalankan php -S 0.0.0.0:8000 -t klinik_api. Endpoint backend akan tersedia di http://localhost:8000. Gunakan server Apache/Nginx bila ingin permanen; cukup arahkan document root ke klinik_api.
Jalankan Frontend Flutter

Masuk ke folder fe, jalankan flutter pub get, lalu flutter run untuk emulator/device yang diinginkan.
Pastikan frontend tahu URL backend. Secara default ApiService memakai http://10.0.2.2/klinik_api (alamat khusus Android emulator ke host).
Jika backend ada di http://localhost:8000, saat menjalankan Flutter di emulator Android pakai flutter run --dart-define=API_URL=http://10.0.2.2:8000.
Jika menjalankan di web/desktop, gunakan host normal: flutter run -d chrome --dart-define=API_URL=http://localhost:8000.
Sesuaikan IP jika backend berjalan di mesin lain (mis. http://192.168.1.10:8000).
Alur koneksi

Backend PHP melayani permintaan REST ke tabel-tabel sesuai dump SQL.
Flutter FE memanggil endpoint tersebut melalui ApiService, jadi selama URL/port sesuai, data pasien, dokter, janji, dll. tersinkron otomatis.
Setelah semua aktif, uji cepat dengan membuat akun dari aplikasi, login, buat janji, dan cek tabel di database untuk memastikan integrasi sukses.
