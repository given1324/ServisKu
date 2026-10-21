# Integrasi API dan Vertical Slice — ServisKu

Dokumen ini menjelaskan implementasi tugas **Integrasi API dan Vertical Slice** pada aplikasi **ServisKu** (Manajemen Catatan Servis Kendaraan).

---

## 1. Pemilihan Fitur Inti
Fitur inti yang dipilih dari proyek yang sudah ada adalah **Riwayat Servis Kendaraan (Service History)**:
- **Alasan Pemilihan:** Riwayat servis merupakan fungsionalitas paling esensial dalam aplikasi ServisKu, yang mencakup siklus hidup data penuh (*full lifecycle*): pencatatan servis baru, kalkulasi odometer & pengeluaran, pemantauan jadwal servis berkala, pengeditan, serta penghapusan data.
- **Model Entitas:** [ServiceHistory](file:///c:/Users/USER/serviceku/lib/models/service_history.dart)
  - `id` (String unik)
  - `jenisServis` (String nama servis/penggantian suku cadang)
  - `odometer` (int kilometer jarak tempuh kendaraan)
  - `totalBiaya` (int biaya servis dalam Rupiah)
  - `createdAt` (DateTime waktu pencatatan/servis)
  - `completedAt` (DateTime? waktu selesai)
  - `status` (String 'Selesai' | 'Belum Selesai')
  - `catatan` (String? catatan teknis/suku cadang tambahan)

---

## 2. Arsitektur Vertical Slice

Alur vertikal menghubungkan lapisan antarmuka pengguna (UI) hingga ke Backend REST API melalui repository dan model:

```
┌────────────────────────────────────────────────────────┐
│                      UI LAYER                          │
│   - DashboardScreen (Daftar Catatan, Metrik, Hapus)    │
│   - FormServisScreen (Form Tambah & Edit Catatan)      │
│   (Loading State, Empty State, Error State, Retry)     │
└─────────────────────────┬──────────────────────────────┘
                          │ (watch / read)
                          ▼
┌────────────────────────────────────────────────────────┐
│             STATE NOTIFIER (Riverpod)                  │
│   - ServiceHistoryNotifier (AsyncNotifier)             │
│   - refreshData() / addService() / updateService()     │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│                 REPOSITORY LAYER                       │
│   - ServiceRepository                                  │
│   - fetchServiceHistory()                              │
│   - addServiceHistory() / updateServiceHistory()       │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│                 API SERVICE LAYER                      │
│   - ApiService (http.Client)                           │
│   - GET /services (Loading dari Backend)               │
│   - POST /services (Penyimpanan ke Backend)            │
│   - PUT /services/:id & DELETE /services/:id           │
└─────────────────────────┬──────────────────────────────┘
                          │ (HTTP / JSON)
                          ▼
┌────────────────────────────────────────────────────────┐
│                  BACKEND REST API                      │
│   - Remote Server / SimulatedBackendClient (HTTP)      │
└────────────────────────────────────────────────────────┘
```

---

## 3. Komponen Alur & Penyimpanan Data

| Komponen | Berkas Kode | Peran & Tanggung Jawab |
|---|---|---|
| **Model** | [service_history.dart](file:///c:/Users/USER/serviceku/lib/models/service_history.dart) | Data transfer object (DTO) dengan validasi skema (`isValid`, `validate()`), serialisasi (`toJson`, `toMap`), dan deserialisasi aman (`fromJson`, `fromMap`). |
| **API Client** | [api_service.dart](file:///c:/Users/USER/serviceku/lib/services/api_service.dart) | Menangani komunikasi HTTP jaringan (GET, POST, PUT, DELETE), validasi status code (200, 201, 204), deserialisasi payload JSON, serta melempar `ApiException` dan `FormatException`. |
| **Simulated Backend** | [api_service.dart](file:///c:/Users/USER/serviceku/lib/services/api_service.dart) | Mengimplementasikan `http.BaseClient` untuk simulasi REST API dengan delay jaringan (50 ms) agar aplikasi dapat didemokan secara mandiri tanpa dependensi server eksternal. |
| **Repository** | [service_repository.dart](file:///c:/Users/USER/serviceku/lib/repositories/service_repository.dart) | Single Source of Truth yang mengabstraksi pemanggilan API dari state notifier, sekaligus menyinkronkan data ke penyimpanan lokal jika `SharedPreferences` tersedia. |
| **State Management** | [service_provider.dart](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart) | Menggunakan Riverpod `AsyncNotifier` untuk mengelola state asinkron (`loading`, `data`, `error`), optimistik update, serta penanganan error via `AsyncValue.guard`. |
| **User Interface** | [dashboard_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/dashboard_screen.dart) & [form_service_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/form_service_screen.dart) | Menampilkan 5 kondisi UI secara interaktif: loading, empty, error, success, dan retry. |

---

## 4. Tampilan 5 Kondisi UI

1. **Loading State:**
   - **Tampilan:** `CircularProgressIndicator` berada di tengah layar saat data pertama kali dimuat dari API backend.
   - **Submit Loading:** Pada form catatan servis, tombol "Simpan catatan" menampilkan indikator pemuatan dan dalam kondisi *disabled* agar pengguna tidak dapat melakukan *double submit*.
2. **Empty State:**
   - **Tampilan:** Saat backend merespons dengan array data kosong (`[]`), dashboard menampilkan pesan informatif:  
     `"Belum ada riwayat servis. Silakan tambah data baru."`
3. **Error State:**
   - **Tampilan:** Jika backend mengembalikan HTTP status error (seperti 500/404) atau terjadi kegagalan jaringan, antarmuka menampilkan ikon `cloud_off_rounded` disertai teks:  
     `"Terjadi kesalahan saat memuat data.\n[Pesan Error]"`
4. **Success State:**
   - **Tampilan:** Setelah data berhasil dimuat atau disimpan ke backend, dashboard menampilkan ringkasan pengeluaran, kilometer odometer terbaru, pemantauan servis berkala, dan daftar kartu riwayat servis.
5. **Retry State:**
   - **Tampilan & Aksi:** Tombol **"Coba Lagi"** muncul pada tampilan error state. Pengguna juga dapat melakukan gesture *pull-to-refresh* (`RefreshIndicator`) untuk memicu pemanggilan ulang `ref.read(serviceHistoryProvider.notifier).refreshData()`.

---

## 5. Rincian Pengujian Unit Test

Pengujian unit test diimplementasikan pada berkas [test/api_unit_test.dart](file:///c:/Users/USER/serviceku/test/api_unit_test.dart) dengan minimal 6 unit test wajib:

| No | Kategori Unit Test | Skenario Pengujian | Hasil |
|:--:|---|---|:--:|
| 1 | **Model Valid** | Memverifikasi bahwa payload JSON valid berhasil diparse ke entitas `ServiceHistory`, seluruh field terpetakan secara presisi, `isValid == true`, dan `validate()` berjalan normal tanpa error. | **PASS** |
| 2 | **Model Invalid** | Menguji penanganan data cacat: field wajib `jenisServis` kosong, odometer bernilai negatif, atau total biaya negatif melempar `FormatException` serta terdeteksi `isValid == false`. | **PASS** |
| 3 | **API Sukses** | Menggunakan `MockClient` dengan respons HTTP 200 OK (GET) dan HTTP 201 Created (POST). Memverifikasi bahwa data berhasil dimuat dan disimpan ke backend. | **PASS** |
| 4 | **Data Kosong** | Menguji respons HTTP 200 OK dengan payload array kosong `[]`. Memverifikasi repository mengembalikan `List` kosong (`isEmpty == true`) untuk menampilkan empty state di UI. | **PASS** |
| 5 | **HTTP Gagal** | Menguji respons server saat terjadi kesalahan HTTP 500 (Internal Server Error) dan HTTP 404 (Not Found). Memverifikasi bahwa repository melempar `ApiException` dengan status code yang sesuai. | **PASS** |
| 6 | **JSON Rusak** | Menguji saat server mengembalikan HTTP 200 tetapi isi body bukan JSON valid (sintaks terputus, dokumen HTML 502 Bad Gateway, atau bukan array). Memverifikasi melempar `FormatException`. | **PASS** |

### Perintah Menjalankan Unit Test API:
```powershell
flutter test test/api_unit_test.dart
```

Output:
```plaintext
00:00 +0: loading C:/Users/USER/serviceku/test/api_unit_test.dart
00:00 +0: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 1. Model Valid: JSON valid berhasil diparse ke ServiceHistory dan berstatus valid
00:00 +1: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 2. Model Invalid: JSON/data invalid melempar FormatException atau terdeteksi invalid
00:00 +2: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 3. API Sukses: Backend mengembalikan HTTP 200/201 dan data berhasil dimuat/disimpan
00:00 +3: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 4. Data Kosong: Backend mengembalikan HTTP 200 OK dengan payload array kosong []
00:00 +4: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 5. HTTP Gagal: Backend mengembalikan status HTTP error (500/404) melempar ApiException
00:00 +5: Pengujian Unit Test: Integrasi API & Vertical Slice (Minimal 6 Unit Test) 6. JSON Rusak: Backend mengembalikan HTTP 200 dengan payload JSON cacat melempar FormatException
00:00 +6: All tests passed!
```

### Menjalankan Seluruh Rangkaian Pengujian:
```powershell
flutter test
```
Hasil: Total 36 pengujian (API unit tests, notifier unit tests, widget tests, dan persistence tests) lulus 100% (*All tests passed!*).
