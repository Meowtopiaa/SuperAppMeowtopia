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
| **-** | **Core / Shared** | `Core` & `Cat` | `auth/` & `cat/` | Autentikasi Sanctum & OTP, Master data kucing & kalung QR, profil pengguna, ledger poin, scanner pusat. |
| **1** | **Acumalaka** | `FeedingSpot` | `feeding_spot/` | **Adopt Feeding Spot**: Manajemen titik makan resmi kampus, scan QR spot, unggah bukti foto (kamera saja), verifikasi kondisi mangkok makan, dan reward poin. |
| **2** | **SUPER-SUB** | `CatHunter` | `cat_hunter/` | **Telcat**: Game koleksi kucing kampus turn-based encounter (bukan AR virtual), encounter kalung QR, input kondisi kucing, log GPS crowdsourced heatmap, dex koleksi, & leaderboard. |
| **3** | **E-Nigma** | `CatAdoption` | `cat_adoption/` | **Adopsi & Rehoming**: Formulir komitmen/kesiapan adopter mahasiswa, verifikasi kelayakan admin, handover serah terima kucing via QR, monitoring "Kucing Saya" berkala (bi-weekly), kendala & pengembalian rehoming. |
| **4** | **Optimind** | `IncidentReport` | `incident_report/` | **Emergency Incident Reporting System**: Pelaporan darurat kucing sakit/terluka/terjebak, pin lokasi GPS darurat & foto insiden, status triage penanganan relawan/klinik. |
| **5** | **Rekans Caps** | `CatIdentification` | `cat_identification/` | **Sistem Identifikasi Kucing**: Identifikasi kucing tak dikenal / kalung hilang berbasis scan QR, pengenalan foto AI, dan kuesioner pertanyaan ciri fisik (corak bulu, ekor, telinga). |

---

## 🏗️ Struktur Direktori Proyek

```
Meowtopia/
├── .github/                             # CI, CODEOWNERS, dan PR Template
├── docker-compose.yml                   # PostGIS, Redis, MinIO, Mailpit
├── docs/                                # PRD.md, api/, erd/, decisions/
├── backend/                             # Backend Laravel (Modular Architecture)
│   ├── app/
│   │   ├── Http/Controllers/Controller.php
│   │   ├── Models/User.php              # Model User dengan ULID & Spatie Role
│   │   ├── Providers/
│   │   │   └── ModuleServiceProvider.php # Auto-loader migration & route tiap modul
│   │   ├── Support/
│   │   │   └── ApiResponse.php          # Standard JSON API response helper
│   │   └── Modules/
│   │       ├── Core/                    # Auth OTP, Role, Ledger Poin, Media, Idempotency
│   │       ├── Cat/                     # Master Data Kucing & Token QR Kalung
│   │       ├── CatIdentification/       # Modul Kelompok Rekans Caps
│   │       ├── FeedingSpot/             # Modul Kelompok Acumalaka
│   │       ├── CatHunter/               # Modul Kelompok SUPER-SUB
│   │       ├── CatAdoption/             # Modul Kelompok E-Nigma
│   │       └── IncidentReport/          # Modul Kelompok Optimind
│   ├── bootstrap/
│   ├── routes/api.php
│   ├── database/seeders/DatabaseSeeder.php
│   ├── composer.json
│   └── .env.example
│
└── frontend/                            # Mobile Frontend Flutter (Feature-First Architecture)
    ├── assets/
    │   └── images/logo.png
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart                     # MaterialApp + GoRouter + AppTheme
    │   ├── core/
    │   │   ├── constants/app_constants.dart
    │   │   ├── network/                 # Dio Client, Idempotency & Token Interceptor
    │   │   ├── router/app_router.dart   # ShellRoute + Tab Navigation
    │   │   ├── scanner/                 # Central ScannerPage & QR Parser
    │   │   ├── camera/                  # CameraCapturePage
    │   │   ├── hub/                     # CatActionRegistry
    │   │   └── theme/app_theme.dart     # Palette oranye hangat & modern
    │   └── features/
    │       ├── shell/                   # MainNavigationShell (Beranda, Berburu, Scan, Lapor, Profil)
    │       ├── home/                    # Beranda (PM)
    │       ├── profile/                 # Profil & Poin (PM)
    │       ├── auth/                    # Login, Register, OTP
    │       ├── cat/                     # Detail Kucing
    │       ├── feeding_spot/            # Acumalaka
    │       ├── cat_hunter/              # SUPER-SUB
    │       ├── cat_adoption/            # E-Nigma
    │       ├── incident_report/         # Optimind
    │       └── cat_identification/      # Rekans Caps
    └── pubspec.yaml
```

---

## 📜 Aturan Keras Pengkodean (*Hard Rules*)

Sumber kebenaran tunggal: `docs/PRD.md` (PRD Final v1.1).
1. **Satu tabel `cats`:** Hanya satu tabel master kucing. Modul dilarang membuat tabel kucing, saldo poin, atau laporan insiden sendiri.
2. **Poin & Status Kucing:** Poin hanya melalui `PointService::award()`. Status kucing hanya melalui `CatStatusService::change()`.
3. **RBAC & Autentikasi:** Izin diperiksa melalui permission atau policy Spatie, bukan string role. Registrasi tidak menerima role dari input pengguna.
4. **Idempotensi:** Endpoint tulis yang rawan duplikat (bertanda † di PRD) wajib menyertakan header `Idempotency-Key`.
5. **Format Respons API:** Wajib melalui `app/Support/ApiResponse`:
   * Sukses: `{ success: true, message, data, meta? }`
   * Gagal: `{ success: false, code, message, errors?, request_id }`
6. **Migrasi Database:** Hanya di `Modules/<Nama>/Database/Migrations` (M kapital), wajib memiliki `down()`, dan nama tabel berawalan prefix modul (`feeding_`, `adoption_`, `incident_`). Migrasi yang sudah di-merge tidak boleh diedit.
7. **Integritas Core:** Modul kelompok dilarang mengubah file Core, Providers, Support, routes root, atau `frontend/lib/core`.
8. **Acumalaka & GPS:** Tidak ada GPS untuk verifikasi pakan. GPS hanya dipakai di HP untuk mengurutkan daftar spot terdekat tanpa dikirim atau disimpan ke server.
9. **Privasi Data:** Data pribadi (nomor telepon, foto rumah, koordinat presisi) dilarang dikembalikan pada endpoint publik.
10. **Pesan Sukses:** Pesan sukses hanya dikembalikan setelah data benar-benar tersimpan di database.

---

## 🌿 Aturan Git Workflow & Kolaborasi Tim

```
main (Produksi - Tag Rilis Resmi)
  │
  └── development (Integrasi Utama & Fondasi Bersama v0.1-core)
        │
        ├── team/acumalaka        (Kelompok 1 - FeedingSpot)
        ├── team/super-sub        (Kelompok 2 - CatHunter)
        ├── team/enigma           (Kelompok 3 - CatAdoption)
        ├── team/optimind         (Kelompok 4 - IncidentReport)
        └── team/rekans-caps      (Kelompok 5 - CatIdentification)
```

1. **Struktur Branch Resmi**:
   * `main`: Produksi. Hanya diisi lewat PR dari `development` setelah uji integrasi terpadu.
   * `development`: Integrasi harian bersama. Semua branch kelompok bermuara di sini.
   * `team/<kelompok>`: Base branch resmi masing-masing kelompok capstone.
   * `team/<kelompok>/<tugas>`: Branch fitur individual anggota tim (misal `team/acumalaka/feat-intent-finalize`).
2. **Siklus Kerja Anggota Kelompok**:
   ```bash
   # 1. Pindah ke branch tim kelompok Anda dan sinkronkan development
   git checkout team/<kelompok>
   git fetch origin
   git merge origin/development

   # 2. Buat branch tugas individual
   git checkout -b team/<kelompok>/<nama-tugas>

   # 3. Kerjakan tugas pada modul kelompok Anda
   git add .
   git commit -m "feat(modul): deskripsi perubahan"

   # 4. Buka PR ke branch team/<kelompok> (internal tim)
   # 5. Ketua tim membuka PR dari team/<kelompok> ke development untuk direview PM
   ```
3. **Konvensi Commit**:
   Format: `tipe(modul): deskripsi`
   Contoh:
   * `feat(feeding_spot): implementasi finalisasi pemberian makan R1-R8`
   * `fix(incident_report): perbaiki validasi upload bukti foto darurat`
   * `refactor(cat_hunter): optimasi kalkulasi giliran encounter`

---

## 🚀 Panduan Menjalankan Proyek

### 1. Prasyarat & Docker (Local Dev)
Jalankan dependensi database PostgreSQL + PostGIS, Redis, MinIO, dan Mailpit:
```bash
docker compose up -d
```
* PostgreSQL/PostGIS: `localhost:5432` (db: `meowtopia`, user: `meowtopia`, pass: `secret`)
* Redis: `localhost:6379`
* MinIO Console: `http://localhost:9001` (user: `minio`, pass: `minio12345`)
* Mailpit (Email OTP Web UI): `http://localhost:8025`

### 2. Backend (Laravel API)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```
Backend REST API akan berjalan di `http://127.0.0.1:8000/api/v1/`.

### 3. Frontend (Flutter App)
```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```
*(Catatan: `10.0.2.2` untuk emulator Android. Untuk HP fisik, gunakan IP LAN laptop).*
