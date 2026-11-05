# ServisKu - Buku Riwayat Perawatan Motor Digital

## Deskripsi Masalah
Banyak pemilik kendaraan bermotor, khususnya sepeda motor yang digunakan untuk mobilitas sehari-hari, sering kali lupa kapan terakhir kali mereka melakukan perawatan rutin, seperti mengganti oli mesin, kampas rem, busi, maupun servis transmisi berkala. 

Selama ini, pencatatan perawatan kendaraan masih sangat bergantung pada buku servis konvensional atau kartu kertas yang diberikan oleh pihak bengkel. Kartu berbahan kertas tersebut rentan hilang, robek, basah, atau tertinggal di rumah saat pengguna sedang berada di bengkel. Ketiadaan catatan yang teratur dan mudah diakses ini menyebabkan perawatan motor menjadi tertunda atau terlewat, yang berujung pada penurunan performa motor, kerusakan mesin secara mendadak, serta pembengkakan biaya perbaikan kendaraan.

---

## Profil Target Pengguna
Aplikasi ini dirancang khusus untuk memenuhi kebutuhan:
* **Pengguna Utama**: Pemilik dan pengendara sepeda motor harian, khususnya kalangan mahasiswa, pekerja kantor, dan anak kos yang memiliki rutinitas padat.
* **Karakteristik & Kebutuhan Pengguna**: Pengguna membutuhkan pencatatan digital yang praktis dan cepat dibuka melalui layar smartphone saat sedang berada di bengkel untuk mengecek riwayat kilometer (odometer) terakhir serta riwayat penggantian suku cadang sebelumnya. Pengguna juga menginginkan catatan pengeluaran biaya perawatan kendaraan yang rapi dan transparan.

---

## Manfaat Aplikasi
Hadirnya ServisKu memberikan berbagai manfaat nyata bagi para pemilik kendaraan:
* **Buku Riwayat Servis Digital yang Aman**: Menggantikan kartu kertas fisik dengan pencatatan digital berbasis cloud yang aman, teratur, dan tidak akan hilang atau rusak.
* **Kondisi Kendaraan Tetap Prima**: Membantu memantau batas interval kilometer dan jadwal servis berkala secara tepat waktu sehingga performa mesin tetap terjaga.
* **Transparansi Pengeluaran Perawatan**: Memudahkan pengguna memantau akumulasi total biaya yang telah dihabiskan untuk perawatan motor sehingga pengelolaan anggaran bulanan menjadi lebih terkontrol.
* **Kemudahan Akses Kapan Saja**: Riwayat servis dapat diakses dengan cepat langsung dari smartphone di bengkel, dan tetap dapat dibuka secara lancar meskipun koneksi internet sedang lambat atau offline berkat dukungan penyimpanan lokal.

---

## Daftar Fitur Inti
Aplikasi ini menyediakan fitur-fitur utama yang saling terintegrasi:

1. **Autentikasi Pengguna & Rute Terproteksi**: 
   Sistem mewajibkan pengguna untuk login terlebih dahulu sebelum dapat mengakses halaman dashboard. Mendukung masuk menggunakan akun email dan kata sandi terdaftar serta opsi login via akun Gmail. Pengguna baru dapat mendaftarkan akun secara mandiri melalui menu registrasi, dan sesi login tersimpan secara aman dan persisten.

2. **Pengelolaan Informasi Motor Utama**:
   Menampilkan kartu identitas kendaraan pengguna yang memuat nama dan tipe motor, plat nomor kendaraan, tahun perakitan, angka odometer terakhir, serta tanggal pembuatan akun pengguna, lengkap dengan formulir untuk mengubah data motor secara reaktif.

3. **Pencatatan Riwayat Servis (CRUD Lengkap)**:
   Formulir pencatatan servis baru yang mencakup angka odometer, jenis perawatan (seperti Ganti Oli Mesin, Kampas Rem, Busi), rincian total biaya, status pengerjaan, dan catatan mekanik. Pengguna dapat melihat daftar riwayat secara kronologis, mengedit catatan yang sudah ada, serta menghapus data dengan konfirmasi keamanan.

4. **Pemantauan Jadwal Komponen Berkala**:
   Indikator visual kondisi suku cadang utama (Oli Mesin, Rem, Busi, Filter Udara, CVT) berdasarkan jarak tempuh odometer. Sistem secara otomatis memberikan penanda peringatan jika komponen mendekati jadwal servis atau telah melewati batas interval (*overdue*), serta menyediakan fitur penambahan komponen kustom.

5. **Ringkasan Finansial Perawatan**:
   Menghitung secara otomatis total akumulasi biaya pengeluaran servis serta jumlah frekuensi servis yang telah dilakukan oleh pengguna.

6. **Fitur Lanjutan (Notifikasi & Lokasi Bengkel)**:
   Notifikasi alert pengingat servis otomatis saat kilometer motor mendekati interval servis, serta daftar dan peta penunjuk lokasi bengkel resmi maupun umum terdekat berbasis GPS beserta estimasi jaraknya.

---

## Fitur yang Tidak Dikerjakan
Agar ruang lingkup proyek tetap fokus, efisien, dan memiliki performa aplikasi yang ringan, beberapa fitur berikut sengaja tidak diimplementasikan:
1. **Pengiriman Pesan Notifikasi Eksternal**: Sistem tidak menggunakan layanan pengiriman pesan otomatis melalui SMS Gateway berbayar maupun pesan broadcast WhatsApp pihak ketiga.
2. **Unggah Berkas / Foto Nota Fisik**: Aplikasi tidak menyediakan fitur unggah gambar nota bengkel untuk menghemat ruang penyimpanan basis data, sehingga seluruh pencatatan difokuskan pada teks dan angka terstruktur.
3. **Pemesanan Antrean Servis Terintegrasi**: Aplikasi tidak terhubung langsung dengan sistem reservasi antrean bengkel resmi eksternal.
4. **Gerbang Pembayaran Digital (In-App Payment)**: Aplikasi tidak menyediakan transaksi pembayaran nontunai langsung di dalam aplikasi; pembayaran tetap dilakukan pengguna secara langsung kepada pihak bengkel.

---

## Kriteria Aplikasi Dinyatakan Berhasil
Aplikasi ServisKu dinyatakan berhasil memenuhi tujuan pembuatannya apabila:
1. **Fungsionalitas CRUD Berjalan Lancar**: Pengguna dapat menambah, melihat, mengedit, dan menghapus catatan riwayat servis maupun informasi kendaraan tanpa terjadi error atau kendala sistem.
2. **Keamanan & Pemisahan Data Terjamin**: Seluruh data tersimpan secara persisten ke database cloud PostgreSQL Supabase dengan penerapan Row Level Security (RLS) berbasis `auth.uid()`, sehingga data pengguna satu dengan pengguna lainnya terpisah secara aman dan tidak saling bercampur.
3. **Sistem Keamanan Akses Berfungsi Penuh**: Mekanisme rute terproteksi berjalan dengan benar, di mana pengguna yang belum login tidak dapat mengakses dashboard, dan sesi login pengguna tetap terjaga saat aplikasi ditutup lalu dibuka kembali.
4. **Tampilan Nyaman & Responsif**: Antarmuka aplikasi berjalan ringan, tidak rumit, sangat nyaman dibaca lewat layar smartphone, dan memiliki sistem penyimpanan lokal (*caching*) agar data tetap dapat diakses saat koneksi internet lemah.

---

## Panduan Pengujian untuk Reviewer

Bagian ini disusun sebagai panduan langkah demi langkah bagi **Reviewer / Penguji** untuk menjalankan dan menguji seluruh fitur utama serta fitur *advanced* pada aplikasi **ServisKu**.

### 1. Cara Menjalankan Aplikasi (Instalasi & Run)
Pastikan perangkat telah terinstal **Flutter SDK** (`^3.13.4`). Jalankan perintah berikut di terminal pada direktori utama proyek:

```bash
# 1. Unduh seluruh dependensi paket Flutter
flutter pub get

# 2. Jalankan aplikasi di Browser (Chrome) atau Perangkat/Emulator Android
flutter run -d chrome
# atau untuk Android:
flutter run
```

---

### 2. Skenario Pengujian Fitur (Step-by-Step Testing Guide)

#### A. Pengujian Autentikasi & Rute Terproteksi (Advance Feature 1)
1. Saat aplikasi pertama kali dibuka, sistem otomatis mengarahkan ke **Halaman Login** (pengguna tidak dapat masuk ke Dashboard sebelum autentikasi).
2. **Mendaftar Akun Baru (Registrasi)**:
   - Klik tautan **"Daftar Sekarang"** di bagian bawah halaman login.
   - Masukkan **Nama Lengkap**, **Email** (contoh: `reviewer@gmail.com`), dan **Kata Sandi** (minimal 6 karakter).
   - Klik **"Daftar Akun Baru"** -> Anda akan otomatis masuk ke halaman **Dashboard Utama**.
3. **Menguji Logout & Login Kembali**:
   - Buka tab **Akun** (pojok kanan bawah) -> gulir ke bawah dan klik **"Keluar dari Akun (Logout)"**.
   - Masuk kembali menggunakan email & kata sandi yang baru didaftarkan, atau klik tombol **"Masuk dengan Akun Gmail"**.

#### B. Pengujian Informasi Motor & Akun
1. Pada tab **Kendaraan (Dashboard)**, perhatikan kartu hijau **MOTOR UTAMA** di bagian atas.
2. Klik tombol **"Edit"** di pojok kanan atas kartu hijau tersebut (atau buka tab **Akun** -> klik **"Edit Motor"** pada kartu *Informasi Motor & Akun*).
3. Ubah **Nama Motor** (misal: `Honda Vario 160`), **Plat Nomor** (misal: `KT 1234 AB`), dan **Tahun** (misal: `2024`), lalu klik **Simpan**.
4. Data motor pada Dashboard dan halaman Profil Akun akan langsung diperbarui secara *real-time* dan tersimpan ke Supabase.

#### C. Pengujian Riwayat Servis (CRUD), Perhitungan Komponen & Status Selesai
1. **Menambah Catatan Servis (`Belum Selesai`)**:
   - Klik tombol **`+`** di pojok kanan bawah Dashboard (atau klik langsung salah satu kartu pada **Pantauan Komponen**, misalnya kartu **Oli Mesin**).
   - Pilih/ketik jenis servis: **`Oli Mesin`**.
   - Masukkan Odometer: **`2500`** km, Total Biaya: **`65000`**, Catatan: `Ganti oli rutin`.
   - Biarkan Status Servis pada **`Belum Selesai`**, lalu klik **Simpan catatan**.
   - **Hasil yang Terlihat**:
     - Pada daftar *Riwayat terbaru*, muncul catatan `Oli Mesin` dengan status `Belum Selesai`.
     - Pada kartu *Pantauan Komponen*, kartu **Oli Mesin** menyala **Merah (`Servis! / Waktunya ganti!`)** karena odometer sudah mencapai `2.500 km` tetapi status servisnya belum selesai.
2. **Menandai Servis Menjadi `Selesai`**:
   - Pada item riwayat `Oli Mesin` di bawah, klik ikon titik tiga (**`...`**) di sebelah kanan -> pilih **"Tandai Selesai"**.
   - **Perubahan Otomatis yang Terjadi**:
     - Ikon riwayat berubah menjadi **Centang Hijau (`✓`)** dengan keterangan *"Diselesaikan pada [Tanggal Hari Ini]"*.
     - Kartu **Oli Mesin** di *Pantauan Komponen* otomatis me-reset jadwal berikutnya menjadi **`5,000 km (+2,500)`** dengan keterangan **`Sekitar 2,500 km lagi`** (kondisi kembali normal).
3. **Menguji Pencarian (Search Bar)**:
   - Ketik kata kunci (misalnya `oli` atau `kampas rem`) pada kolom pencarian di bawah *Riwayat terbaru* untuk menyaring riwayat servis dan kartu komponen secara *real-time*.

#### D. Pengujian Notifikasi & Pengingat Servis (Advance Feature 2)
1. Buka tab **Notifikasi** di navigasi bawah.
2. Setiap kali Anda menambah riwayat servis baru atau ada komponen yang sisa jarak tempuhnya $\le 500\text{ km}$ / melewati batas kilometer, notifikasi otomatis tercatat di halaman ini.
3. **Uji Cepat (Simulasi Instan)**:
   - Klik ikon **Lonceng `+`** di pojok kanan atas AppBar pada halaman **Notifikasi** untuk memicu simulasi pengingat servis darurat secara instan.
   - Klik menu titik tiga (**`⋮`**) di pojok kanan atas untuk menguji fitur **Tandai Semua Dibaca**, **Hapus Semua Notifikasi**, dan **Kelola Izin Notifikasi**.

#### E. Pengujian Lokasi & Peta Bengkel Terdekat (Advance Feature 3)
1. Buka tab **Bengkel** di navigasi bawah.
2. Aplikasi secara otomatis mendeteksi lokasi kota/kecamatan Anda saat ini dan menampilkan daftar bengkel terdekat (Resmi Honda/AHASS, Resmi Yamaha, Bengkel Umum 24 Jam, dan Tambal Ban) beserta jarak kilometernya.
3. **Mengubah / Mencari Kota Secara Manual**:
   - Klik tombol **"Ubah"** pada label lokasi di pojok kiri bawah peta radar (atau klik ikon target GPS di pojok kanan atas).
   - Ketik nama kota/kecamatan Anda (misalnya: `Samarinda`, `Balikpapan`, `Surabaya`, `Bandung`, `Yogyakarta`) lalu klik **Cari**.
   - Daftar bengkel, alamat, dan perhitungan jarak tempuh (`km`) akan otomatis diperbarui mengikuti titik koordinat kota tersebut.
4. Klik tombol **"Rute Maps"** pada salah satu kartu bengkel untuk melihat tautan navigasi langsung ke Google Maps.


