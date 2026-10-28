# 🐾 Meowtopia Super App

<p align="center">
  <img src="frontend/assets/images/logo.png" alt="Meowtopia Logo" width="160" />
</p>

<p align="center">
  <b>Platform Ekosistem Digital Pengelolaan & Kesejahteraan Kucing Kampus</b><br>
  <i>Capstone Design Project - Universitas Telkom</i>
</p>

---

## 📌 Ringkasan Proyek

**Meowtopia** adalah super app pengelolaan kucing terintegrasi yang dikembangkan secara kolaboratif oleh 5 kelompok Capstone. Super app ini menyatukan pemeliharaan feeding spot resmi, gamifikasi penjelajahan kucing kampus, sistem adopsi & rehoming legal, pelaporan insiden darurat, serta identifikasi visual/karakteristik kucing berbasis AI & kuesioner ke dalam satu ekosistem digital.

### 👥 Pembagian 5 Kelompok & Fitur Utama

| No | Kelompok | Modul Backend (`backend/app/Modules/`) | Fitur Frontend (`frontend/lib/features/`) | Deskripsi Fitur |
|:--:|:---|:---|:---|:---|
| **-** | **Core / Shared** | `Core` & `Cat` | `auth/` & `cat/` | Autentikasi SSO/Sanctum, Master data kucing & kalung QR, profil pengguna. |
| **1** | **Acumalaka** | `FeedingSpot` | `feeding_spot/` | **Adopt Feeding Spot**: Manajemen titik makan resmi kampus, scan QR spot, unggah bukti foto, verifikasi kondisi mangkok makan, dan reward poin. |
| **2** | **SUPER-SUB** | `CatHunter` | `cat_hunter/` | **Telcat**: Game koleksi kucing kampus turn-based encounter (bukan AR virtual), encounter kalung QR, input kondisi kucing, log GPS crowdsourced heatmap, dex koleksi, & leaderboard. |
| **3** | **E-Nigma** | `CatAdoption` | `cat_adoption/` | **Adopsi & Rehoming**: Formulir komitmen/kesiapan adopter, verifikasi kelayakan admin, handover serah terima kucing via QR, monitoring "Kucing Saya" berkala (bi-weekly), kendala & pengembalian rehoming. |
| **4** | **Optimind** | `IncidentReport` | `incident_report/` | **Emergency Incident Reporting System**: Pelaporan darurat kucing sakit/terluka/terjebak, pin lokasi GPS darurat & foto insiden, status triage penanganan relawan/klinik. |
| **5** | **Rekans Caps** | `CatIdentification` | `cat_identification/` | **Sistem Identifikasi Kucing**: Identifikasi kucing tak dikenal / kalung hilang berbasis scan QR, pengenalan foto AI, dan kuesioner pertanyaan ciri fisik (corak bulu, ekor, telinga). |

---

## 🏗️ Struktur Direktori Proyek

```
Meowtopia/
├── .gitignore
├── README.md
├── backend/                             # Backend Laravel (Modular Architecture)
│   ├── app/
│   │   ├── Http/Controllers/Controller.php
│   │   ├── Models/User.php              # Model User default untuk Auth Sanctum
│   │   ├── Providers/
│   │   │   └── ModuleServiceProvider.php # Auto-loader migration & route tiap modul
│   │   ├── Support/
│   │   │   └── ApiResponse.php          # Standard JSON API response helper
│   │   └── Modules/
│   │       ├── Core/                    # Auth, Role, SSO, Base User
│   │       ├── Cat/                     # Master Data Kucing & Token QR Kalung
│   │       ├── FeedingSpot/             # Modul Kelompok Acumalaka
│   │       ├── CatHunter/               # Modul Kelompok SUPER-SUB
│   │       ├── CatAdoption/             # Modul Kelompok E-Nigma
│   │       ├── IncidentReport/          # Modul Kelompok Optimind
│   │       └── CatIdentification/       # Modul Kelompok Rekans Caps
│   ├── bootstrap/
│   │   ├── app.php
│   │   └── providers.php                # Registrasi ModuleServiceProvider
│   ├── routes/
│   │   └── api.php                      # Root API routes
│   ├── database/
│   │   └── seeders/DatabaseSeeder.php   # Seeder terpusat
│   ├── composer.json
│   └── .env.example
│
└── frontend/                            # Mobile Frontend Flutter (Feature-First Architecture)
    ├── assets/
    │   └── images/logo.png              # Logo Resmi Meowtopia
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart                     # MaterialApp + GoRouter + AppTheme
    │   ├── core/
    │   │   ├── constants/app_constants.dart
    │   │   ├── network/                 # Dio Client & ApiException
    │   │   ├── router/app_router.dart   # ShellRoute + Tab Navigation
    │   │   ├── storage/token_storage.dart
    │   │   ├── theme/app_theme.dart     # Palette oranye hangat & modern
    │   │   └── widgets/                 # Reusable Button, Loading, Error View
    │   ├── features/
    │   │   ├── auth/                    # Login, Register
    │   │   ├── cat/                     # Detail Kucing, Tampilan QR Kalung
    │   │   ├── feeding_spot/            # Kelompok Acumalaka
    │   │   ├── cat_hunter/              # Kelompok SUPER-SUB
    │   │   ├── cat_adoption/            # Kelompok E-Nigma
    │   │   ├── incident_report/         # Kelompok Optimind
    │   │   └── cat_identification/      # Kelompok Rekans Caps
    └── pubspec.yaml                     # Dependencies (Provider, Dio, GoRouter, dll.)
```

---

## 📜 Terms & Conditions: Aturan & Tata Cara Menggunakan Struktur Monorepo

Karena proyek ini dikerjakan secara paralel oleh **5 kelompok yang berbeda**, seluruh anggota kelompok **WAJIB** membaca dan mematuhi panduan aturan di bawah ini guna mencegah konflik kode (*merge conflict*), kerusakan database, maupun ketidakkonsistenan arsitektur:

### 1. 🛡️ Batasan Wilayah Kerja (Domain Boundaries)
Setiap kelompok memiliki hak akses dan tanggung jawab penuh pada foldernya masing-masing:
* **Backend**:
  * Kelompok hanya boleh membuat controller, model, request, service, dan migration di dalam:
    `backend/app/Modules/<NamaModulKelompok Anda>/`
* **Frontend**:
  * Kelompok hanya boleh membuat halaman UI, service, model, provider, dan sub-routes di dalam:
    `frontend/lib/features/<nama_fitur_kelompok Anda>/`

> [!WARNING]
> **ZONA TERPROTEKSI (SHARED CORE)**  
> File/folder berikut merupakan fondasi bersama:
> - `backend/app/Modules/Core/` & `backend/app/Modules/Cat/`
> - `backend/app/Models/User.php`
> - `backend/app/Providers/ModuleServiceProvider.php`
> - `frontend/lib/core/` (router, network, storage, theme, widgets)
> - `frontend/lib/features/shell/`  
> ⚠️ **DILARANG KERAS** mengubah isi file-file ini tanpa kesepakatan bersama antar kelompok atau Technical Lead!

---

### 2. 🗄️ Aturan Database & Migrasi (Database Rules)
1. **Pemberian Nama Tabel**:
   Nama tabel yang dibuat pada file migrasi wajib mencerminkan modul kelompok dan berformat jamak (*snake_case plural*), contoh:
   * Acumalaka: `feeding_spots`, `feeding_activities`
   * SUPER-SUB: `cat_encounters`, `user_cat_dex`
   * E-Nigma: `adoption_applications`, `adoption_followups`
   * Optimind: `incident_reports`
   * Rekans Caps: `identification_questions`, `identification_attempts`
2. **Relasi Foreign Key ke Tabel Shared (`users` dan `cats`)**:
   * Gunakan `foreignId('user_id')->constrained('users')`.
   * Tentukan aksi penghapusan dengan cermat (gunakan `nullOnDelete()` jika data riwayat ingin tetap tersimpan, atau `cascadeOnDelete()` jika data terikat penuh).
3. **Aturan Migrasi Tidak Boleh Diedit (Immutable Migrations)**:
   * File migration yang sudah di-merge ke branch `main` **TIDAK BOLEH DIUBAH ATAU DIHAPUS**.
   * Jika memerlukan penambahan kolom baru atau perubahan tipe data, buat file migration baru:
     ```bash
     php artisan make:migration add_columns_to_table_name --path=app/Modules/<ModulAnda>/Database/Migrations
     ```

---

### 3. 🌐 Aturan API & Standarisasi Response Backend
1. **Wajib Menggunakan Helper `ApiResponse`**:
   Semua Controller wajib mengembalikan JSON menggunakan `App\Support\ApiResponse` agar format response di frontend seragam:
   ```php
   // Respon Berhasil (200 OK)
   return ApiResponse::success($data, 'Kucing berhasil ditemukan');

   // Respon Data Baru Dibuat (201 Created)
   return ApiResponse::created($cat, 'Pendaftaran kucing berhasil');

   // Respon Error (4xx / 5xx)
   return ApiResponse::error('Kucing tidak ditemukan', 404, $errors);

   // Respon Paginasi
   return ApiResponse::paginated($cats, 'Daftar kucing berhasil dimuat');
   ```
2. **Routing Modul**:
   * Daftarkan route di file `backend/app/Modules/<NamaModul>/routes.php`.
   * Route ini sudah otomatis dimuat oleh `ModuleServiceProvider` dengan prefix URL `/api/v1/`.
   * Gunakan middleware `auth:sanctum` untuk endpoint yang memerlukan login pengguna.

---

### 4. 📱 Aturan Frontend Flutter
1. **State Management Bersama**:
   * Sesuai kesepakatan, gunakan package **`provider`** (`ChangeNotifierProvider`).
   * Setiap modul memiliki provider masing-masing (contoh: `FeedingSpotProvider`, `CatHunterProvider`, dll.) yang diletakkan pada folder `logic/`.
2. **Koneksi HTTP / API**:
   * Wajib menggunakan singleton `ApiClient()` dari `core/network/api_client.dart`.
   * Token autentikasi Bearer akan otomatis dipasang oleh interceptor pada setiap request yang dikirim.
3. **Konsistensi Tampilan & Tema (Design System)**:
   * Hindari penggunaan kode warna acak (hardcoded hex). Selalu gunakan token dari `AppConstants` (`AppConstants.primaryColor`, `AppConstants.dangerColor`, dll.).
   * Gunakan widget yang sudah distandarkan pada `core/widgets/`:
     * `CustomButton` (untuk tombol utama dengan status loading)
     * `LoadingIndicator` (untuk animasi loading)
     * `ErrorView` (untuk tampilan pesan error dan tombol coba lagi)
4. **Sub-Routing GoRouter**:
   * Definisikan daftar rute di `<nama_fitur>_routes.dart` masing-masing modul.
   * Rute tersebut sudah terpasang rapi ke dalam `StatefulShellRoute` pada `AppRouter` sehingga navigasi Bottom Navigation Bar tetap konsisten.

---

### 5. 🌿 Aturan Git Workflow & Kolaborasi Tim (Rules of Engagement)

```
main (BRANCH TERPROTEKSI - Selalu Stabil)
  │
  ├── feature/feeding-spot-acumalaka       (Kelompok 1)
  ├── feature/cat-hunter-supersub          (Kelompok 2)
  ├── feature/cat-adoption-enigma          (Kelompok 3)
  ├── feature/incident-report-optimind     (Kelompok 4)
  └── feature/cat-identification-rekanscaps(Kelompok 5)
```

1. **Dilarang Keras Push Langsung ke Branch `main`**:
   Semua pekerjaan wajib dilakukan pada branch fitur terpisah.
2. **Siklus Kerja Setiap Anggota Kelompok**:
   ```bash
   # 1. Pastikan branch main lokal Anda paling mutakhir
   git checkout main
   git pull origin main

   # 2. Buat atau pindah ke branch kelompok Anda
   git checkout -b feature/<nama-kelompok>-<nama-fitur>

   # 3. Lakukan pekerjaan (coding) hanya pada folder kelompok Anda
   git add .
   git commit -m "feat(feeding-spot): implementasi scan qr feeding spot"

   # 4. Sebelum membuat Pull Request (PR), tarik pembaruan terbaru dari main
   git checkout main
   git pull origin main
   git checkout feature/<nama-kelompok>-<nama-fitur>
   git merge main

   # 5. Push ke repository remote dan buka Pull Request (PR)
   git push origin feature/<nama-kelompok>-<nama-fitur>
   ```
3. **Penyelesaian Konflik (*Merge Conflict*)**:
   * Jika terjadi konflik pada file konfigurasi bersama (seperti `composer.json`, `pubspec.yaml`, `main.dart`, atau `routes/api.php`), **JANGAN MENIMPA / HAPUS KODE KELOMPOK LAIN SECARA SEPIHAK**.
   * Lakukan komunikasi langsung antar perwakilan kelompok untuk menyelesaikan baris kode yang bentrok.
4. **Penambahan Package / Library Baru**:
   * Jika ada kelompok yang membutuhkan library Composer atau dependency Flutter baru, wajib mengumumkan terlebih dahulu di grup koordinasi agar tidak terjadi bentrok versi library.

---

## 🚀 Panduan Menjalankan Proyek

### 1. Backend (Laravel)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```
Backend API akan berjalan di `http://127.0.0.1:8000/api/v1/`.

### 2. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```
