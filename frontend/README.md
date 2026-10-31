# Frontend Meowtopia

Panduan konfigurasi, struktur kode, dan integrasi Flutter untuk kelima kelompok. Baca [README utama](../README.md) untuk pembagian domain, setup backend, aturan branch, database, dan PR.

Frontend memakai Provider, Dio, GoRouter, Material 3, font Inter lokal, dan komponen visual bersama. Dashboard global menghubungkan fitur kelompok; alur bisnis tetap berada di modul pemiliknya.

## Prasyarat dan instalasi

Versi yang dipakai untuk pemeriksaan lokal adalah **Flutter 3.47.9 / Dart 3.13.7**. Syarat SDK pada `pubspec.yaml` dan lockfile selaras: **Dart >=3.13.0** dan **Flutter >=3.44.0**. Gunakan SDK yang memenuhi keduanya.

Dari root repository:

```powershell
cd frontend
flutter --version
flutter doctor
flutter pub get
flutter devices
flutter run -d web-server --web-port=5782
```

Buka **http://localhost:5782**. Mode data contoh aktif secara bawaan; backend belum diperlukan untuk melihat dashboard dan contoh alur AFS.

Jika SDK Flutter lokal di `.tools/flutter` memang sudah tersedia, perintah Flutter dapat dijalankan dengan:

```powershell
..\.tools\flutter\bin\flutter.bat pub get
..\.tools\flutter\bin\flutter.bat run -d web-server --web-port=5782
```

Folder `.tools/` diabaikan Git dan tidak tersedia otomatis setelah clone. Anggota lain menyiapkan Flutter sendiri di PATH atau memakai lokasi SDK yang mereka miliki.

`r` menjalankan hot reload, `R` hot restart, dan `q` menghentikan proses. Gunakan restart untuk perubahan route/provider. Perubahan `--dart-define` memerlukan proses run baru dengan parameter yang baru.

## Konfigurasi API per developer

Konfigurasi dibaca dari `lib/core/constants/app_constants.dart` ketika aplikasi dikompilasi:

| Parameter | Bawaan | Fungsi |
| --- | --- | --- |
| `MEOWTOPIA_DEMO` | `true` | Data contoh AFS dan Aktivitas; bukan mock seluruh aplikasi |
| `MEOWTOPIA_API_URL` | `http://10.0.2.2:8000/api/v1` | Base URL API, termasuk prefix `/api/v1` |

Gunakan `--dart-define` untuk alamat lokal masing-masing. Jangan mengganti konstanta bersama setiap kali berpindah komputer.

Browser pada komputer yang juga menjalankan backend:

```powershell
flutter run -d web-server --web-port=5782 --dart-define=MEOWTOPIA_DEMO=false --dart-define=MEOWTOPIA_API_URL=http://127.0.0.1:8000/api/v1
```

Android Emulator standar:

```powershell
flutter run -d <device-id> --dart-define=MEOWTOPIA_DEMO=false --dart-define=MEOWTOPIA_API_URL=http://10.0.2.2:8000/api/v1
```

HP fisik, dengan contoh IP komputer yang harus diganti sesuai jaringan:

```powershell
flutter run -d <device-id> --dart-define=MEOWTOPIA_DEMO=false --dart-define=MEOWTOPIA_API_URL=http://192.168.1.10:8000/api/v1
```

`<device-id>` diganti dengan ID dari `flutter devices`. Untuk HP, backend perlu berjalan dengan `php artisan serve --host=0.0.0.0 --port=8000`; HP dan komputer harus saling terjangkau pada jaringan lokal. `localhost` pada HP menunjuk ke HP itu sendiri.

### Platform dan kamera

- Android menargetkan API 24+ dan JDK 17. Izin kamera/internet sudah dideklarasikan; HTTP lokal diizinkan pada manifest debug.
- iOS menargetkan iOS 15+, dibangun di macOS dengan Xcode, dan memiliki deskripsi izin kamera. Untuk API di perangkat iOS, gunakan HTTPS atau sepakati konfigurasi pengembangan ATS bersama penanggung jawab platform.
- Kamera browser memerlukan izin pengguna dan secure context seperti localhost atau HTTPS. Browser HP yang membuka alamat IP melalui HTTP belum memenuhi syarat kamera tersebut.
- Aktifkan kamera setelah tindakan pengguna. Hentikan scanner saat tab tidak terlihat atau aplikasi masuk latar agar kamera tidak terus berjalan.
- Konfigurasi rilis, signing, endpoint HTTPS, dan kamera perangkat fisik tetap memerlukan pemeriksaan tersendiri.

## Struktur dan pemilik perubahan

```text
lib/
  main.dart                 Registrasi provider seluruh modul
  app.dart                  MaterialApp, tema, dan router
  core/
    constants/              Konfigurasi dasar
    navigation/             Katalog AppFeature
    network/                ApiClient dan ApiException
    router/                 Perakitan route semua modul
    storage/                Penyimpanan token
    theme/                  AppTheme dan MeowStyle
    utils/                  Utilitas lintas fitur
    widgets/                Komponen bersama
  features/
    home/                   Beranda dan Jelajah
    shell/                  Navbar global
    activity/               Aktivitas pribadi lintas fitur
    profile/                Profil global
    auth/                   Autentikasi bersama
    cat/                    Master kucing bersama
    feeding_spot/           Acumalaka
    cat_hunter/             SUPER-SUB
    cat_adoption/           E-Nigma
    incident_report/        Optimind
    cat_identification/     Rekans Caps
```

Di dalam modul, gunakan `data/` untuk model/service, `logic/` untuk provider, `ui/` untuk halaman/widget, dan `<fitur>_routes.dart` untuk route. Pertahankan struktur yang sudah ada; tidak semua halaman memerlukan provider baru.

Kelompok mengubah folder domainnya sendiri. `main.dart`, `app.dart`, `core/`, modul global/bersama, dependency, dan runner platform memerlukan koordinasi sesuai [aturan kolaborasi](../README.md#aturan-kolaborasi).

Source integrasi awal juga memuat perubahan pada modul lain, termasuk scanner identifikasi, padding navbar, format, dan penyesuaian API Flutter. Perubahan tersebut perlu tercantum dalam cakupan review; nama branch bukan bukti bahwa semua file di dalam commit milik satu kelompok.

## Navigasi global dan route fitur

| Tab global | Route | Fungsi |
| --- | --- | --- |
| Beranda | `/home` | Dashboard dan pintasan kelima fitur |
| Jelajah | `/explore` | Akses seluruh layanan |
| Pindai | `/identify` | Mengenali kucing melalui QR kalung |
| Aktivitas | `/activity` | Riwayat pribadi lintas fitur |
| Profil | `/profile` | Informasi akun dan akses login/logout |

Navbar global dipertahankan untuk seluruh aplikasi. Pindai di tengah merupakan QR kucing; QR feeding spot berada pada alur Acumalaka.

| Fitur | Route masuk | Route lain yang sudah tersedia |
| --- | --- | --- |
| Identifikasi | `/identify` | `/identify/photo`, `/identify/question`, `/identify/result` |
| Feeding spot | `/feeding` | `/feeding/spot/:id`, `/feeding/scan`, `/feeding/history` |
| Cat Hunter | `/hunter` | `/hunter/encounter`, `/hunter/leaderboard` |
| Adopsi | `/adoption` | `/adoption/apply`, `/adoption/my-cats` |
| Insiden | `/incidents` | `/incidents/create` |

Route AFS layar penuh dirangkai melalui `feedingFlowRoutes`, termasuk kamera, form, dan ringkasan pengajuan. Daftar spot menggunakan `feedingSpotRoutes`.

Saat menambah atau mengubah halaman:

1. Definisikan route di file route milik modul; gunakan subroute relatif seperti `photo` bila berada di bawah route induk.
2. Untuk tujuan yang tersedia, gunakan `context.go` saat mengganti tujuan utama dan `context.push` ketika membuka detail yang perlu kembali ke halaman sebelumnya.
3. Pendaftaran provider baru di `main.dart` dan branch baru di `AppRouter` dikoordinasikan agar registrasi kelompok lain tetap terjaga.
4. Lima branch pertama di `AppRouter` dipetakan ke navbar global. Jangan mengubah urutannya tanpa menyesuaikan dan meninjau shell.
5. Nama, route, ikon, warna, serta gambar sampul fitur global berasal dari `AppFeature`; selaraskan perubahan katalog dengan pemilik fitur.

## Pola kode, tampilan, dan aset

| Kebutuhan | Gunakan |
| --- | --- |
| HTTP dan Bearer token | `ApiClient()`; service cukup memanggil path relatif seperti `/feeding-spots` |
| Error API | `ApiException`, lalu tampilkan pesan yang dapat ditindaklanjuti |
| State lintas widget | Provider milik modul; registrasi global tetap di `main.dart` |
| Warna dan tema bersama | `AppConstants`, `AppTheme`, `MeowStyle` |
| Halaman dan kartu bersama | `MeowPage`, `GlassCard`, `CinematicCard` |
| Tombol/loading/error | Komponen yang sudah tersedia di `core/widgets/` |
| Pintasan global | `FeatureShortcuts` dan `AppFeature` |

- Gunakan `snake_case` untuk file, `UpperCamelCase` untuk class, dan `lowerCamelCase` untuk variabel/metode.
- Widget privat yang hanya dipakai satu halaman tetap berada di halaman/modul tersebut. Komponen lintas modul masuk `core/widgets/` setelah disepakati.
- Pertahankan validasi, kondisi loading, error, data kosong, dan pencegahan kirim berulang pada alur yang memerlukannya.
- Hindari menyalin logika bisnis kelompok lain atau membuat Dio/token storage baru untuk setiap fitur.
- Navbar melayang memakai body yang bergulir di belakangnya. Gunakan `MeowPage.scrollPadding(context)` untuk daftar agar item terakhir tetap dapat dijangkau; jangan menambahkan padding navbar berulang.
- Sorotan Beranda berganti otomatis tiap 6 detik dan bisa digeser, tanpa kontrol tambahan. Timer ditunda selama sentuhan aktif dan berhenti ketika Beranda/aplikasi tidak aktif; pengurangan gerakan menggunakan pergantian langsung.
- Font Inter disertakan lokal. Aset Figma berada di `assets/images/figma/` dan `assets/icons/figma/`; asal aset dicatat pada `assets/figma_sources.json`.
- Jika mengganti aset, perbarui semua referensi, deklarasi `pubspec.yaml` bila perlu, dan catatan asal/lisensinya. Pertahankan berkas lisensi font.
- Sepakati perubahan dependency terlebih dahulu. Commit `pubspec.yaml` bersama `pubspec.lock`; jalankan `flutter pub get` tanpa menghapus lockfile atau melakukan upgrade massal.

`.dart_tool/`, `.widget_preview/`, `.flutter-plugins-dependencies`, dan `build/` merupakan output lokal/generated. Jangan diedit manual atau dimasukkan sebagai source aplikasi.

## Mode data dan integrasi

`MEOWTOPIA_DEMO=true` menyiapkan data berikut:

| Area | Perilaku |
| --- | --- |
| AFS dan statistik Beranda | Spot, riwayat, poin, favorit, dan pengajuan contoh berada di memori |
| Aktivitas global | Menggabungkan riwayat AFS contoh dan contoh kategori lain |
| Login, identifikasi, Cat Hunter, adopsi, insiden | Tetap menggunakan layanan API masing-masing |

Banner pratinjau tidak ditampilkan pada UI. Pengajuan contoh tidak dikirim ke reviewer dan tidak menambah saldo server. Muat ulang aplikasi menghapus perubahan di memori. Nilai contoh tidak boleh dipakai untuk menyimpulkan bahwa integrasi backend sudah selesai.

Dengan `MEOWTOPIA_DEMO=false`:

- Daftar spot memakai `GET /feeding-spots`. Field `image_url`, `verified_count_14_days`, dan `aggregate_updated_at` dibaca bila tersedia.
- `activities_count` lama tidak dianggap sebagai jumlah aktivitas terverifikasi dalam 14 hari. Ketiadaan agregat ditampilkan sebagai data belum tersedia.
- Sesi AFS, unggah bukti, review, dan ledger belum tersedia sesuai rancangan baru; pembukaan sesi/pengiriman produksi masih diblokir.
- Endpoint lama `POST /feeding-spots/record` langsung memberi status verified dan 15 poin. Alur baru tidak memanggilnya sebagai pengganti proses review.
- Riwayat AFS pada implementasi saat ini belum mengambil riwayat server.
- Peta AFS merupakan ilustrasi lokasi spot, bukan GPS relawan atau peta navigasi produksi. Kebijakan GPS perlu keputusan tim.

Semua path API di atas relatif terhadap `MEOWTOPIA_API_URL`, yang sudah mencakup `/api/v1`.

### Aktivitas lintas fitur

`ActivityService` disiapkan untuk `GET /activities/mine`. Endpoint ini **belum tersedia di backend**. Frontend meminta autentikasi dan menampilkan kondisi gagal muat/coba lagi jika layanan belum siap.

Kontrak yang saat ini dibaca frontend:

| Field | Bentuk |
| --- | --- |
| `id` | Identitas event yang dapat dijadikan string |
| `feature` | `identification`, `feeding`, `hunter`, `adoption`, atau `incident` |
| `title` | String wajib |
| `description` | String opsional |
| `status_label` | String opsional; bawaan `Tercatat` |
| `created_at` | Waktu ISO 8601 dengan zona waktu untuk pengurutan/label waktu |

Respons menggunakan pembungkus `ApiResponse` dengan daftar event pada `data`. Backend harus membatasi event ke akun terautentikasi; daftar seluruh laporan pengguna bukan riwayat pribadi. Penambahan kategori atau perubahan field perlu diselaraskan dengan `ActivityEntry` dan `AppFeature`.

QR kucing mengikuti token backend berawalan `MEOW-CAT-`. Token feeding spot merupakan identitas terpisah dan harus cocok dengan spot yang dipilih.

## Pemeriksaan sebelum PR

Contoh dari folder `frontend` untuk perubahan Acumalaka; ganti path sesuai folder yang benar-benar dikerjakan:

```powershell
dart format lib/features/feeding_spot
flutter analyze
flutter build web --no-wasm-dry-run
git diff --check
git diff --name-only
```

Build web di atas memeriksa target JavaScript; dukungan WebAssembly tidak dinyatakan siap.

Saat ini folder tes otomatis frontend belum tersedia. Catat uji manual yang dilakukan: tujuan navbar, kembali dari detail, daftar panjang di belakang navbar, layar kecil, loading/error/data kosong, izin kamera, serta validasi/kirim ulang sesuai fitur yang diubah. Uji alur API pada mode API; keberhasilan memakai data contoh tidak membuktikan alur server bekerja.

PR mencantumkan perangkat/browser, mode data, alamat API tanpa token, hasil analyzer/build, dan fitur yang belum bisa diuji. File milik kelompok lain atau bagian bersama harus terlihat jelas dalam daftar perubahan dan reviewer.

## Kendala umum

| Gejala | Yang diperiksa |
| --- | --- |
| `flutter` tidak dikenali | PATH SDK; atau gunakan lokasi SDK lokal yang memang tersedia |
| Dependency gagal karena versi Dart | Versi pada `flutter --version` dibandingkan syarat `pubspec.lock` |
| Koneksi API gagal pada browser | Backend aktif; URL browser memakai `127.0.0.1`, bukan alamat emulator; cek CORS |
| Koneksi gagal pada HP | IP LAN, server bind `0.0.0.0`, firewall, jaringan, dan kebijakan HTTP perangkat |
| Browser menolak request | Izinkan origin pengembangan yang tepat pada CORS backend; periksa HTTP/HTTPS, jangan menonaktifkan keamanan browser |
| Spot API kosong | Seeder belum membuat spot; pemilik modul perlu menyiapkan data lokal |
| Aktivitas global 404 atau sesi AFS ditolak | Integrasi backend memang belum tersedia; lihat batas integrasi di atas |
| Kamera gagal | Izin pengguna, secure context browser, ketersediaan perangkat, dan lifecycle scanner |
| Perubahan flag/API tidak terlihat | Hentikan proses run lalu jalankan kembali dengan `--dart-define` yang baru |
| Konten terakhir tertutup navbar | Pemakaian `MeowPage.scrollPadding` dan kemungkinan padding ganda |

Untuk setup database, aturan migration, pemilihan branch, staging file, dan penggabungan PR, kembali ke [README utama](../README.md).
