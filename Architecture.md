# Architecture Documentation — ServisKu

## Overview
ServisKu menerapkan arsitektur berorientasi lapisan (*layered architecture*) yang memisahkan tanggung jawab antara antarmuka (Presentation Layer), manajemen state (State Management Layer), abstraksi data (Repository Layer), dan penyimpanan persisten lokal (Data/Persistence Layer).

```
┌────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                   │
│   - DashboardScreen (Overview, summary, list riwayat)  │
│   - FormServisScreen (Input form, validasi, edit)      │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│               STATE MANAGEMENT LAYER                   │
│   - Riverpod AsyncNotifier (ServiceHistoryNotifier)    │
│   - serviceHistoryProvider (UI reactive binding)       │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│                   REPOSITORY LAYER                     │
│   - ServiceRepository (Kontrak & orkestrasi data)      │
│   - JSON Serialization / Deserialization               │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│               LOCAL PERSISTENCE LAYER                  │
│   - SharedPreferences ('servisku_service_history_v1')  │
│   - Device / Browser local file storage                │
└────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer (`lib/screens/`)
- `dashboard_screen.dart`: Menampilkan data riwayat servis, kalkulasi total pengeluaran, total servis, odometer terbaru, banner jadwal komponen, dan profil motor utama dengan aksi edit cepat.
- `form_service_screen.dart`: Menangani input data servis baru dan pengeditan data riwayat servis. Memiliki pilihan cepat (quick chips) dari komponen terdaftar, validasi input, dan proteksi *double-tap submit*.
- `form_motor_screen.dart`: Modal bottom sheet untuk mengedit profil motor utama (nama/tipe motor, plat nomor, tahun pembuatan).
- `components_screen.dart`: Manajemen komponen servis berkala (Oli Mesin, Oli Gardan, Busi, Filter Udara, Kampas Rem, CVT, Coolant, serta komponen kustom baru), memantau interval km terhadap odometer saat ini, dan tombol langsung 'Catat Servis'.

### 2. State Management Layer (`lib/providers/`)
- Menggunakan `flutter_riverpod` dengan pendekatan `AsyncNotifier`.
- `serviceHistoryProvider` (`ServiceHistoryNotifier`): Mengelola daftar riwayat servis kendaraan (CRUD).
- `vehicleInfoProvider` (`VehicleInfoNotifier`): Mengelola state profil motor utama secara reaktif.
- `serviceComponentsProvider` (`ServiceComponentsNotifier`): Mengelola daftar komponen servis berkala (CRUD komponen kustom dan status interval).

### 3. Repository Layer (`lib/repositories/`)
- `service_repository.dart`: Bertindak sebagai Single Source of Truth bagi Notifier.
- Melakukan serialisasi entitas `ServiceHistory`, `VehicleInfo`, dan `ServiceComponent` ke format JSON dan deserialisasi dari JSON.
- Mengisolasi implementasi penyimpanan lokal dari logika bisnis dan UI.

### 4. Persistence Layer (`shared_preferences`)
- Menggunakan `shared_preferences` untuk menyimpan list serialized JSON pada disk lokal perangkat / browser:
  - `servisku_service_history_v1`: Catatan riwayat servis kendaraan
  - `servisku_vehicle_info_v1`: Informasi profil motor utama
  - `servisku_service_components_v1`: Daftar komponen servis berkala & kustom
- Mendukung multi-platform: Android, iOS, Windows desktop, Linux, macOS, dan Web tanpa dependensi native FFI tambahan.
