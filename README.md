# ServisKu - Mobile Vehicle Service Tracker App 🏍️

## Deskripsi Masalah
Banyak pemilik kendaraan bermotor (terutama mahasiswa, pekerja harian, dan pengguna komuter) kesulitan mempertahankan konsistensi dan keteraturan servis berkala pada sepeda motor mereka. Kegagalan perawatan ini sering terjadi karena mereka tidak memiliki alat pencatat riwayat servis yang praktis dan tidak adanya dorongan visual (seperti indikator status keausan suku cadang dan estimasi jadwal servis) untuk memotivasi mereka melakukan perawatan tepat waktu. Selain itu, kartu catatan servis konvensional berbahan kertas dari bengkel sering kali hilang, basah, sobek, atau lupa dibawa saat berada di bengkel. Akibatnya, pemilik tidak mengetahui riwayat jarak tempuh (*odometer*) servis terakhir, penggantian suku cadang menjadi terlambat, dan mesin kendaraan berisiko tinggi mengalami kerusakan fatal dengan biaya perbaikan yang membengkak.

## Profil Target Pengguna
1.Pengguna Utama: Pemilik kendaraan bermotor, khususnya mahasiswa, pekerja, atau anak kos.

2.Karakteristik: Membutuhkan catatan digital yang cepat dibuka lewat HP saat sedang berada di bengkel untuk mengecek riwayat servis sebelumnya.
## Manfaat Aplikasi
1.Menjadi buku riwayat servis digital pribadi yang aman dan tidak akan hilang.
2.Memudahkan pengguna melihat riwayat kilometer (odometer) terakhir saat servis.
3.Membantu menjaga kondisi kendaraan tetap prima karena perawatan menjadi lebih terpantau.

## Daftar Fitur Inti
> *Target penyelesaian dalam 12 pertemuan.*

1. **Manajemen Riwayat Servis (CRUD):** Fitur lengkap untuk menambah (*Create*), membaca (*Read*), mengedit (*Update*), dan menghapus (*Delete*) catatan servis kendaraan dengan validasi form (Odometer km, Jenis Servis, Total Biaya, Tanggal Servis, dan Catatan Tambahan) serta proteksi *double-submit*.
2. **Manajemen Komponen Servis Kustom:** Fleksibilitas bagi pengguna untuk menambah, mengedit, dan menghapus komponen servis baru (misalnya kampas rem, filter udara, v-belt CVT, aki) dengan interval kilometer yang dapat ditentukan secara mandiri.
3. **Pengelolaan Profil Kendaraan Utama:** Fitur untuk mencatat dan mengubah profil motor pengguna (Nama Motor, Nomor Plat Kendaraan, dan Tahun Pembuatan) langsung dari antarmuka *dashboard*.
4. **Penyimpanan Data Lokal Permanen (Local Persistence):** Penggunaan arsitektur penyimpanan lokal (`shared_preferences`) yang menjamin seluruh catatan riwayat, komponen kustom, dan profil motor tersimpan permanen serta tidak hilang saat aplikasi ditutup atau perangkat di-*restart* (*offline-first*).

## Fitur yang Tidak Dikerjakan
1. **Integrasi Remote Push Notifications Server:** Tidak menggunakan server push notifikasi pihak ketiga (seperti Firebase Cloud Messaging / OneSignal) untuk menjaga arsitektur aplikasi tetap mandiri di perangkat lokal pengguna.
2. **Fitur Unggah Foto Nota Bengkel:** Semua pencatatan difokuskan pada teks, tanggal, kilometer, dan angka biaya agar aplikasi tetap ringan, responsif, dan hemat ruang memori penyimpanan perangkat.
3. **Integrasi Peta Lokasi Bengkel (Google Maps API):** Fokus pengembangan murni pada pencatatan dan estimasi perawatan kendaraan pribadi pengguna, bukan sebagai direktori pencarian lokasi bengkel.

## Kriteria Aplikasi Dinyatakan Berhasil
1.Pengguna dapat menambah, mengedit, dan menghapus catatan riwayat servis kendaraannya tanpa error.

2.Daftar riwayat servis tampil berurutan dan akurat sesuai data yang dimasukkan pengguna.

3.Data pengguna satu dengan pengguna lainnya terpisah dengan aman (tidak saling bercampur).

4.Tampilan web ringan, tidak rumit, dan sangat nyaman dibaca lewat layar smartphone.