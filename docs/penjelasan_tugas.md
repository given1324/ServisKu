# Tugas Mahasiswa — Local Data & Persistence

**Aplikasi:** ServisKu (Manajemen Catatan & Riwayat Servis Kendaraan)  
**Teknologi:** Flutter, Riverpod, SharedPreferences (Local Storage)  
**Fitur Vertikal:** Frontend (Dashboard & Form Servis) → State Notifier (Riverpod) → Repository Layer → Local Persistence (`shared_preferences`)

---

## 1. Ringkasan Implementasi

Sesuai kriteria tugas **Local Data & Persistence**, berikut adalah pemenuhan kebutuhan minimal yang telah diimplementasikan:

| Komponen | Spesifikasi & Implementasi | Lokasi Kode |
|---|---|---|
| **Local Data** | Penyimpanan data persisten lokal menggunakan package resmi `shared_preferences` berbasis JSON string serialization. | [service_repository.dart](file:///c:/Users/USER/serviceku/lib/repositories/service_repository.dart) |
| **Data Model** | Model entity `ServiceHistory` dilengkapi method serialisasi (`toMap`, `toJson`) dan deserialisasi (`fromMap`, `fromJson`), serta `copyWith`. | [service_history.dart](file:///c:/Users/USER/serviceku/lib/models/service_history.dart) |
| **CRUD** | Implementasi lengkap: **Create** (tambah servis baru), **Read** (muat riwayat tersimpan), **Update** (edit catatan & ubah status), **Delete** (hapus catatan). | [service_provider.dart](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart) & UI |
| **Persistence Test** | Pengujian otomatis yang memverifikasi bahwa data tidak hilang saat aplikasi ditutup lalu dibuka kembali (*cold restart*). | [persistence_test.dart](file:///c:/Users/USER/serviceku/test/persistence_test.dart) |
| **Fitur Vertikal** | FE (`DashboardScreen`, `FormServisScreen`) $\rightarrow$ Notifier (`ServiceHistoryNotifier`) $\rightarrow$ Repository (`ServiceRepository`) $\rightarrow$ `SharedPreferences`. | Seluruh alur data |

---

## 2. Struktur Data Model (`ServiceHistory`)

Model data disimpan secara lokal dengan skema:

```dart
class ServiceHistory {
  final String id;              // ID unik (timestamp / UUID)
  final String jenisServis;     // Nama/jenis pengerjaan servis
  final int odometer;           // Odometer kendaraan (km)
  final int totalBiaya;         // Biaya servis (Rupiah)
  final DateTime createdAt;     // Waktu pencatatan
  final DateTime? completedAt;  // Waktu servis diselesaikan
  final String status;          // 'Belum Selesai' | 'Selesai'
  final String? catatan;        // Catatan tambahan / spare part
}
```

### Mekanisme Serialisasi & Deserialisasi
- `toMap()`: Mengonversi objek `ServiceHistory` menjadi `Map<String, dynamic>` dengan tanggal diformat ISO 8601.
- `fromMap(Map<String, dynamic> map)`: Membaca map dan menginstansiasi ulang objek `ServiceHistory`.
- `toJson()`: Mengubah entity menjadi string JSON menggunakan `json.encode()`.
### Model Profil Motor (`VehicleInfo`)
Selain catatan servis, informasi motor utama juga disimpan secara persisten:
```dart
class VehicleInfo {
  final String namaMotor;   // Contoh: 'Honda Vario 160', 'Yamaha NMAX 155'
  final String platNomor;   // Contoh: 'B 1234 XYZ'
  final int tahun;          // Contoh: 2023
}
```
Dilengkapi dengan `toMap()`, `fromMap()`, `toJson()`, dan `fromJson()` serta key SharedPreferences `servisku_vehicle_info_v1`.

### Model Komponen Servis (`ServiceComponent`)
Untuk mendukung pemantauan dan kustomisasi suku cadang berkala:
```dart
class ServiceComponent {
  final String id;          // ID komponen (e.g. 'comp_oli_mesin', 'comp_busi')
  final String nama;        // Nama komponen (e.g. 'Oli Mesin', 'Kampas Rem')
  final int intervalKm;     // Interval servis berkala dalam kilometer
  final String deskripsi;   // Catatan rekomendasi / tips servis
  final bool isCustom;      // true jika ditambahkan pengguna secara manual
}
```
Dilengkapi preset standar pabrik (Oli Mesin, Oli Gardan, Busi, Filter Udara, Kampas Rem, V-Belt CVT, Radiator Coolant) dan kemampuan **CRUD Komponen Kustom** (Tambah, Edit, Hapus) yang tersimpan secara lokal pada key SharedPreferences `servisku_service_components_v1`.

---

## 3. Alur CRUD Vertikal (FE $\rightarrow$ Local Storage)

```
┌────────────────────────────────────────────────────────┐
│                   FRONTEND (UI)                        │
│   - DashboardScreen (Daftar Catatan, Ringkasan, Hapus) │
│   - FormServisScreen (Form Tambah & Edit Catatan)      │
└─────────────────────────┬──────────────────────────────┘
                          │ (watch / read)
                          ▼
┌────────────────────────────────────────────────────────┐
│             STATE NOTIFIER (Riverpod)                  │
│   - ServiceHistoryNotifier (AsyncNotifier)             │
│   - addService() / updateService() / deleteService()   │
└─────────────────────────┬──────────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────────┐
│                 REPOSITORY LAYER                       │
│   - ServiceRepository                                  │
│   - fetchServiceHistory()                              │
│   - addServiceHistory()                                │
│   - updateServiceHistory()                             │
│   - deleteServiceHistory()                             │
└─────────────────────────┬──────────────────────────────┘
                          │ (jsonEncode / jsonDecode)
                          ▼
┌────────────────────────────────────────────────────────┐
│              LOCAL PERSISTENCE LAYER                   │
│   - SharedPreferences ('servisku_service_history_v1')  │
│   - Tersimpan pada storage lokal device / browser      │
└────────────────────────────────────────────────────────┘
```

### Penjelasan Operasi CRUD:
1. **Create (Tambah Data):**
   - Pengguna menekan tombol Floating Action Button (`+`) di Dashboard.
   - Form modal muncul (`FormServisScreen`).
   - Setelah validasi berhasil, form memanggil `ref.read(serviceHistoryProvider.notifier).addService(...)`.
   - Notifier meneruskan ke `ServiceRepository.addServiceHistory()`. Data dienkode ke JSON dan disimpan permanen via `prefs.setString()`.
   - State Riverpod diperbarui secara reaktif, dashboard langsung menampilkan data baru.

2. **Read (Membaca & Memuat Data):**
   - Saat aplikasi pertama kali dibuka (diinisialisasi pada `main.dart` dengan `SharedPreferences.getInstance()`), `ServiceHistoryNotifier.build()` memanggil `ServiceRepository.fetchServiceHistory()`.
   - Repository membaca string JSON dari storage lokal, mendecode ke `List<ServiceHistory>`, dan mengurutkannya dari yang terbaru.
   - Dashboard menampilkan daftar riwayat servis, ringkasan pengeluaran, dan kilometer odometer terbaru.

3. **Update (Perbarui Data):**
   - Pengguna memilih opsi **Edit** pada menu pop-up item riwayat servis.
   - Form terbuka dalam mode edit dengan kolom-kolom yang sudah terisi data awal (*pre-filled*).
   - Pengguna dapat mengubah nama servis, odometer, biaya, status (misal dari "Belum Selesai" menjadi "Selesai"), atau catatan.
   - Perubahan disimpan ke `SharedPreferences` dan state UI langsung ter-update seketika.

4. **Delete (Hapus Data):**
   - Pengguna memilih opsi **Hapus** pada menu pop-up kartu riwayat servis.
   - Dialog konfirmasi muncul untuk mencegah ketidaksengajaan.
   - Saat dikonfirmasi, `deleteService(id)` dipanggil: data dihapus dari `SharedPreferences` dan item langsung hilang dari daftar tampilan.

---

## 4. Bukti Pengujian Persistensi (Persistence Test)

Pengujian persistensi dilakukan di [test/persistence_test.dart](file:///c:/Users/USER/serviceku/test/persistence_test.dart) dengan mensimulasikan siklus hidup aplikasi yang ditutup (*killed/disposed*) lalu dibuka kembali (*cold restart*):

1. **Test Model & Serialisasi:** Memastikan serialisasi dan deserialisasi JSON bekerja presisi tanpa kehilangan nilai field.
2. **Test CRUD Storage Lokal:** Memverifikasi penulisan dan pembacaan langsung ke `SharedPreferences`.
3. **Test Cold Restart Persistence:** Menyimpan catatan servis di Sesi 1, menghancurkan instance objek repository, kemudian membuat instance baru di Sesi 2 dari storage yang sama. Data terbukti tetap utuh.
4. **Test Update & Delete Persistence:** Memastikan perubahan data dan penghapusan data tetap bertahan setelah simulasi restart aplikasi.
5. **Test Alur Vertikal Notifier:** Memastikan integrasi FE State Notifier menyimpan data ke storage fisik dan terbaca kembali saat container baru diinisialisasi.

### Hasil Eksekusi Test:
Perintah:
```powershell
flutter test
```
Output:
```plaintext
00:05 +20: All tests passed!
```
Total 22 pengujian (unit test, widget test, dan persistence test) lulus 100%.

---

## 5. Panduan Demo Singkat CRUD & Persistence

Untuk mendemonstrasikan tugas ini secara langsung:

1. **Jalankan Aplikasi:**
   - **Mode Web dengan Penyimpanan Persisten (Rekomendasi):**
     ```powershell
     .\run_web.bat
     # atau perintah manual:
     flutter run -d chrome --web-port=5000 --web-browser-flag="--user-data-dir=.chrome_data"
     ```
     > **Catatan Penting:** Perintah ini mengunci port (`:5000`) dan folder profil Chrome (`.chrome_data`), sehingga saat proses di terminal dimatikan (`Ctrl+C` / `Terminate batch job`) lalu dijalankan kembali, data `localStorage` **tetap utuh dan tidak hilang**.
   - **Mode Standar:**
     ```powershell
     flutter run -d chrome
     ```
2. **Demo Edit Profil Motor:**
   - Pada kartu hijau gelap di bagian atas dashboard, klik tombol **Edit** di samping teks "MOTOR UTAMA".
   - Ubah Nama Motor (misal: `Yamaha NMAX 155`), Plat Nomor (`B 4321 ZZZ`), dan Tahun (`2024`).
   - Klik **Simpan Perubahan**. Kartu motor langsung ter-update dengan nama dan plat nomor baru!
   - Refresh browser / restart aplikasi: nama motor baru tetap tersimpan permanen.
3. **Demo Create (Tambah Data):**
   - Klik tombol bundar hijau **+** di pojok kanan bawah.
   - Masukkan jenis servis: `Ganti Oli Mesin & Filter`.
   - Masukkan odometer: `15000`.
   - Masukkan biaya: `85000`.
   - Pilih status servis (misal: `Belum Selesai`).
   - Klik **Simpan catatan**. Kartu baru langsung muncul di dashboard dan total pengeluaran terhitung.
4. **Demo Update (Ubah Data):**
   - Klik tombol titik tiga (`...`) pada kartu yang baru dibuat.
   - Pilih menu **Edit**.
   - Ubah status menjadi `Selesai` atau ubah biaya menjadi `95000`.
   - Klik **Simpan catatan**. Status pada kartu berubah menjadi "Selesai".
5. **Demo Persistence (Uji Ketahanan Data):**
   - **Tutup aplikasi sepenuhnya** (hentikan proses di terminal / tutup window / refresh tab browser dengan `F5` atau `Ctrl+R`).
   - Buka kembali aplikasi.
   - **Hasil:** Data motor dan riwayat servis yang sebelumnya disimpan tetap tersedia lengkap tanpa hilang!
6. **Demo Delete (Hapus Data):**
   - Klik tombol titik tiga (`...`) pada kartu servis.
   - Pilih menu **Hapus**.
   - Konfirmasi dialog hapus.
   - Kartu terhapus dari tampilan.
   - Refresh kembali browser / buka ulang aplikasi: data yang telah dihapus terbukti tidak muncul kembali.
