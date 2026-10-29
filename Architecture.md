# Arsitektur Sistem — ServisKu (Mobile App)

Dokumen ini menjelaskan rancangan arsitektur berorientasi lapisan (*Layered Architecture*), integrasi *Vertical Slice*, tumpukan teknologi (*tech stack*), alur data, skema entitas, dan struktur direktori untuk aplikasi **ServisKu** berbasis Flutter.

---

## 1. Tumpukan Teknologi (Tech Stack)

Aplikasi ini dibangun menggunakan arsitektur multi-platform (*Cross-Platform Mobile & Web*) yang mengedepankan pemisahan tanggung jawab (*Separation of Concerns*), ketahanan data (*offline-first* dengan sinkronisasi REST API), serta pengujian otomatis menyeluruh.

- **Framework & Bahasa Pemrograman:** Flutter (SDK Dart ^3.13.4)
- **State Management:** `flutter_riverpod` (^3.4.3) berbasis `AsyncNotifier` dan `ProviderScope`
- **HTTP & API Networking:** `http` (^1.6.0) dengan abstraksi [ApiService](file:///c:/Users/USER/serviceku/lib/services/api_service.dart) (REST API Client + `SimulatedBackendClient`)
- **Penyimpanan Lokal (Persistence & Cache):** `shared_preferences` (^2.5.6) berbasis serialisasi JSON
- **Lokalisasi & Format Data:** `intl` (^0.20.3) untuk mata uang (Rupiah) dan format tanggal/angka
- **Testing Suite:** `flutter_test` dan `http/testing.dart` (`MockClient`)

---

## 2. Diagram Arsitektur & Vertical Slice

Aplikasi menerapkan pola arsitektur berlapis (*Clean Layered Architecture*) dengan implementasi *Vertical Slice* penuh:

```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   - DashboardScreen (Overview, Ringkasan, Riwayat)     │
│   - FormServisScreen (Input Servis, Validasi Form)     │
│   - FormMotorScreen (Profil Kendaraan Utama)           │
│   - ComponentsScreen (Manajemen Suku Cadang/Komponen)  │
│   (5 State: Loading, Empty, Error, Success, Retry)     │
└─────────────────────────┬──────────────────────────────┘
                          │ (watch / read)
                          ▼
┌────────────────────────────────────────────────────────┐
│               STATE MANAGEMENT LAYER                   │
│   - serviceHistoryProvider (ServiceHistoryNotifier)    │
│   - vehicleInfoProvider (VehicleInfoNotifier)          │
│   - serviceComponentsProvider (ServiceComponents)      │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│                   REPOSITORY LAYER                     │
│   - ServiceRepository (Single Source of Truth)         │
│   - Serialisasi / Deserialisasi & Sinkronisasi Cache   │
└───────────────────┬───────────────────┬────────────────┘
                    │                   │
      (HTTP REST API)                   (JSON Local Storage)
                    ▼                   ▼
┌───────────────────────────┐   ┌────────────────────────┐
│     REMOTE DATA SOURCE    │   │  LOCAL DATA SOURCE     │
│  - ApiService             │   │  - SharedPreferences   │
│  - GET /services (Load)   │   │  - Device / Browser    │
│  - POST /services (Save)  │   │    Local Storage       │
│  - PUT / DELETE           │   └────────────────────────┘
└───────────────────────────┘
```

---

## 3. Pembagian Tanggung Jawab Lapisan (Layer Responsibilities)

### A. Presentation Layer (`lib/screens/`)
Bertanggung jawab atas rendering visual, interaksi pengguna, dan penanganan feedback antarmuka:
- [dashboard_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/dashboard_screen.dart): Menampilkan ringkasan total pengeluaran servis, total pengerjaan, odometer terakhir, jadwal pemantauan komponen berkala, profil motor utama, serta daftar kartu riwayat servis. Menangani transisi 5 kondisi UI: **Loading**, **Empty State**, **Error State**, **Success State**, dan tombol **Retry** ("Coba Lagi").
- [form_service_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/form_service_screen.dart): Form modal untuk menambah dan mengedit catatan servis, validasi input (*required fields*, format angka), dan *submit loading* untuk mencegah *double tap*.
- [form_motor_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/form_motor_screen.dart): Modal bottom sheet untuk mengelola profil motor utama (nama kendaraan, nomor plat, dan tahun pembuatan).
- [components_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/components_screen.dart): Manajemen suku cadang berkala (Oli Mesin, Oli Gardan, Busi, Filter Udara, Kampas Rem, CVT, Coolant, serta komponen kustom) dan kalkulasi interval km terhadap odometer saat ini.

### B. State Management Layer (`lib/providers/`)
Menggunakan Riverpod dengan pendekatan `AsyncNotifier` untuk mengelola state asinkron secara reaktif:
- `serviceHistoryProvider` ([ServiceHistoryNotifier](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart)): Mengelola state riwayat servis (Read, Create, Update, Delete) serta menangani error melalui `AsyncValue.guard`.
- `vehicleInfoProvider` ([VehicleInfoNotifier](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart)): Mengelola profil motor utama.
- `serviceComponentsProvider` ([ServiceComponentsNotifier](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart)): Mengelola daftar komponen dan pemantauan jarak tempuh servis berkala.

### C. Repository Layer (`lib/repositories/`)
- [service_repository.dart](file:///c:/Users/USER/serviceku/lib/repositories/service_repository.dart): Berperan sebagai jembatan (*Single Source of Truth*) yang mengabstraksi sumber data dari Notifier dan UI. Menghubungkan pemanggilan ke remote [ApiService](file:///c:/Users/USER/serviceku/lib/services/api_service.dart) saat online dan menyinkronkan data ke penyimpanan lokal [SharedPreferences](https://pub.dev/packages/shared_preferences).

### D. Remote API Layer (`lib/services/`)
- [api_service.dart](file:///c:/Users/USER/serviceku/lib/services/api_service.dart):
  - Mengelola komunikasi HTTP REST API (GET, POST, PUT, DELETE) menggunakan `http.Client`.
  - Menerapkan error handling ketat: melempar `ApiException` pada kegagalan HTTP (500, 404) dan `FormatException` pada payload JSON rusak.
  - Memiliki `SimulatedBackendClient` (`http.BaseClient`) untuk menjalankan aplikasi secara mandiri (*offline demo*) dengan delay realistis (50 ms) tanpa memerlukan backend fisik eksternal saat presentasi.

### E. Local Persistence Layer (`shared_preferences`)
Menyimpan serialized JSON string pada storage lokal perangkat atau browser:
- `servisku_service_history_v1`: Catatan riwayat servis kendaraan.
- `servisku_vehicle_info_v1`: Informasi profil motor utama.
- `servisku_service_components_v1`: Daftar komponen servis berkala & kustom.

---

## 4. Skema Entitas Data Model (`lib/models/`)

### A. Model `ServiceHistory`
```dart
class ServiceHistory {
  final String id;              // ID unik (UUID / Timestamp)
  final String jenisServis;     // Nama/jenis pengerjaan servis
  final int odometer;           // Odometer kendaraan saat servis (km >= 0)
  final int totalBiaya;         // Biaya servis dalam Rupiah (>= 0)
  final DateTime createdAt;     // Waktu pencatatan
  final DateTime? completedAt;  // Waktu servis diselesaikan
  final String status;          // 'Selesai' | 'Belum Selesai'
  final String? catatan;        // Catatan tambahan / spare part
}
```
Dilengkapi dengan `isValid`, `validate()`, `toMap()`, `fromMap()`, `toJson()`, dan `fromJson()`.

### B. Model `VehicleInfo`
```dart
class VehicleInfo {
  final String namaMotor;   // Contoh: 'Honda Vario 160'
  final String platNomor;   // Contoh: 'B 1234 XYZ'
  final int tahun;          // Contoh: 2024
}
```

### C. Model `ServiceComponent`
```dart
class ServiceComponent {
  final String id;          // ID unik komponen
  final String nama;        // Nama komponen (misal: 'Oli Mesin')
  final int intervalKm;     // Rekomendasi interval servis (km)
  final String deskripsi;   // Keterangan / tips servis
  final bool isCustom;      // true jika ditambahkan pengguna secara mandiri
}
```

---

## 5. Struktur Direktori Proyek

```text
serviceku/
├── docs/
│   ├── Architecture.md                        # Dokumentasi arsitektur sistem
│   ├── Integrasi API dan Vertical Slice.md   # Panduan tugas integrasi API & 6 unit test
│   ├── State Management.md                    # Dokumentasi state management (Riverpod)
│   └── penjelasan_tugas.md                    # Dokumentasi tugas persistensi lokal
│
├── lib/
│   ├── main.dart                              # Root entry point & inisialisasi SharedPreferences
│   │
│   ├── models/                                # Lapisan model entitas & validasi
│   │   ├── service_history.dart               # Model riwayat servis
│   │   ├── vehicle_info.dart                  # Model profil kendaraan
│   │   └── service_component.dart             # Model komponen & interval servis
│   │
│   ├── providers/                             # Lapisan Riverpod State Notifiers
│   │   └── service_provider.dart              # Providers & AsyncNotifiers
│   │
│   ├── repositories/                          # Lapisan Repository Data Orchestration
│   │   └── service_repository.dart            # Abstraksi data API & Local Storage
│   │
│   ├── services/                              # Lapisan REST API Client
│   │   └── api_service.dart                   # ApiService, ApiException, SimulatedBackendClient
│   │
│   └── screens/                               # Lapisan Antarmuka Pengguna (UI)
│       ├── dashboard_screen.dart              # Layar utama (ringkasan, riwayat, status)
│       ├── form_service_screen.dart           # Modal tambah & edit riwayat servis
│       ├── form_motor_screen.dart             # Modal edit profil motor
│       └── components_screen.dart             # Layar kelola komponen servis berkala
│
├── test/                                      # Pengujian Otomatis (Automated Testing)
│   ├── api_unit_test.dart                     # 6 Unit Test: Model Valid, Invalid, API Sukses, Kosong, Gagal, Rusak
│   ├── unit_test.dart                         # Unit test Riverpod Notifiers
│   ├── widget_test.dart                       # 11 Widget tests (Loading, Empty, Error, Retry, Submit, Form)
│   └── persistence_test.dart                  # 11 Persistence tests (Cold restart & storage persistence)
│
├── pubspec.yaml                               # Konfigurasi dependensi proyek
└── run_web.bat                                # Script menjalankan Web dengan Chrome data profile persisten
```

---

**Hasil Eksekusi Keseluruhan:**
```powershell
flutter test
# 00:10 +36: All tests passed! (100% Lulus)
```
