# Dokumen Handover & Panduan Pengujian Reviewer — ServisKu

Dokumen ini disusun untuk memudahkan **Reviewer / Penguji** dalam menjalankan, mengevaluasi, dan menguji seluruh fitur pada aplikasi **ServisKu (Buku Riwayat Perawatan Motor Digital)**.

---

## 1. Persiapan & Cara Menjalankan Aplikasi

Aplikasi dikembangkan menggunakan **Flutter** (Target Platform: **Android & Web**) dengan manajemen state **Flutter Riverpod** serta database cloud **Supabase PostgreSQL & Supabase Auth**.

### Langkah Menjalankan Aplikasi:
```bash
# 1. Masuk ke direktori proyek dan unduh dependensi
flutter pub get

# 2. Jalankan aplikasi di Google Chrome (Web) atau Emulator/Perangkat Android
flutter run -d chrome
# atau untuk Android:
flutter run
```

---

## 2. Alur Pengujian Fitur untuk Reviewer (Step-by-Step)

### A. Autentikasi & Rute Terproteksi (Advance Feature 1)
1. **Rute Terproteksi**: Saat aplikasi pertama kali dijalankan, pengguna belum memiliki sesi aktif dan akan otomatis diarahkan ke **Halaman Login**. Pengguna tidak dapat mengakses Dashboard tanpa login terlebih dahulu.
2. **Registrasi Akun Baru**:
   - Klik tombol **"Daftar Sekarang"** di bagian bawah form login.
   - Isi **Nama Lengkap**, **Email** (contoh: `reviewer.servisku@gmail.com`), dan **Kata Sandi** (minimal 6 karakter).
   - Klik **"Daftar Akun Baru"**. Akun akan didaftarkan ke Supabase Auth & penyimpanan lokal, lalu pengguna otomatis diarahkan masuk ke Dashboard.
3. **Login Email & Opsi Gmail**:
   - Untuk menguji login ulang, buka tab **Akun** (kanan bawah) -> klik **"Keluar dari Akun (Logout)"**.
   - Masukkan kembali email dan kata sandi yang telah didaftarkan, atau gunakan tombol **"Masuk dengan Akun Gmail"**.

---

### B. Informasi Motor Utama & Profil Akun
1. Buka tab **Kendaraan** (Dashboard) atau tab **Akun**.
2. Pada tab **Akun**, terdapat kartu **Informasi Motor & Akun** yang menampilkan:
   - Nama / Tipe Motor, Plat Nomor, dan Tahun Kendaraan.
   - **Tanggal Pembuatan Akun** yang tercatat secara otomatis.
3. Klik tombol **"Edit Motor"** (atau tombol **"Edit"** di kartu hijau atas pada Dashboard), ubah nama motor, plat nomor, serta tahun, lalu klik **Simpan**. Perubahan akan langsung tersinkronisasi ke seluruh layar dan database cloud.

---

### C. Pencatatan Riwayat Servis (CRUD) & Kalkulasi Pantauan Komponen
Fitur **Pantauan Komponen** menghitung target kilometer servis berikutnya secara otomatis dari data **Riwayat Servis**:

$$\text{Target KM Berikutnya} = \text{Odometer Servis Terakhir (Status Selesai)} + \text{Interval KM Komponen}$$

**Cara Menguji Perubahan Status (`Belum Selesai` vs `Selesai`)**:
1. Klik tombol **`+`** di kanan bawah Dashboard (atau klik langsung kartu **Oli Mesin** pada bagian *Pantauan Komponen*).
2. Isi form dengan data contoh berikut:
   - **Jenis servis**: `Oli Mesin`
   - **Odometer (km)**: `2500`
   - **Total biaya**: `65000`
   - **Status Servis**: `Belum Selesai`
   - Klik **Simpan catatan**.
3. **Amati Hasil Saat Status `Belum Selesai`**:
   - Odometer motor naik ke `2.500 km`.
   - Karena servis `Oli Mesin` berstatus **Belum Selesai**, kartu **Oli Mesin** di *Pantauan Komponen* akan menyala **Merah (`Servis! / Waktunya ganti!`)** dan memicu notifikasi peringatan.
4. **Ubah Status Menjadi `Selesai`**:
   - Pada daftar *Riwayat terbaru*, klik ikon titik tiga (**`...`**) di sebelah kanan item `Oli Mesin` -> pilih **"Tandai Selesai"**.
5. **Amati Perubahan Saat Ditandai `Selesai`**:
   - Ikon riwayat berubah menjadi **Centang Hijau (`✓`)** beserta tanggal penyelesaian (*"Diselesaikan pada ..."*).
   - Target pada kartu **Oli Mesin** langsung ter-reset ke jadwal berikutnya yaitu **`5,000 km (+2,500)`** dengan sisa jarak **`Sekitar 2,500 km lagi`** dan progress bar kembali normal.
6. **Menguji Pencarian (Search Bar)**:
   - Ketik nama komponen atau jenis servis (misal: `oli` atau `kampas rem`) pada kolom pencarian untuk memfilter daftar riwayat dan komponen secara instan.

---

### D. Notifikasi & Pengingat Servis Berkala (Advance Feature 2)
1. Buka tab **Notifikasi** di navigasi bawah.
2. Notifikasi dibuat secara **otomatis** ketika:
   - Pengguna mencatat riwayat servis baru (`✅ Servis Tercatat`).
   - Sisa jarak tempuh komponen $\le 500\text{ km}$ (`⏳ Pengingat Servis`).
   - Odometer melewati batas jadwal servis komponen (`🚨 Waktunya Servis!`).
3. **Tombol Simulasi Instan untuk Reviewer**:
   - Klik ikon **Lonceng `+`** di pojok kanan atas halaman **Notifikasi** untuk memicu contoh notifikasi peringatan jatuh tempo secara langsung.
   - Klik ikon titik tiga (**`⋮`**) di pojok kanan atas untuk mencoba fitur **Tandai Semua Dibaca**, **Hapus Semua Notifikasi**, dan pengaturan **Kelola Izin Notifikasi** (*Granted / Denied*).

---

### E. Pencari Bengkel & Lokasi GPS Dinamis (Advance Feature 3)
1. Buka tab **Bengkel** di navigasi bawah.
2. Aplikasi otomatis mendeteksi lokasi kota/kecamatan pengguna menggunakan jaringan/GPS (*IP Geolocation & OpenStreetMap Nominatim Reverse Geocoding*).
3. **Menguji Pencarian Lokasi Kota Manual**:
   - Klik tombol **"Ubah"** pada label lokasi di bagian bawah peta radar (atau ikon GPS di pojok kanan atas AppBar).
   - Ketik nama kota atau kecamatan mana saja di Indonesia (contoh: `Samarinda`, `Balikpapan`, `Surabaya`, `Bandung`, `Yogyakarta`) lalu klik **Cari**.
   - Titik koordinat, daftar bengkel terdekat, serta perhitungan jarak (`km`) akan otomatis diperbarui mengikuti kota yang dipilih.
4. Klik tombol **"Rute Maps"** pada salah satu bengkel untuk membuka tautan penunjuk arah (*Directions*) Google Maps dari titik lokasi pengguna menuju bengkel tersebut.

