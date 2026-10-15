## Arsitektur Sistem - ServisKu (Mobile App)

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi (tech stack), alur sistem, skema data, dan struktur direktori untuk aplikasi mobile ServisKu berbasis Flutter.

# 1. Tumpukan Teknologi (Tech Stack)

Aplikasi ini dibangun menggunakan arsitektur Cross-Platform Mobile Application dengan dukungan Backend-as-a-Service (BaaS) agar pengerjaan logika backend lebih cepat dan fokus pada tampilan UI.

Frontend (Mobile): Flutter Framework (Bahasa Pemrograman Dart).

Backend & Database (BaaS): Firebase (Firebase Authentication & Cloud Firestore) atau Supabase.

State Management: Provider / GetX (Untuk mengelola state data servis dan sesi login pengguna).

Perancangan UI (Prototype): Figma (Digunakan sebagai acuan mockup UI/UX sebelum penulisan kode).

# 2. Alur Sistem (System Flow)

Prototype ke UI Screen: Tampilan desain awal di Figma (Login, Dashboard Riwayat, Form Tambah Servis, dan Profil) diimplementasikan langsung ke dalam file-file screen Flutter.

Autentikasi & Routing: Pengguna mendaftar/login melalui auth_service.dart. Sistem Routing akan memeriksa status autentikasi pengguna; jika belum login, navigasi otomatis diarahkan ke LoginScreen, dan jika sudah login akan masuk ke DashboardScreen.

Penerapan Reusable Widgets: Komponen UI yang sering muncul—seperti kartu riwayat servis (ServiceCard), kartu total biaya (SummaryCard), tombol kustom (CustomButton), dan form input (CustomInputField)—dibuat sebagai widget terpisah agar dapat dipakai berulang kali tanpa membuat kode berantakan.

Manajemen Data Servis (CRUD):

Create: Pengguna mengisi form servis $\rightarrow$ dikirim via service_log_service.dart ke Cloud Firestore.

Read: DashboardScreen memuat daftar riwayat servis pengguna secara real-time menggunakan StreamBuilder atau FutureBuilder.

Update & Delete: Pengguna dapat memperbarui catatan kilometer/biaya atau menghapus riwayat dari halaman detail.

3. Skema Database (NoSQL - Firestore)
Data disimpan dalam dua koleksi (collections) utama dengan hubungan berbasis userId.

A. Koleksi users
Menyimpan data profil pemilik kendaraan.

*  `id` (String, Primary Key / UID dari Firebase Auth)

* `nama` (String)

* `email` (String)

* `createdAt` (Timestamp)

B. Koleksi service_logs
Menyimpan setiap catatan perawatan kendaraan.

* `id` (String, Auto-generated)

* `userId` (String, Foreign Key -> users.id)

* `tanggal` (Timestamp / ISO Date)

* `jenisServis` (String, contoh: "Ganti Oli Mesin & Servis CVT")

* `kilometer` (Number, contoh: 15500)

* `biaya` (Number, contoh: 120000)

* `createdAt` (Timestamp)

4. Struktur Direktori Proyek
Struktur folder disusun secara modular berbasis konsep pemisahan fungsi (Separation of Concerns):

```text
servisku_mobile/
│
├── assets/                 # Logo, ikon kendaraan, dan gambar lokal
│
├── lib/
│   ├── main.dart           # Entry point aplikasi & inisialisasi Firebase
│   │
│   ├── routes/             # Pengaturan alur perpindahan halaman (Routing)
│   │   └── app_routes.dart # Definisi rute: '/login', '/dashboard', '/add-service'
│   │
│   ├── screens/            # Tampilan halaman utama berdasarkan Prototype
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── dashboard_screen.dart   # Menampilkan ringkasan & daftar riwayat
│   │   ├── add_service_screen.dart # Form mencatat servis baru
│   │   └── profile_screen.dart
│   │
│   ├── widgets/            # Reusable component / widget yang dipakai berulang
│   │   ├── custom_button.dart
│   │   ├── custom_input_field.dart
│   │   ├── service_card.dart       # Kartu item riwayat servis
│   │   └── summary_card.dart       # Kartu total pengeluaran/kilometer
│   │
│   ├── models/             # Model data (Konversi JSON/Firestore ke Objek Dart)
│   │   └── service_log_model.dart
│   │
│   └── services/           # Logika integrasi API / Database eksternal
│       ├── auth_service.dart        # Logika Login & Register
│       └── service_log_service.dart # Logika CRUD data servis ke Firestore
│
├── .env                    # Variabel konfigurasi API Key (Tidak di-commit ke Git)
├── pubspec.yaml            # Dependensi paket (firebase_core, provider, dll)
└── README.md               # Dokumentasi utama proyek[cite: 1]
