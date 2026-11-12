# Dokumentasi Test dan Refactor (Avoid Code Duplication & Separation of Concerns)

Dokumen ini menjelaskan proses **Test dan Refactor** pada proyek **ServisKu** untuk memastikan kode bersih dari duplikasi (*Don't Repeat Yourself / DRY*) serta menerapkan pemisahan tanggung jawab (*Single Responsibility Principle / Separation of Concerns*) menjadi fungsi-fungsi kecil yang fokus pada pekerjaannya masing-masing.

---

## 1. Tujuan Refactoring

1. **Menghindari Duplikasi Kode (Zero Code Duplication)**:
   - Menghilangkan duplikasi aturan validasi form yang sebelumnya ditulis berulang secara *inline* di berbagai layar.
   - Menghilangkan duplikasi dekorasi `TextFormField` (`InputDecoration`) pada formulir kendaraan dan formulir servis.
   - Menghilangkan duplikasi rumus perhitungan jadwal servis komponen (`lastServicedKm`, `nextServiceKm`, `kmRemaining`, `isOverdue`, `isWarning`, `progress`) yang sebelumnya berulang di 4 tempat berbeda.
2. **Pemisahan Tanggung Jawab (Separation of Concerns)**:
   - **`ProfileForm`**: Hanya fokus menangani input pengguna dan status UI (loading & pesan feedback `SnackBar`).
   - **`validation`**: Hanya fokus menangani aturan validasi input sebagai fungsi murni (*pure functions*).
   - **`profileRepository`**: Hanya fokus menangani request API ke Supabase Cloud dan penyimpanan cache lokal (`SharedPreferences`).

---

## 2. Struktur Pemisahan Tanggung Jawab

```
lib/
├── screens/
│   ├── form_motor_screen.dart       # ProfileForm: Input & Status UI
│   ├── form_service_screen.dart     # FormServisScreen: Input & Status UI Servis
│   ├── components_screen.dart       # UI Daftar Komponen
│   └── dashboard_screen.dart        # UI Dashboard Utama
├── utils/
│   ├── validation.dart              # validation: Aturan Input (Pure Functions)
│   └── component_calculator.dart    # Kalkulator Jadwal Komponen Terpusat (DRY)
└── repositories/
    ├── profile_repository.dart      # profileRepository: Request API & Storage Profil Motor
    └── service_repository.dart      # Delegasi Profil ke ProfileRepository & CRUD Servis
```

### A. `ProfileForm` — Input dan Status UI (`lib/screens/form_motor_screen.dart`)
Widget `ProfileForm` (beserta alias kompatibilitas `FormMotorScreen`) dipecah menjadi fungsi-fungsi kecil yang masing-masing hanya mengerjakan satu tugas spesifik:
- `_initControllers()`: Menginisialisasi `TextEditingController` dari data kendaraan saat ini.
- `_buildUpdatedVehicle()`: Merakit objek `VehicleInfo` dari nilai input yang telah di-*trim* dan diformat.
- `_setLoadingStatus(bool isLoading)`: Mengubah state `_isLoading` untuk menonaktifkan tombol dan menampilkan indikator loading saat proses simpan berlangsung.
- `_showStatusSnackBar(String message, {bool isError})`: Menampilkan feedback visual (`SnackBar` hijau saat sukses, merah saat gagal).
- `_buildInputField(...)`: Fungsi pembangun `TextFormField` reusable untuk mencegah duplikasi kode `InputDecoration` pada field **Nama / Tipe Motor**, **Plat Nomor Kendaraan**, dan **Tahun Pembuatan**.
- `_buildHeader()` & `_buildActionButtons()`: Memisahkan pembuatan UI header modal dan tombol aksi (**Batal** & **Simpan Perubahan**).

### B. `validation` — Aturan Input (`lib/utils/validation.dart`)
Kelas `FormValidation` berisi fungsi-fungsi statis murni (*pure functions*) yang tidak bergantung pada `BuildContext` maupun widget Flutter, sehingga sangat mudah diuji secara terisolasi (*unit testable*):
- **Validasi Profil Kendaraan (`ProfileForm`)**:
  - `validateNamaMotor(String? value)` — Memastikan nama/tipe motor tidak kosong.
  - `validatePlatNomor(String? value)` — Memastikan plat nomor kendaraan tidak kosong.
  - `validateTahun(String? value)` — Memastikan tahun berupa angka valid pada rentang `1900 - 2100`.
- **Validasi Akun & Autentikasi (`LoginScreen`)**:
  - `validateNamaLengkap(String? value)` — Memastikan nama lengkap terisi saat registrasi.
  - `validateEmail(String? value)` — Memastikan format email valid (`@` dan `.`).
  - `validatePassword(String? value)` — Memastikan kata sandi minimal 6 karakter.
- **Validasi Catatan Servis & Komponen (`FormServisScreen` & `ComponentsScreen`)**:
  - `validateJenisServis(String? value)` — Memastikan jenis servis tidak kosong.
  - `validateOdometer(String? value)` & `validateTotalBiaya(String? value)` — Memastikan input berupa angka bulat non-negatif (`_validateNonNegativeInt`).
  - `validateNamaKomponen(String? value)` & `validateIntervalKm(String? value)` — Memastikan nama komponen terisi dan interval km `> 0`.

### C. `profileRepository` — Request API (`lib/repositories/profile_repository.dart`)
Kelas `ProfileRepository` bertanggung jawab penuh atas komunikasi data profil kendaraan ke backend Supabase (`vehicle_info`) maupun penyimpanan lokal (`SharedPreferences`):
- `fetchVehicleInfo([String? userEmail])`: Mengoordinasikan pengambilan data dari cloud dengan *fallback* ke penyimpanan lokal.
- `saveVehicleInfo(VehicleInfo info, [String? userEmail])`: Mengoordinasikan penyimpanan ke cloud dan pembaruan cache lokal.
- `_fetchVehicleFromCloud([String? userEmail])`: Menjalankan query `SELECT` ke tabel `vehicle_info` di Supabase.
- `_saveVehicleToCloud(VehicleInfo info, [String? userEmail])`: Menjalankan request `UPSERT` ke tabel `vehicle_info` di Supabase.
- `_fetchVehicleFromLocal()` & `_saveVehicleToLocal(VehicleInfo info)`: Membaca dan menulis JSON `VehicleInfo` ke `SharedPreferences`.
- `mapCloudRowToVehicle(Map<String, dynamic> item)` & `buildVehiclePayload(...)`: Fungsi kecil khusus pemetaan respons API dan pembuatan payload JSON request.

### D. Penghapusan Duplikasi Kalkulasi Jadwal (`lib/utils/component_calculator.dart`)
Sebelumnya, perhitungan status komponen (`lastServicedKm`, `nextServiceKm`, `kmRemaining`, `isOverdue`, `isWarning`, `progress`) ditulis ulang di 4 lokasi (`DashboardScreen._buildComponentCard`, `DashboardScreen._buildTopRightCard`, `ComponentsScreen.build`, dan `NotificationNotifier.evaluateServiceReminders`).
Kini seluruhnya dipusatkan ke `ComponentCalculator.evaluate(...)` dengan fungsi-fungsi kecil:
- `findCompletedServices(...)`
- `hasPendingService(...)`
- `calculateNextServiceKm(...)`
- `calculateKmRemaining(...)`
- `calculateProgress(...)`

---

## 3. Alur Kerja Refactoring (4 Tahap)

Proses refactoring dilakukan secara bertahap dan terukur mengikuti siklus 4 langkah:

| Tahap | Langkah | Deskripsi Aktivitas |
| :---: | :--- | :--- |
| **1** | **Tes Awal Lulus** | Menjalankan seluruh suite pengujian (`flutter test`) sebelum perubahan dilakukan untuk memastikan kondisi *baseline* hijau (semua tes lulus). |
| **2** | **Pindahkan Satu Bagian** | Mengekstrak satu tanggung jawab dalam satu waktu: dimulai dari `FormValidation` (`lib/utils/validation.dart`), dilanjutkan `ProfileRepository` (`lib/repositories/profile_repository.dart`), `ComponentCalculator` (`lib/utils/component_calculator.dart`), hingga merampingkan `ProfileForm` (`lib/screens/form_motor_screen.dart`). |
| **3** | **Tes Ulang** | Menjalankan kembali `flutter test` setiap kali satu bagian selesai dipindahkan, serta menambahkan unit test khusus untuk memverifikasi fungsi-fungsi baru yang diekstrak. |

---

## 4. Cakupan Pengujian (Test Suite)

Seluruh hasil refactoring diverifikasi oleh 4 file pengujian otomatis di direktori `test/`:

1. **`test/unit_test.dart`**:
   - Menguji state management `ServiceHistoryNotifier` & `ServiceComponentsNotifier`.
   - Menguji fungsi validasi terpisah di `FormValidation` (`validateNamaMotor`, `validatePlatNomor`, `validateTahun`, `validateJenisServis`, `validateOdometer`, `validateTotalBiaya`, `validateIntervalKm`).
   - Menguji `ProfileRepository` (`saveVehicleInfo` & `fetchVehicleInfo`).
   - Menguji `ComponentCalculator.evaluate` untuk kondisi normal dan *overdue*.
2. **`test/api_unit_test.dart`**:
   - Menguji integrasi API & penanganan respons HTTP (`200 OK`, `201 Created`, data kosong `[]`, error `404`/`500` `ApiException`, serta JSON rusak `FormatException`).
3. **`test/persistence_test.dart`**:
   - Menguji ketahanan penyimpanan lokal (`SharedPreferences`) saat simulasi aplikasi ditutup dan dibuka kembali (*cold restart*) untuk riwayat servis, `VehicleInfo`, dan komponen kustom.
4. **`test/widget_test.dart`**:
   - Menguji tampilan UI `DashboardScreen`, `FormServisScreen`, dan `ProfileForm` (`FormMotorScreen`), termasuk interaksi pengguna mengedit nama motor dan memverifikasi pembaruan di layar utama.

### Cara Menjalankan Pengujian

```powershell
# Menjalankan seluruh pengujian (Unit, API, Persistence, dan Widget Test)
flutter test

# Menjalankan pengujian spesifik untuk unit test & hasil refactoring
flutter test test/unit_test.dart
```

