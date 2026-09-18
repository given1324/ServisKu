# Arsitektur Sistem - Serviceku (Web Application)

Dokumen ini menjelaskan rancangan arsitektur, tumpukan teknologi (tech stack), struktur proyek, dan skema data untuk aplikasi web Serviceku.

## 1. Tumpukan Teknologi (Tech Stack)

Aplikasi ini menggunakan arsitektur Monolitik modern dengan Next.js App Router yang menggabungkan frontend dan backend dalam satu proyek.
- **Frontend & Backend (Framework):** Next.js (App Router, v16.3.5)
- **UI Library:** React (v19)
- **Bahasa Pemrograman:** JavaScript
- **Database:** SQLite (file lokal `dev.db`)
- **ORM (Object-Relational Mapping):** Prisma
- **Autentikasi:** NextAuth.js (v4) menggunakan sistem Kredensial (Username & Password)
- **Keamanan/Kriptografi:** `bcryptjs` untuk *hashing* password.

## 2. Alur Sistem (System Flow)

- **Autentikasi:** Aplikasi menggunakan NextAuth untuk mengelola sesi pengguna. Saat login, sistem akan mencocokkan *username* dan *password* (yang di-hash dengan `bcryptjs`) dari database SQLite melalui Prisma. Sesi disimpan secara aman menggunakan mekanisme yang disediakan oleh NextAuth.
- **Manajemen Data (CRUD):** Semua operasi pembuatan, pembacaan, pengeditan, dan penghapusan data servis kendaraan (Service Records) dilakukan melalui **Server Actions** (`app/actions.js`). Hal ini memungkinkan frontend memanggil fungsi backend secara langsung dan aman tanpa harus membuat API route terpisah.
- **Akses Relasional:** Setiap catatan servis (Service Record) diikat langsung ke pengguna yang sedang login (melalui `userId`), memastikan bahwa pengguna hanya bisa melihat dan mengelola catatan servis milik mereka sendiri.

## 3. Skema Database (Relasional - SQLite via Prisma)

Sistem menggunakan dua tabel/model utama yang direlasikan:

### A. Tabel/Model `User`

Menyimpan kredensial dan profil dasar pengguna.
- `id` (String, Primary Key / UUID)
- `username` (String, Unique) - Digunakan untuk identitas login
- `password` (String) - Disimpan dalam bentuk hash `bcrypt`
- `createdAt` (DateTime) - Waktu akun dibuat

### B. Tabel/Model `ServiceRecord`

Menyimpan riwayat servis kendaraan yang dilakukan oleh pengguna.
- `id` (String, Primary Key / UUID)
- `userId` (String, Foreign Key -> `User`)
- `date` (DateTime) - Tanggal servis dilakukan
- `serviceType` (String) - Jenis servis (contoh: "Ganti Oli", "Tune Up")
- `odometer` (Int) - Jarak tempuh kendaraan (kilometer) saat servis
- `cost` (Int) - Biaya servis
- `createdAt` (DateTime) - Waktu data ditambahkan
- `updatedAt` (DateTime) - Waktu data terakhir diubah

## 4. Struktur Direktori Proyek

Proyek ini menggunakan struktur standar Next.js App Router yang memisahkan konfigurasi, UI, logika aksi server, dan koneksi database.

```text
Serviceku/
│
├── app/                    # Direktori utama Next.js App Router (Frontend & Routing)
│   ├── dashboard/          # Halaman dashboard (daftar servis, tambah servis)
│   ├── login/              # Halaman login
│   ├── actions.js          # Next.js Server Actions untuk logika CRUD dan mutasi data
│   ├── globals.css         # Styling global aplikasi
│   └── layout.js / page.js # Root layout dan halaman utama
│
├── components/             # Komponen UI yang dapat digunakan ulang
│   └── AuthProvider.js     # Provider NextAuth untuk Session React Context
│
├── lib/                    # Fungsi utilitas dan instance bersama
│   └── prisma.js           # Konfigurasi dan inisialisasi singleton Prisma Client
│
├── prisma/                 # Konfigurasi Database dan ORM
│   ├── schema.prisma       # Definisi skema tabel (User, ServiceRecord)
│   └── dev.db              # File database lokal SQLite
│
├── public/                 # Aset statis (gambar, favicon)
├── .env                    # Variabel environment (Rahasia autentikasi/database) - Tidak di-commit
├── next.config.mjs         # Konfigurasi Next.js
├── package.json            # Daftar dependensi NPM (Next.js, Prisma, NextAuth)
└── jsconfig.json           # Konfigurasi JavaScript
```

## 5. Keamanan dan Akses Data

- **Server-Side Data Mutation:** Penggunaan Server Actions di Next.js memastikan logika mutasi database tidak bocor ke klien, dan berjalan secara aman di lingkungan server.
- **Proteksi Rute (Route Protection):** Halaman yang memerlukan data pengguna (seperti `dashboard/`) diamankan menggunakan *session checking* dari NextAuth. Jika pengguna tidak memiliki sesi yang valid, mereka akan diarahkan kembali ke halaman login.
- **Manajemen Kredensial:** Variabel lingkungan (seperti konfigurasi rahasia NextAuth `NEXTAUTH_SECRET`) disimpan dalam file `.env` untuk mencegah kebocoran kredensial ke dalam repositori kode publik.
- **Proteksi Password:** Sistem tidak pernah menyimpan password dalam bentuk teks murni (*plaintext*). Pustaka `bcryptjs` digunakan untuk memodifikasi password menjadi hash yang aman sebelum dimasukkan ke dalam database.
