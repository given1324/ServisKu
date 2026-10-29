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


---

## 6. Tugas Pertemuan 7: MVP Lengkap & 3 Advanced Feature

### A. Ringkasan Implementasi MVP Pertemuan 7

Seluruh alur utama MVP telah diselesaikan dengan integrasi 3 fitur tingkat lanjut (*advanced features*), penanganan kondisi (*loading*, *empty*, *error*, *permission handling*), serta penyesuaian estetika *Dark Theme* sesuai referensi visual:

| Fitur / Kebutuhan | Deskripsi Implementasi | Lokasi Kode |
|---|---|---|
| **1. Navigasi Penuh** | Bottom Navigation Bar 5 Tab (Kendaraan, Riwayat, Bengkel, Notifikasi, Akun) dengan badge jumlah notifikasi unread. | [main_navigation_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/main_navigation_screen.dart) |
| **2. Form & Validasi** | Form validasi ketat: email valid & password min 6 karakter, form servis (nama, odo angka, biaya angka), form motor, dan form kustom komponen. | [login_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/login_screen.dart), [form_service_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/form_service_screen.dart) |
| **3. Penyimpanan Data** | Penyimpanan sesi login, preferensi izin, profil motor, komponen kustom, riwayat servis, dan notifikasi ke Local Storage (`SharedPreferences`). | [service_repository.dart](file:///c:/Users/USER/serviceku/lib/repositories/service_repository.dart), [service_provider.dart](file:///c:/Users/USER/serviceku/lib/providers/service_provider.dart) |
| **4. Advanced Feature 1: Autentikasi** | Sistem login pengguna, register, demo guest login, persistensi sesi akun, dan logout. | [login_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/login_screen.dart), [user_model.dart](file:///c:/Users/USER/serviceku/lib/models/user_model.dart) |
| **5. Advanced Feature 2: Notifikasi Pengingat** | Peringatan servis berkala saat batas odometer tercapai, simulasi trigger, dialog izin notifikasi (Izinkan / Tolak / Batal), filter notifikasi. | [notification_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/notification_screen.dart), [service_notification.dart](file:///c:/Users/USER/serviceku/lib/models/service_notification.dart) |
| **6. Advanced Feature 3: Lokasi Bengkel Google Maps** | Pencari bengkel terdekat (AHASS, Yamaha, Umum, Tambal Ban) berbasis GPS & Haversine formula, radar visualizer, izin lokasi, dan direct link rute Google Maps. | [workshop_map_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/workshop_map_screen.dart), [workshop_model.dart](file:///c:/Users/USER/serviceku/lib/models/workshop_model.dart) |
| **7. Penanganan Kondisi Lengkap** | Penanganan status: *Loading* (indikator progres), *Empty* (tampilan ramah pengguna saat data kosong), *Error* (penanganan kegagalan & tombol Coba Lagi), *Permission & Cancellation* (penanganan izin GPS & Notif saat ditolak/dibatalkan). | Seluruh layar UI |
| **8. Desain Sesuai Referensi** | Tampilan *Dark Theme* (`#0F1216`), kartu Odometer besar (`10.000 km`), siluet motor spotlight, banner status "Semua komponen dalam kondisi baik", segmented tab ("Komponen" | "Perawatan"), dan kartu "Sehat". | [dashboard_screen.dart](file:///c:/Users/USER/serviceku/lib/screens/dashboard_screen.dart) |

---

### B. Penjelasan 3 Advanced Feature & Manfaatnya Bagi Pengguna

#### 1. Autentikasi Pengguna (Login & Manajemen Akun)
- **Cara Kerja:** Pengguna dapat masuk menggunakan akun terdaftar atau menggunakan akun demo instan. Sesi login tersimpan secara persisten di local storage sehingga pengguna tidak perlu login berulang kali saat membuka aplikasi.
- **Manfaat bagi Pengguna:**
  1. **Personalisasi Data:** Setiap data riwayat perawatan dan profil kendaraan terikat dengan akun pengendara.
  2. **Keamanan & Privasi:** Mencegah catatan pengeluaran servis dan spesifikasi kendaraan diakses orang lain tanpa izin.
  3. **Fleksibilitas Akses Tamu:** Pengguna baru tetap dapat langsung mencoba fitur MVP melalui tombol "Masuk sebagai Tamu (Mode Demo)".

#### 2. Notifikasi & Pengingat Servis Berkala
- **Cara Kerja:** Sistem memantau selisih jarak tempuh odometer terhadap batas interval masing-masing komponen (seperti Oli Mesin 2.000 km, Busi 6.000 km). Saat kilometer mendekati batas atau terlampaui (*overdue*), aplikasi membunyikan/menampilkan peringatan notifikasi berlevel urgensi (Aman, Perhatian, Darurat).
- **Manfaat bagi Pengguna:**
  1. **Mencegah Kerusakan Mesin Fatal:** Pengendara terhindar dari kehabisan oli mesin atau mogok di jalan akibat komponen aus yang lupa diganti.
  2. **Efisiensi Biaya Perawatan:** Servis tepat waktu menjaga konsumsi bahan bakar tetap hemat dan memperpanjang usia motor.
  3. **Kontrol Izin Transparan:** Pengguna memiliki kendali penuh untuk mengizinkan (*grant*) atau menolak (*deny*) izin notifikasi melalui dialog izin yang ramah.

#### 3. Lokasi GPS & Pencari Bengkel Google Maps Terdekat
- **Cara Kerja:** Aplikasi meminta izin akses lokasi (GPS) untuk mendeteksi koordinat pengguna (Latitude & Longitude). Jarak ke berbagai bengkel dihitung secara akurat menggunakan rumus matematika *Haversine* dan diurutkan dari yang terdekat. Dilengkapi tombol direct link untuk membuka titik lokasi dan navigasi rute di Google Maps.
- **Manfaat bagi Pengguna:**
  1. **Solusi Cepat Kondisi Darurat:** Sangat membantu saat pengendara mengalami ban bocor atau motor mogok di perjalanan untuk menemukan tukang tambal ban atau bengkel terdekat.
  2. **Pilihan Bengkel Spesifik:** Pengguna dapat menyaring bengkel resmi (AHASS Honda, Yamaha) atau bengkel umum yang buka 24 jam.
  3. **Navigasi Rute Langsung:** Sekali klik, aplikasi langsung membuka Google Maps Navigation tanpa perlu mengetik ulang alamat.

---

### C. Penanganan Kasus Izin & Pembatalan (Permission & Cancellation Handling)

1. **Izin Notifikasi:**
   - Pengguna dapat memilih **Izinkan**, **Tolak**, atau **Batal/Nanti**.
   - Jika ditolak, aplikasi tidak crash; sistem beralih ke mode manual dan menampilkan banner informatif bahwa pengingat otomatis non-aktif.
2. **Izin Lokasi (GPS):**
   - Jika pengguna menolak atau membatalkan izin lokasi, aplikasi secara cerdas beralih ke lokasi acuan default (Gading Serpong / Tangerang) sehingga pengguna tetap dapat melihat daftar bengkel dan tautan peta.
   - Disediakan tombol **Coba Lagi** untuk meminta izin kembali kapan pun pengguna menginginkannya.
