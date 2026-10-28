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

---

## 🌿 Panduan Branching Git untuk 5 Kelompok

Semua kelompok bekerja dengan percabangan fitur yang terisolasi dari branch `main`:

```bash
# Branch per kelompok:
git checkout -b feature/feeding-spot-acumalaka
git checkout -b feature/cat-hunter-supersub
git checkout -b feature/cat-adoption-enigma
git checkout -b feature/incident-report-optimind
git checkout -b feature/cat-identification-rekanscaps
```

Dengan struktur modular ini:
- Backend: Tiap kelompok hanya fokus bekerja di `backend/app/Modules/<ModulKelompok>/`.
- Frontend: Tiap kelompok hanya fokus bekerja di `frontend/lib/features/<fitur_kelompok>/`.
- Konflik merge antar kelompok diminimalisir hingga 90%+.
