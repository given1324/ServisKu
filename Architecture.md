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
