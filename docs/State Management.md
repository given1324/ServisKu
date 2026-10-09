# P4 — Service History State Management

## Tujuan Feature
Feature Catatan Kendaraan (Service History) menerapkan form dan state management dengan Riverpod. Implementasi awal P4 ini menggunakan repository dengan simulasi delay/penyimpanan lokal untuk mendemonstrasikan alur data asinkron sebelum nantinya diintegrasikan dengan database sungguhan.

## Arsitektur
- **DashboardScreen & FormServisScreen** (widget/UI)
  → **ServiceHistoryNotifier** (Riverpod state controller)
  → **ServiceRepository** (data abstraction & in-memory/local storage)

**Lokasi kode:**
- `lib/screens/dashboard_screen.dart` — UI, list riwayat servis, kondisi state asinkron, dan integrasi state.
- `lib/screens/form_service_screen.dart` — UI, form tambah/edit catatan servis, validasi form, dan state submit loading.
- `lib/providers/service_provider.dart` — State loading, data, empty, error, retry, dan submit (notifier).
- `lib/repositories/service_repository.dart` — Kontrak repository dan simulasi data/penyimpanan lokal.
- `lib/models/service_history.dart` — Entity dan struktur data input.

## Kondisi, Tampilan, Test

| Kondisi | Tampilan | Test |
|---|---|---|
| **Initial loading** | `CircularProgressIndicator` ketika repository memuat data awal | `shows initial loading while service data is fetched` |
| **Data berhasil dimuat** | Daftar kartu riwayat servis, ringkasan pengeluaran, dan informasi odometer | `shows loaded data when a service history exists` |
| **Empty state** | Pesan "Belum ada riwayat servis" dan instruksi untuk menambah data baru | `shows empty state when no service history has been saved` |
| **Error + retry** | Pesan gagal memuat dan tombol "Coba Lagi" | `shows error state and retry loads the service history again` |
| **Validasi form** | Jenis servis wajib diisi, serta odometer dan biaya harus berupa angka valid | `validates required fields and number formats` |
| **Loading submit** | Tombol "Simpan catatan" menampilkan loading dan ter-disable agar tidak double tap | `shows submit loading and prevents a double submit` |


## Hasil Verifikasi
**Perintah yang dijalankan:**
```powershell
flutter test test/widget_test.dart
```

**Hasil pada 9 Oktober 2026:**
```plaintext
00:06 +1: All tests passed!
```

## AI Usage Record — P4

**Tool**
Gemini & Antigravity AI Assistant digunakan untuk membantu membuat boilerplate Riverpod, menyusun struktur komponen UI, serta melakukan review logika state management.

**Prompt yang Digunakan**
"Tugas Anda adalah membuat satu feature Flutter yang menerapkan state management, form, dan validasi secara nyata. Feature wajib memiliki minimal enam kondisi UI: initial loading, data berhasil dimuat, empty state, error state dengan tombol retry, validasi input pada form, serta loading saat proses submit agar pengguna tidak dapat melakukan double tap. Gunakan state management yang konsisten, misalnya Riverpod, dan pisahkan tanggung jawab antara widget, notifier/use case, serta repository. Sertakan widget test untuk setiap state utama dan dokumentasikan hasilnya dengan screenshot atau video singkat. Anda boleh menggunakan Codex atau Gemini untuk membantu membuat boilerplate, test, atau melakukan review kode, tetapi Anda tetap wajib memahami, menjelaskan, dan bertanggung jawab atas kode yang dikumpulkan; cantumkan prompt AI yang digunakan serta bagian kode yang Anda periksa atau perbaiki sendiri."

**Bagian yang Ditinjau dan Diperbaiki Sendiri**
- Memilih feature Catatan Kendaraan (Dashboard & Form Servis) karena ini merupakan fungsionalitas inti dari aplikasi ServisKu.
- Mengontrol penggunaan `AsyncValue.guard` pada `service_provider.dart` untuk memastikan UI tidak crash ketika repository melempar exception saat memuat atau memutasi data.
- Memvalidasi penggunaan `GlobalKey<FormState>` dan pemisahan state lokal `_isLoading` di dalam StatefulWidget (`FormServisScreen`), sehingga tombol benar-benar nonaktif saat proses asinkron (penyimpanan data) berjalan.
- Mengembangkan logika tambahan untuk pengelompokan UI secara modern (menggunakan `CustomScrollView` & `SliverList`) dan menerapkan Optimistic UI Update pada state saat menambah atau menghapus servis, agar antarmuka merespons tanpa jeda loading.
- Menjalankan ulang widget test di terminal sampai hasil pengujian UI menyatakan lulus (*All tests passed!*).

## Tanggung Jawab Mahasiswa
Mahasiswa perlu dapat menjelaskan alur Widget → Notifier → Repository, alasan membungkus root aplikasi dengan `ProviderScope` di `main.dart`, serta mekanisme penonaktifan tombol (*disabled state*) saat proses submit berlangsung untuk mencegah pengiriman data berulang.
