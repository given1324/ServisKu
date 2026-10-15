# ServisKu 🏍️

Aplikasi pencatatan dan pelacakan riwayat servis berkala kendaraan bermotor dengan dukungan **Local Data & Persistence** serta State Management berbasis **Riverpod**.

## ✨ Fitur Utama
- **Local Data & Persistence**: Data riwayat servis tersimpan permanen di perangkat lokal menggunakan `shared_preferences`. Data tetap aman saat aplikasi ditutup atau browser di-refresh.
- **CRUD Penuh**:
  - **Create**: Tambah catatan servis baru dengan validasi form.
  - **Read**: Tampilkan daftar riwayat servis, total biaya, dan odometer kendaraan.
  - **Update**: Edit rincian catatan servis dan ubah status pengerjaan (Belum Selesai / Selesai).
  - **Delete**: Hapus catatan servis dengan dialog konfirmasi.
- **Modern UI**: Dashboard interaktif dengan kalkulasi statistik otomatis, card riwayat modern, dan pull-to-refresh.
- **State Management**: Dibangun menggunakan `AsyncNotifier` dari `flutter_riverpod` dengan pemisahan tanggung jawab yang jelas.

## 🚀 Menjalankan Aplikasi
```powershell
# Mengambil dependensi
flutter pub get

# Menjalankan aplikasi di Web (Chrome dengan data persisten)
.\run_web.bat
# atau manual:
flutter run -d chrome --web-port=5000 --web-browser-flag="--user-data-dir=.chrome_data"
```

## 🧪 Menjalankan Pengujian (Tests)
```powershell
flutter test
```
Seluruh pengujian mencakup:
1. `test/persistence_test.dart` — Pengujian persistensi, serialisasi/deserialisasi, dan simulasi cold restart.
2. `test/unit_test.dart` — Pengujian logika notifier dan repository.
3. `test/widget_test.dart` — Pengujian antarmuka dan interaksi pengguna.

## 📖 Dokumentasi Tugas
Rincian penjelasan pemenuhan tugas mahasiswa dapat dilihat pada:
- [docs/penjelasan_tugas.md](docs/penjelasan_tugas.md)
- [Architecture.md](Architecture.md)
