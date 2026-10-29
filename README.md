# ServisKu - Buku Riwayat Perawatan Motor Digital

## Deskripsi Masalah
Banyak pemilik kendaraan bermotor, khususnya sepeda motor yang digunakan untuk aktivitas harian, menghadapi kendala dalam mengingat jadwal perawatan berkala seperti waktu penggantian oli mesin, kampas rem, busi, maupun servis transmisi. Selama ini, pencatatan servis masih mengandalkan buku servis manual atau kartu kertas dari bengkel yang sangat rentan hilang, robek, basah, atau tertinggal saat pengguna sedang berada di bengkel. 

Ketiadaan catatan riwayat yang teratur ini sering kali mengakibatkan pengguna terlambat melakukan perawatan, yang pada akhirnya memicu kerusakan mesin mendadak, penurunan performa kendaraan, dan pembengkakan biaya perbaikan yang tidak terduga.

---

## Profil Target Pengguna
Aplikasi ini ditujukan bagi:
* **Pengguna Utama**: Pemilik dan pengendara sepeda motor harian, khususnya mahasiswa, pekerja kantor, dan anak kos yang memiliki mobilitas tinggi dan rutinitas padat.
* **Karakteristik & Kebutuhan Pengguna**: Pengguna yang menginginkan kepraktisan dan kecepatan akses melalui smartphone untuk mengecek riwayat kilometer (odometer) terakhir serta riwayat penggantian suku cadang saat mekanik bengkel menanyakan perawatan sebelumnya. Pengguna juga membutuhkan catatan riwayat pengeluaran perawatan yang rapi dan transparan.

---

## Manfaat Aplikasi
Hadirnya ServisKu memberikan berbagai manfaat nyata bagi pemilik kendaraan, antara lain:
* **Buku Servis Digital yang Aman**: Menggantikan kartu kertas konvensional dengan basis data digital yang tersimpan aman di cloud sehingga catatan riwayat servis tidak akan pernah hilang atau rusak.
* **Perawatan Kendaraan Terpantau Tepat Waktu**: Membantu menjaga kondisi mesin dan komponen vital motor tetap prima karena estimasi jarak tempuh dan interval servis berkala terpantau dengan jelas.
* **Transparansi Pengeluaran Keuangan**: Memudahkan pengguna mengetahui akumulasi total biaya yang telah dikeluarkan untuk perawatan motor sehingga pengelolaan anggaran bulanan menjadi lebih terencana.
* **Akses Praktis di Mana Saja**: Riwayat servis dapat dibuka dan diperbarui langsung dari smartphone saat berada di bengkel, bahkan tetap dapat diakses saat koneksi internet sedang tidak stabil berkat dukungan penyimpanan lokal.

---

## Daftar Fitur Inti
Aplikasi ini menyediakan serangkaian fitur fungsional yang saling terintegrasi:

1. **Autentikasi Akun & Rute Terproteksi**: 
   Sistem mewajibkan pengguna untuk melakukan login sebelum dapat masuk ke dashboard utama. Mendukung login menggunakan Email dan Kata Sandi terdaftar serta opsi login menggunakan akun Gmail. Pengguna baru dapat mendaftarkan akun secara mandiri melalui menu registrasi, dan sesi login akan tersimpan otomatis secara persisten.

2. **Pengelolaan Informasi Motor Utama**:
   Menampilkan kartu identitas kendaraan pengguna yang memuat nama dan tipe motor, nomor polisi (plat kendaraan), tahun perakitan, angka odometer terakhir, serta tanggal pembuatan akun pengguna. Data motor ini dapat diperbarui kapan saja melalui formulir pengeditan.

3. **Pencatatan Riwayat Servis (CRUD Lengkap)**:
   Fasilitas formulir untuk mencatat riwayat servis baru yang mencakup angka kilometer (odometer), jenis servis yang dilakukan, rincian total biaya, status pengerjaan, dan catatan tambahan. Pengguna dapat membaca daftar riwayat secara kronologis, mengedit riwayat yang sudah ada, maupun menghapus catatan yang keliru melalui dialog konfirmasi keamanan.

4. **Pemantauan Jadwal Komponen Berkala**:
   Fitur visualisasi status suku cadang utama (seperti Oli Mesin, Kampas Rem, Busi, Filter Udara, dan CVT) yang dilengkapi indikator progres jarak tempuh. Sistem secara otomatis memberikan peringatan apabila sisa kilometer mendekati jadwal servis atau telah melewati batas interval (*overdue*), serta menyediakan opsi untuk menambahkan komponen kustom baru.

5. **Ringkasan Finansial Perawatan**:
   Menghitung secara otomatis total akumulasi biaya pengeluaran servis serta jumlah frekuensi servis yang telah diselesaikan oleh pengguna.

6. **Fitur Lanjutan (Notifikasi & Lokasi Bengkel)**:
   Menyediakan notifikasi pengingat otomatis saat kendaraan mendekati batas servis berkala, serta peta/daftar penunjuk lokasi bengkel resmi dan umum terdekat berbasis GPS beserta estimasi jaraknya.

---

## Fitur yang Tidak Dikerjakan
Untuk menjaga agar ruang lingkup proyek tetap fokus, efisien, dan memiliki kinerja aplikasi yang ringan, beberapa hal berikut tidak diimplementasikan:
1. **Pengiriman Notifikasi Eksternal Berbayar**: Sistem tidak menggunakan layanan pengiriman pesan otomatis melalui SMS Gateway berbayar maupun broadcast pesan WhatsApp pihak ketiga.
2. **Unggah Foto / Berkas Nota Fisik**: Aplikasi tidak menyediakan fitur unggah gambar nota bengkel untuk menjaga efisiensi penyimpanan database, sehingga seluruh pencatatan difokuskan pada teks dan angka terstruktur.
3. **Pemesanan / Booking Antrean Servis Terintegrasi**: Aplikasi tidak terhubung langsung dengan sistem reservasi antrean bengkel resmi eksternal.
4. **Gerbang Pembayaran Digital (In-App Payment)**: Aplikasi tidak menyediakan transaksi pembayaran nontunai langsung di dalam aplikasi; transaksi servis tetap diselesaikan pengguna secara langsung di bengkel.

---

## Kriteria Aplikasi Dinyatakan Berhasil
Aplikasi ServisKu dinyatakan berhasil memenuhi tujuan pengembangannya apabila:
1. **Fungsionalitas CRUD Berjalan Tanpa Kendala**: Pengguna dapat menambah, melihat, memperbarui, dan menghapus catatan riwayat servis maupun data kendaraan tanpa menimbulkan error atau kegagalan sistem.
2. **Penyimpanan Data Terpusat & Aman**: Seluruh data tersimpan secara persisten ke cloud database PostgreSQL Supabase dengan penerapan Row Level Security (RLS) berbasis `auth.uid()`, sehingga data setiap pengguna terisolasi dengan aman dan tidak saling bercampur.
3. **Proteksi Akses Terjamin**: Mekanisme rute terproteksi berjalan dengan benar, di mana pengguna yang belum login tidak dapat mengakses halaman dalam dashboard, dan sesi login pengguna tetap terjaga saat aplikasi ditutup dan dibuka kembali.
4. **Antarmuka Nyaman & Responsif**: Tampilan antarmuka berjalan lancar, mudah digunakan di layar smartphone, serta didukung sistem penyimpanan lokal (*caching*) agar data riwayat tetap dapat dibuka meskipun saat pengguna berada di area bengkel dengan sinyal internet yang lemah.
