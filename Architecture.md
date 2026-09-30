# Arsitektur Sistem - ServisKu 

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi, struktur proyek, dan skema data untuk aplikasi mobile ServisKu. Arsitektur ini dirancang khusus agar ringan, mudah dikelola oleh satu pengembang (solo developer), dan dapat diselesaikan dalam target 12 pertemuan.

## 1. Tumpukan Teknologi (Tech Stack)
*   **Frontend (Mobile):** Flutter (UI Toolkit untuk membuat aplikasi Android/iOS yang ringan).
*   **Bahasa Pemrograman:** Dart.
*   **Lingkungan Pengembangan:** Antigravity IDE.
*   **Backend & Database (BaaS):** Firebase (Authentication & Cloud Firestore). Sangat cocok karena sistem ini difokuskan pada teks dan angka saja tanpa unggah foto.
*   **State Management:** Riverpod (untuk mengatur alur data dari database ke antarmuka aplikasi secara efisien).

## 2. Alur Sistem (System Flow)
*   **Autentikasi Pengguna:** Aplikasi berkomunikasi dengan Firebase Auth untuk pendaftaran dan login. Token akses memastikan data pengguna terisolasi dengan aman.
*   **Sinkronisasi Data (CRUD):** Tambah, baca, ubah, dan hapus riwayat servis dikirim dari aplikasi ke Cloud Firestore. Data langsung diurutkan dari tanggal paling baru ke paling lama dari sisi server.
*   **Kalkulasi Ringkasan Biaya:** Saat pengguna membuka daftar riwayat, fungsi lokal pada aplikasi akan menyaring data bulan berjalan dan menjumlahkan field `totalBiaya` untuk menampilkan ringkasan pengeluaran bulanan.
*   **Filter Pencarian:** Kolom pencarian di antarmuka akan memfilter daftar riwayat yang sudah dimuat ke dalam memori lokal (berdasarkan kata kunci pada `jenisServis`, misal: "Kampas Rem"), sehingga proses pencarian terasa instan.

## 3. Skema Database (NoSQL - Firestore)
Sistem menggunakan dua koleksi utama untuk menjaga pemisahan data antar pengguna.

**A. Koleksi Users**
*   `id` (String, Primary Key / UID dari Firebase Auth)
*   `email` (String)
*   `createdAt` (Timestamp)

**B. Koleksi RiwayatServis**
*   `id` (String, Auto-generated)
*   `userId` (String, Foreign Key -> Users)
*   `tanggal` (Timestamp)
*   `jenisServis` (String) - Contoh: "Ganti Oli Mesin"
*   `odometer` (Number) - Kilometer saat ini
*   `totalBiaya` (Number) - Total pengeluaran servis
*   `createdAt` (Timestamp)

## 4. Struktur Direktori Proyek
Proyek ini menggunakan arsitektur modular yang rapi agar mudah di-maintenance:

```text
servisku_flutter/
│
├── lib/
│   ├── main.dart                  # Entri utama aplikasi
│   ├── app.dart                   # Root widget, tema, dan navigasi
│   │
│   ├── screens/                   # Halaman antarmuka utama (UI)
│   │   ├── login_screen.dart      # Halaman autentikasi
│   │   ├── dashboard_screen.dart  # Menampilkan riwayat (terurut), ringkasan biaya bulanan, dan filter pencarian
│   │   └── form_servis_screen.dart # Form input (Tanggal, Jenis, Odometer, Biaya)
│   │
│   ├── widgets/                   # Komponen UI yang dapat digunakan ulang
│   │   └── service_card.dart      # Desain kartu untuk item daftar servis
│   │
│   ├── models/                    # Cetak biru struktur data
│   │   └── service_history.dart   # Model yang merepresentasikan tabel RiwayatServis
│   │
│   ├── providers/                 # State management (Riverpod Notifier)
│   │   └── service_provider.dart  # Menghubungkan logika dari database ke UI
│   │
│   └── services/                  # Logika eksternal / komunikasi ke Firebase
│       ├── auth_service.dart      # Logika pendaftaran dan login
│       └── database_service.dart  # Logika CRUD ke Firestore
│
└── pubspec.yaml                   # Daftar dependensi (flutter_riverpod, firebase_core, dll)
