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

