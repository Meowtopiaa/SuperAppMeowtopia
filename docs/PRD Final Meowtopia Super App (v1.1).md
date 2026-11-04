# PRD Final Meowtopia Super App (v1.1)

Tanggal: 3 November 2026. Pemilik: PM Meowtopia. Status: final untuk pengembangan. Perubahan hanya lewat PM dan dicatat di Decision Log (bagian 16).

Dokumen ini menggantikan PRD Gabungan v1.0 dan PRD Induk draf 31 Oktober sebagai satu acuan kerja. Lima PRD kelompok tetap menjadi sumber detail. Jika ada perbedaan, dokumen ini yang berlaku.

## 0. Cara Membaca

- **Terkunci:** keputusan yang berlaku dan tidak diubah lewat PR.
- **Default:** berlaku sampai pihak luar (kampus, mitra) mengonfirmasi. Mengubahnya hanya menyentuh bagian yang disebut di bagian 16.
- **P0:** wajib untuk pilot. **P1:** dikerjakan setelah P0 modul itu selesai. **P2:** pengembangan lanjutan.
- Kode status di database dan API memakai bahasa Inggris huruf besar (contoh VERIFIED). Label di aplikasi memakai bahasa Indonesia.
- Istilah: **Core** adalah bagian bersama yang dikelola PM. **Modul** adalah fitur milik satu kelompok. **Ledger** adalah catatan semua transaksi poin. **Idempoten** berarti pengiriman ulang tidak menggandakan hasil.

## 1. Produk, Tujuan, dan Batas

Meowtopia adalah super app mobile untuk mengelola kucing kampus: satu akun, satu data kucing, satu sistem poin.

**Pengguna:** mahasiswa, dosen, staf; relawan (caretaker); admin per modul; super admin (PM).

**Tujuan:**

- Identitas dan riwayat kucing yang konsisten di semua fitur.
- Identifikasi kucing lewat QR, pertanyaan, dan foto.
- Pencatatan pemberian makan di spot resmi dengan bukti dan verifikasi.
- Game koleksi yang tidak mewajibkan kontak fisik dengan kucing.
- Pengelolaan adopsi dari kelayakan sampai pengembalian.
- Pelaporan insiden dengan tiket, penugasan, dan riwayat.

**Di luar cakupan:** layanan medis atau darurat dengan jaminan waktu; pembuktian mutlak bahwa foto atau lokasi asli; biometrik wajah kucing; pembayaran; pengiriman WhatsApp otomatis; halaman web publik; reward riil atau penukaran poin; pelacakan lokasi di latar belakang.

**Indikator evaluasi (target uji, bukan janji operasional):**

| ID | Indikator | Target |
| --- | --- | --- |
| KPI-01 | cat\_id yang sama dipakai profil, game, adopsi, dan insiden | 100% skenario uji |
| KPI-02 | Adopsi ganda pada uji permintaan bersamaan | 0 |
| KPI-03 | Reward ganda pada retry dengan idempotency key sama | 0 |
| KPI-04 | Uji akses negatif (bukti pribadi, koordinat presisi, aksi admin) | Semua ditolak |
| KPI-05 | Submit insiden menghasilkan tiket atau pesan gagal yang akurat | Semua kasus lulus |
| KPI-06 | 95% permintaan katalog dan status selesai dalam 3 detik pada 20 pengguna bersamaan | Diukur di lingkungan uji |
| KPI-07 | UAT: catat peserta, skenario, hasil, hambatan | Target kelulusan ditetapkan PM |

## 2. Keputusan Terkunci

| Area | Keputusan |
| --- | --- |
| Frontend | Satu aplikasi Flutter (Android dan iOS). PWA atau React dari PRD Telcat dan Rekans Caps dihapus. |
| Backend | Laravel REST API di `/api/v1`, modular di `backend/app/Modules`. |
| Database | PostgreSQL dengan PostGIS. Jika hosting tidak mendukung PostGIS, lokasi disimpan sebagai lat dan lng dengan jarak Haversine dan heatmap berbasis grid. |
| Panel admin | Filament di Laravel (`/admin`), satu panel dengan menu per role. Cek kompatibilitas versi Filament dengan versi Laravel di `composer.json` sebelum memasang. Filament memakai sesi web, sedangkan API mobile memakai token Sanctum; keduanya memakai tabel users dan permission yang sama. |
| Login MVP | Email dan password dengan verifikasi email berdomain kampus. user\_type (mahasiswa, dosen, staf) ditentukan dari pemetaan domain di konfigurasi. Registrasi tidak menerima role dari input. SSO kampus menyusul lewat antarmuka `AuthProvider` setelah kampus mengonfirmasi akses (bagian 16). |
| QR | QR hanya berisi kode, dibaca scanner di dalam aplikasi. Tidak ada domain, deep link, atau halaman web. Format: `MTP1.C.<token>` untuk kucing dan `MTP1.S.<token>` untuk spot. Kode cadangan alfanumerik (unique\_code) dicetak di kalung untuk input manual. |
| Acumalaka dan GPS | Lokasi sesi diambil dari lokasi spot saat QR spot dipindai. GPS tidak dipakai untuk verifikasi. GPS hanya boleh dipakai di HP untuk mengurutkan daftar spot terdekat; jarak dihitung di aplikasi dan koordinat pengguna tidak dikirim ke server maupun disimpan. |
| Master data kucing | Satu tabel `cats`. Skema dikunci PM, Rekans Caps mengimplementasi dan mengkurasi. Google Sheets hanya sumber import awal. |
| Poin | Satu ledger di Core, dimiliki PM, prioritas P0. |
| Insiden | Optimind pemilik tunggal laporan insiden fisik di kampus. Kendala adopsi tetap di E-Nigma dan ditautkan ke tiket Optimind bila ia insiden di kampus. |
| ML | Layanan FastAPI milik Rekans Caps; Flutter hanya memanggil Laravel. Flag `ML_ENABLED` mengaktifkan atau mematikan jalur foto. |
| Storage media | Object storage privat kompatibel S3 (MinIO di dev) dengan URL bertanda tangan. |
| Notifikasi | Notifikasi in-app sebagai sumber status; push FCM sebagai kanal tambahan. |
| Peta | flutter\_map dengan tile OpenStreetMap untuk dev dan demo. |
| Waktu | Disimpan UTC, ditampilkan WIB. Waktu bisnis selalu dari server. |
| ID | ULID untuk semua primary key dan foreign key. |
| Repo dan branch | Monorepo. Branch `main` (produksi), `development` (integrasi), lima branch tim `team/acumalaka`, `team/rekans-caps`, `team/super-sub`, `team/enigma`, `team/optimind`. |

## 3. Peran, Izin, dan Kepemilikan

### 3.1 Peran

Sistem memakai Spatie Laravel-Permission. Satu pengguna boleh punya beberapa role. Kode hanya mengecek permission, tidak membaca string role.

| Role | Keterangan |
| --- | --- |
| super\_admin | PM; konfigurasi, penetapan role, audit |
| user | Pengguna terdaftar dan terverifikasi email |
| caretaker | Relawan penerima penugasan insiden |
| vet | Kontak dokter hewan atau klinik mitra (data, bukan login) |
| data\_curator | Admin data kucing dan QR (Rekans Caps) |
| adoption\_admin | Pengelola adopsi (E-Nigma) |
| game\_admin | Admin parameter game (SUPER-SUB) |
| spot\_admin | Admin spot pakan (Acumalaka) |
| incident\_admin | Admin atau dispatcher insiden (Optimind) |

Reviewer foto pakan bukan role, melainkan permission `feeding.review` yang diberikan ke spot\_admin atau akun tertentu. Peran istimewa hanya ditetapkan super\_admin lewat panel admin, tidak ada registrasi mandiri, dan setiap perubahan dicatat (aktor, waktu, role lama dan baru).

**Permission utama:** cat.edit, cat.curate, cat.qr.regenerate, spot.manage, feeding.review, game.config, adoption.review, adoption.approve, adoption.set\_ready, adoption.verify\_return, incident.view, incident.dispatch, incident.close, points.config, user.manage.

### 3.2 Kewenangan dan batas

| Peran | Boleh | Tidak boleh |
| --- | --- | --- |
| user | Mengelola akun sendiri, scan, membuat laporan, memakai fitur sesuai syarat | Menetapkan role, mengubah profil kucing, melihat data orang lain |
| user dengan user\_type mahasiswa dan email terverifikasi | Mengajukan adopsi | Dosen dan staf tidak dapat mengajukan |
| data\_curator | Verifikasi profil, QR, antrean kucing tak teridentifikasi | Mengakses bukti pribadi adopsi |
| permission feeding.review | Memeriksa pengajuan yang ditugaskan | Mereview pengajuan sendiri, mengubah saldo langsung |
| adoption\_admin | Menilai kelayakan, menetapkan kesiapan, memeriksa follow-up dan pengembalian | Akses di luar tugas; semua aksi diaudit |
| incident\_admin | Antrean, urgensi, penugasan |  |
| caretaker | Melihat dan memperbarui insiden yang ditugaskan | Melihat semua laporan atau data privat |

### 3.3 Kepemilikan domain

Setiap tabel punya satu pemilik. Modul lain membaca, atau mengubah lewat service dan event, tidak lewat UPDATE langsung.

| Domain | Pemilik | Modul lain boleh |
| --- | --- | --- |
| Auth, users, RBAC, media, notifikasi, audit, scanner, kamera | Core (PM) | Memakai |
| cats, foto, QR token, perjumpaan, antrean kurasi | Rekans Caps (skema dikunci PM) | Merujuk cats.id; menambah tabel satelit sendiri |
| Ledger, aturan poin, leaderboard, badge | Core (PM) | Memberi poin lewat PointService |
| Laporan insiden dan penugasan | Optimind | Membuat laporan lewat API |
| Adopsi, follow-up, pengembalian, kendala adopsi | E-Nigma | Membaca status |
| Encounter, koleksi, rarity | SUPER-SUB | Membaca |
| Spot, aktivitas pakan, review | Acumalaka | Membaca |
| Layanan ML | Rekans Caps | Dipanggil lewat Laravel |

## 4. Core Platform

### 4.1 Akun dan verifikasi

1. Registrasi menerima name, email, password. Server memeriksa domain email terhadap `ALLOWED_EMAIL_DOMAINS`, menentukan user\_type dari `EMAIL_DOMAIN_TYPES` (contoh: domain mahasiswa menjadi mahasiswa), lalu mengirim email verifikasi. Akun belum terverifikasi hanya bisa login dan membuka halaman verifikasi.
2. Payload yang mengandung role, user\_type, atau permission diabaikan. Role dasar `user` ditetapkan server.
3. Login mengembalikan token Sanctum; logout mencabut token aktif.
4. Satu akun per email. Akun yang dinonaktifkan tidak bisa login. Pengguna dapat meminta hapus akun: data pribadi dianonimkan, ledger dan riwayat tetap.
5. Domain kampus yang sebenarnya diisi PM di konfigurasi setelah dikonfirmasi kampus. Verifikasi email adalah penyangga sementara; ia tidak sekuat SSO. Setelah SSO tersedia, `AuthProvider` diganti tanpa mengubah tabel users.

### 4.2 Data kucing dan QR

- `cats` adalah master tunggal. Atribut tidak diketahui boleh kosong; dugaan tidak disimpan sebagai fakta.
- Setiap kucing punya `unique_code` (kode cetak pendek) dan token QR di `cat_qr_tokens`. Token acak 32 karakter; satu token aktif per kucing; token lama dicabut saat diganti dan riwayat tag tersimpan.
- Isi QR kucing: `MTP1.C.<token>`. Isi QR spot: `MTP1.S.<token>`. Scanner menolak tipe yang salah di konteksnya dan tidak mengubah data.
- QR bukan bukti kepemilikan atau keberadaan fisik. Pembuatan QR cetak lewat panel admin (lembar QR siap cetak).
- Penggabungan profil ganda hanya oleh data\_curator: ID lama dipetakan ke ID utama dan diaudit; riwayat tidak dihapus.
- Profil untuk pengguna umum hanya memuat atribut yang boleh dibuka. Koordinat presisi, bukti adopsi, kontak pelapor, dan token tidak pernah dikirim.

### 4.3 Scanner pusat dan hub aksi

- Satu `ScannerPage` di `frontend/lib/core/scanner` dengan parameter tujuan: `profile`, `encounter`, `pickup`, `return`, `feeding`. Mendukung input kode manual.
- Scanner memanggil `GET /scan/resolve` yang mengembalikan tipe (cat atau spot) dan ID tujuan. Resolve tidak memberi poin dan tidak mengubah status.
- Halaman profil kucing adalah hub. `GET /cats/{id}/actions` mengembalikan aksi yang tersedia (id, modul, label, enabled, alasan) berdasarkan status kucing dan penyedia aksi tiap modul. Aplikasi hanya menampilkan id yang terdaftar.

| Aksi | Modul | Tampil bila |
| --- | --- | --- |
| game.encounter | Cat Hunter | presence ON\_CAMPUS dan health bukan SICK atau INJURED |
| adoption.apply | Adopsi | adoption\_status READY dan pengguna memenuhi syarat |
| incident.report | Insiden | selalu |
| feeding.start | Pakan | kucing terkait spot |

### 4.4 Perjumpaan (cat\_sightings)

Satu log untuk semua modul. Kolom request\_id mencegah duplikat saat retry. Scan profil biasa tidak membuat sighting otomatis. Sighting dibuat oleh encounter game, aktivitas pakan yang memuat cat\_id, pengambilan atau pengembalian adopsi, dan tombol "Saya melihat kucing ini" di profil. Deduplikasi default: satu sighting per pengguna, kucing, dan sumber dalam 30 menit.

### 4.5 Poin dan ledger

- Semua modul memberi poin lewat `PointService::award()` dengan `idempotency_key`. Modul tidak menulis saldo.
- `point_rules` menyimpan nilai, batas harian per aturan, dan batas total harian. Admin dapat mengubahnya tanpa rilis.
- Ledger bersifat tambah-saja. Koreksi dibuat sebagai transaksi reversal yang merujuk transaksi asal.
- Saldo adalah cache dari ledger; acuan data utama tetap ledger. Leaderboard dihitung dari ledger dan dapat difilter per sumber (misalnya skor game hanya dari aturan `game.*`).
- Status aktivitas (VERIFIED) dan status poin (CREDITED) ditampilkan terpisah. Aktivitas VERIFIED tetap VERIFIED walau poin PENDING, FAILED, atau tidak memenuhi syarat.
- Ledger berada di database yang sama dengan modul, jadi pemberian poin dipanggil dalam transaksi database yang sama dan tidak memerlukan outbox. Jika kelak dipisah, tambahkan outbox dan rekonsiliasi.
- Tidak ada poin untuk membuka profil atau identifikasi. Laporan yang sama tidak menerima dua reward hanya karena berawal dari game lalu dikirim ke insiden.

### 4.6 Peta dan privasi lokasi

- Satu komponen peta dengan layer: persebaran kucing, insiden, dan spot. Setiap layer punya API dan izin sendiri.
- Data kucing untuk pengguna umum dikaburkan di server ke grid 50 meter dan ditunda 60 menit (default, bagian 16). Koordinat mentah tidak pernah dikirim ke respons publik.
- Lokasi insiden presisi hanya untuk incident\_admin dan caretaker yang ditugaskan. Nomor kontak dan media tidak muncul di daftar.
- Lokasi kucing, insiden, spot, dan pengembalian adalah data berbeda. Jangan menulis semua koordinat ke kolom `last_seen` kucing.
- Izin kamera dan lokasi diminta saat dibutuhkan dengan penjelasan. Tidak ada pelacakan latar belakang. Penolakan izin menghasilkan jalur penanganan sesuai fitur.

### 4.7 Media dan retensi

- Unggahan lewat `POST /media`. Server memvalidasi ukuran (maksimal 5 MB per foto), tipe aktual, dan kemampuan decode, lalu membangkitkan nama file sendiri.
- Media privat hanya dapat dibuka pemilik dan petugas berwenang lewat URL bertanda tangan (berlaku 10 menit).
- Kamera dalam aplikasi tanpa galeri dipakai untuk bukti pakan dan bukti adopsi. Optimind mengizinkan foto atau video.
- Retensi default: foto pakan VERIFIED 180 hari; foto pakan REJECTED 30 hari setelah keputusan final; bukti adopsi dan foto tempat tinggal 1 tahun setelah proses selesai; media insiden 1 tahun setelah tiket ditutup. Penghapusan dijalankan job terjadwal; pengecualian audit disetujui pengelola data.

### 4.8 Notifikasi dan audit

- Setiap notifikasi punya status QUEUED, SENT, FAILED, atau READ. Kegagalan kirim tidak membatalkan transaksi domain dan tidak dilaporkan sebagai terkirim. Pesan sukses hanya setelah penyimpanan relevan berhasil.
- Aksi penting diaudit: aktor, aksi, jenis dan ID objek, waktu server, hasil, alasan. Audit tidak menyimpan token, password, atau salinan data sensitif.

## 5. Aturan Status dan Transisi

Sistem menolak transisi di luar tabel dengan respons 409. Admin tidak dapat memaksa transisi tanpa alasan dan audit. Riwayat tidak dihapus saat status berubah.

### 5.1 Kucing (tiga dimensi independen di tabel cats)

| Dimensi | Nilai | Pemilik perubahan |
| --- | --- | --- |
| presence\_status | ON\_CAMPUS, ADOPTED, MISSING, DECEASED | Core lewat event modul lain; konfirmasi admin untuk MISSING dan DECEASED |
| health\_status | HEALTHY, SICK, INJURED, UNDER\_CARE | Optimind |
| adoption\_status | UNREVIEWED, READY, ADOPTED, RETURN\_PENDING, RETURNED\_REVIEW | E-Nigma |

Kucing baru berstatus UNREVIEWED. Atribut game (Common, Rare, Epic, tamed) bukan status kucing; ia milik SUPER-SUB.

| Dari | Ke | Aktor |
| --- | --- | --- |
| UNREVIEWED atau RETURNED\_REVIEW | READY | adoption\_admin (dengan alasan) |
| READY | ADOPTED | Transaksi pengambilan berhasil |
| ADOPTED | RETURN\_PENDING | Pengajuan pengembalian disetujui |
| RETURN\_PENDING | RETURNED\_REVIEW | adoption\_admin memverifikasi bukti |
| RETURN\_PENDING | ADOPTED | Pengembalian ditolak |

READY tidak boleh ditetapkan saat adopsi aktif atau bukti pengembalian masih diperiksa. Kucing yang baru dikembalikan tidak otomatis READY.

### 5.2 Kelayakan adopter

DRAFT, SUBMITTED, REVISION\_REQUESTED, APPROVED, REJECTED. Pengguna mengirim DRAFT; admin meminta revisi, menyetujui, atau menolak dengan alasan; pengguna dapat mengirim ulang revisi. APPROVED bukan adopsi aktif. Hasil pemeriksaan otomatis (precheck\_passed) terpisah dari keputusan admin.

### 5.3 Adopsi

ACTIVE, RETURN\_REQUESTED, RETURN\_APPROVED, RETURN\_EVIDENCE\_PENDING, CLOSED\_RETURNED. Hanya transaksi pengambilan yang berhasil membuat ACTIVE. Pengajuan dan bukti pengembalian tidak menutup adopsi; hanya verifikasi admin yang menutup (CLOSED\_RETURNED). Penolakan mengembalikan ke ACTIVE. Penahanan sementara kucing saat proses pengambilan disimpan di `adoption_pickup_locks`, bukan sebagai baris adopsi.

### 5.4 Aktivitas pakan dan reward

| Objek | Nilai | Ketentuan |
| --- | --- | --- |
| Aktivitas | DRAFT, SUBMITTED, UNDER\_REVIEW, VERIFIED, REJECTED, EXPIRED | DRAFT dibuat saat QR spot dipindai; menjadi EXPIRED bila melewati batas waktu. Kegagalan teknis tidak otomatis menghasilkan VERIFIED. |
| Reward | NOT\_ELIGIBLE, PENDING, CREDITED, FAILED, REVERSED | PENDING bukan saldo. CREDITED setelah ledger berhasil. Koreksi menghasilkan REVERSED lewat transaksi reversal. |

### 5.5 Insiden

| Status | Makna |
| --- | --- |
| RECEIVED | Tiket tersimpan dan masuk antrean |
| WAITING\_ASSIGNMENT | Belum ada penanggung jawab yang menerima |
| ASSIGNED | Satu penanggung jawab utama ditetapkan atau menerima tugas |
| IN\_PROGRESS | Penanganan dimulai |
| RESOLVED | Tindakan lapangan selesai, catatan penanganan tersimpan |
| CLOSED | Admin menutup setelah peninjauan |

REJECTED dan DUPLICATE hanya oleh admin dengan alasan dan menyimpan riwayat. Penugasan, perubahan status, dan kegagalan notifikasi dicatat terpisah.

### 5.6 Aturan lintas modul

- Pengambilan adopsi berhasil: adoption\_status ADOPTED dan presence\_status ADOPTED. Kucing hilang dari encounter game, katalog adopsi, dan notifikasi kucing tidak terscan. Koleksi dan riwayat pengguna tetap.
- Pengembalian diverifikasi: presence\_status kembali ON\_CAMPUS, adoption\_status RETURNED\_REVIEW. Masa tunggu 30 hari penuh dimulai pada waktu verifikasi.
- MISSING atau DECEASED: disembunyikan dari game dan adopsi, riwayat tetap. Perubahan dikonfirmasi admin berwenang, bukan otomatis dari satu laporan.
- health\_status SICK atau INJURED: encounter tidak dimulai dan jalur laporan terbuka. Laporan SICK atau INJURED mengubah health\_status saat admin memverifikasinya, dan kembali ke HEALTHY atau UNDER\_CARE saat tiket selesai.
- Kondisi yang dipilih pengguna di game adalah observasi dan tidak mengubah status resmi kucing.
- Adopsi dan kelayakan dipisah: kelayakan APPROVED tidak membuat adopsi aktif.

### 5.7 Aturan integritas

- Satu adopsi aktif per kucing dan satu per adopter, ditegakkan dengan indeks unik parsial di database dan transaksi dengan penguncian baris (`lockForUpdate`). Pemeriksaan di aplikasi saja tidak cukup.
- Keunikan ditegakkan di database untuk: periode follow-up per adopsi, satu aktivitas pakan per sesi, idempotency\_key ledger, satu penanggung jawab insiden aktif, dan satu token QR aktif per kucing.
- Perubahan status adopsi dan pembentukan adopsi terjadi dalam satu transaksi.
- Riwayat transaksi dan keputusan tidak dihapus diam-diam.

## 6. Kebutuhan Modul

Setiap baris punya prioritas dan kriteria penerimaan yang dapat diuji. Parameter angka adalah default yang tersimpan di tabel pengaturan dan dapat diubah tanpa rilis.

### 6.1 Core (PM)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| CORE-01 | P0 | Registrasi, login, logout. Token dicabut saat logout. Payload role, user\_type, atau permission diabaikan; uji role=admin menghasilkan akun dasar. |
| CORE-02 | P0 | Verifikasi email lewat kode OTP 6 digit (berlaku 15 menit). Email di luar ALLOWED\_EMAIL\_DOMAINS ditolak. user\_type ditentukan server dari domain. Akun belum terverifikasi tidak dapat memakai fitur selain verifikasi. |
| CORE-03 | P0 | Izin diperiksa di server untuk setiap aksi dan objek. Pengguna A yang membaca bukti pengguna B menerima 403 atau 404 tanpa isi privat. |
| CORE-04 | P0 | Penetapan dan pencabutan role oleh super\_admin lewat panel; aktor, waktu, role lama dan baru tercatat. |
| CORE-05 | P0 | Unggah media divalidasi server; akses media privat lewat URL bertanda tangan. |
| CORE-06 | P0 | Ledger poin, aturan poin, dan PointService (bagian 4.5 dan 9). |
| CORE-07 | P0 | Scanner pusat, komponen kamera, dan hub aksi di Flutter (bagian 4.3 dan 10). |
| CORE-08 | P0 | Notifikasi in-app dengan status QUEUED, SENT, FAILED, READ. |
| CORE-09 | P0 | Audit log untuk aksi penting tanpa menyimpan data sensitif. |
| CORE-10 | P0 | Layer peta dengan privasi lokasi sesuai bagian 4.6. |
| CORE-11 | P1 | Leaderboard (mingguan dan semua waktu) dan badge. |
| CORE-12 | P1 | Push FCM; kegagalan tercatat, status tetap terlihat di notifikasi in-app. |

### 6.2 Data Kucing dan Identifikasi (Rekans Caps)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| CAT-01 | P0 | Setiap profil terverifikasi punya cat\_id unik dan stabil. Penggabungan duplikat butuh keputusan data\_curator, pemetaan ID lama, dan audit. |
| CAT-02 | P0 | Data minimum: nama atau label, foto rujukan, atribut fisik yang diketahui, unique\_code, tiga status, timestamp. Atribut tak diketahui boleh kosong. |
| CAT-03 | P0 | Penerbitan, penggantian, dan pencabutan token QR. Token lama ditolak, token baru mempertahankan cat\_id, riwayat tersimpan. Lembar QR siap cetak dari panel admin. |
| CAT-04 | P0 | Scan QR kucing membuka profil yang tepat. QR tidak valid, dicabut, atau bertipe spot menampilkan pesan yang bisa ditindaklanjuti. |
| CAT-05 | P0 | Input kode manual (unique\_code) bila QR rusak atau tidak terbaca; jalur identifikasi alternatif ditawarkan. Penggantian tag tidak membuat cat\_id baru. |
| CAT-06 | P0 | Perintah `php artisan cats:import file.csv` mengimpor data awal dari ekspor Google Sheets dengan validasi. Sheets bukan database produksi. |
| CAT-07 | P0 | Identifikasi lewat pertanyaan (Akinator): jawaban Ya, Tidak, Tidak Tahu menyaring kandidat memakai atribut terverifikasi; hasil berupa kandidat atau INCONCLUSIVE. Kandidat tidak menjadi identitas pasti tanpa konfirmasi pengguna. |
| CAT-08 | P0 | Antrean kucing tak teridentifikasi (unidentified\_sightings) beserta halaman kurasi untuk data\_curator. Kategori kucing baru dari Optimind masuk antrean ini. |
| CAT-09 | P0 | Respons publik hanya memuat atribut yang boleh dibuka. |
| CAT-10 | P1 | Identifikasi foto: deteksi kucing, lalu klasifikasi warna atau pola untuk menyaring kandidat. Gagal deteksi atau kualitas buruk meminta coba lagi atau beralih ke pertanyaan. Dengan ML\_ENABLED=false, jalur ini dilewati. |
| CAT-11 | P1 | Simpan versi model, input, kategori, jawaban, kandidat, konfirmasi. Persentase confidence tidak ditampilkan sampai metodenya diuji; angka dummy tidak boleh tampil. |
| CAT-12 | P1 | Evaluasi model dengan dataset uji terpisah dan terdokumentasi (jumlah data, kelompok warna, metrik, keterbatasan). |

Identifikasi tidak memberi poin.

### 6.3 Adopt Feeding Spot (Acumalaka)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| AFS-01 | P0 | Spot\_admin membuat, mengubah, menonaktifkan spot dan QR. ACTIVE dapat membuka sesi; TEMPORARILY\_UNAVAILABLE tampil dengan alasan tetapi tidak dapat membuka sesi; INACTIVE tidak tampil ke pengguna umum. |
| AFS-02 | P0 | Peta dan daftar spot dengan legenda status. Data agregat yang usang diberi label, tidak dianggap nol. Daftar diurutkan dari yang terdekat bila pengguna mengizinkan lokasi; bila izin ditolak, daftar tetap tampil dan diurutkan berdasarkan nama. |
| AFS-03 | P0 | Scan QR spot yang valid dan aktif membuat aktivitas berstatus DRAFT dengan lokasi dari spot. QR kucing atau token dicabut ditolak tanpa membuat data. |
| AFS-04 | P0 | Intent dicatat server paling lambat 15 menit sejak sesi dibuat; finalisasi paling lambat 60 menit, memakai jam server. 1 sampai 3 foto dari kamera aplikasi, tanpa galeri. Unggah ulang sebelum batas waktu tidak mensyaratkan foto baru. |
| AFS-05 | P0 | Idempotency key dan satu aktivitas per sesi. Key sama dengan payload sama mengembalikan hasil awal; key sama dengan payload berbeda menghasilkan 409. |
| AFS-06 | P0 | Cooldown 6 jam untuk pengguna dan spot yang sama, dihitung dari pengajuan lengkap terakhir termasuk yang ditolak. Retry bukan kegiatan baru. |
| AFS-07 | P0 | Mesin aturan R1, R2, R4, R5, R6, R8 (Lampiran A) menyimpan hasil dan alasan tiap pemeriksaan. Review wajib untuk dua pengajuan pertama pengguna, sampel acak 10% (hasil sampling disimpan agar retry tidak mengundi ulang), dan semua yang ber-flag. Reviewer tidak boleh mereview miliknya sendiri. Error teknis tidak otomatis VERIFIED. |
| AFS-08 | P0 | Status aktivitas dan status reward ditampilkan terpisah. VERIFIED tetap VERIFIED walau reward PENDING, FAILED, atau NOT\_ELIGIBLE. |
| AFS-09 | P0 | Agregat 14 hari terakhir per spot dan zona (jumlah VERIFIED, waktu pembaruan). Aktivitas tidak diartikan sebagai jumlah makanan atau tingkat lapar kucing. |
| AFS-10 | P0 | cat\_id opsional lewat scan QR kalung. Kegagalan layanan kucing tidak menggagalkan pengajuan. |
| AFS-11 | P1 | Reward potensial 5 sampai 20 poin dihitung sekali saat finalisasi (Lampiran A.1), dikredit setelah VERIFIED dan lolos kuota 3 reward per hari lewat PointService. Sebelum ledger siap, reward dinonaktifkan secara jelas dan tidak membuat saldo palsu. |
| AFS-12 | P1 | Koreksi, banding, reversal, dan rekonsiliasi dengan alasan dan audit. R7 (pHash) bila fitur tersedia. |

Kerusakan fasilitas atau QR ditangani spot\_admin dan tidak memberi poin.

### 6.4 Cat Hunter (SUPER-SUB)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| GAME-01 | P0 | Scan QR kucing membuka profil dengan pilihan Dekati. Scan sendiri tidak memberi poin dan tidak mengoleksi kucing. |
| GAME-02 | P0 | Pengguna memilih kondisi kucing berdasarkan pengamatan. Pilihan sakit atau terluka tidak memulai game; pengguna diarahkan ke form insiden berisi cat\_id. Kondisi pilihan pengguna tidak mengubah status resmi. |
| GAME-03 | P0 | Encounter berbasis giliran (maksimal 5) dengan aksi virtual Elus dan Biarkan. Server menghitung trust dan hasil (jinak, gagal, kabur). Mekanik angka mengikuti PRD SUPER-SUB dan disimpan di game\_settings. |
| GAME-04 | P0 | Koleksi (Cat-dex) membedakan belum ditemui, terlihat, dan berhasil dijinakkan. Encounter gagal boleh membuat status terlihat; hanya hasil jinak yang mengoleksi. |
| GAME-05 | P0 | Poin lewat ledger. Cooldown default: perolehan poin dari kucing yang sama sekali per 6 jam per pengguna; jeda coba lagi setelah gagal 15 menit; Sapa kucing jinak 6 jam. Semua dari game\_settings. |
| GAME-06 | P0 | Lokasi diminta saat encounter untuk peta. Bila izin ditolak, encounter tetap berjalan, lokasi kosong, dan sighting itu tidak masuk peta. Geofence opsional lewat game\_settings.geofence\_enabled (default false) dan radius encounter\_radius\_m (default 50). |
| GAME-07 | P0 | Peta publik memakai data yang dikaburkan dan ditunda di server (bagian 4.6). |
| GAME-08 | P0 | Kucing berstatus presence bukan ON\_CAMPUS tidak dapat di-encounter (CAT\_NOT\_AVAILABLE). |
| GAME-09 | P1 | Leaderboard game dihitung dari transaksi aturan game.\* saja. |
| GAME-10 | P1 | Badge dan streak. |
| GAME-11 | P1 | Cache koleksi dapat dibuka offline; transaksi baru butuh koneksi. |

Etika: aplikasi menampilkan anjuran untuk tidak mengejar, memaksa kontak, atau memberi makan sembarangan. Kalung breakaway dan rancangan tag perlu persetujuan pengelola kucing.

### 6.5 Adopsi dan Rehoming (E-Nigma)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| ADP-01 | P0 | Hanya user\_type mahasiswa dengan email terverifikasi yang dapat mengajukan kelayakan. Dosen dan staf menerima NOT\_STUDENT. |
| ADP-02 | P0 | Form kelayakan dapat disimpan sebagai draf tanpa memilih kucing. Pengiriman memerlukan jawaban wajib, foto tempat tinggal (kamera aplikasi), dan persetujuan komitmen versi yang berlaku. Data pribadi hanya dapat dilihat pemilik dan adoption\_admin. |
| ADP-03 | P0 | Pemeriksaan awal (kelengkapan, izin tempat tinggal, adopsi aktif, masa tunggu). precheck\_passed berbeda dari keputusan admin. |
| ADP-04 | P0 | Admin meminta perbaikan, menyetujui, atau menolak dengan alasan; aktor dan waktu tercatat. Persetujuan tidak membuat adopsi aktif. |
| ADP-05 | P0 | adoption\_admin menetapkan kucing READY dengan alasan dan riwayat. Kucing baru atau baru dikembalikan tidak otomatis READY. |
| ADP-06 | P0 | Pengambilan: pengguna APPROVED memindai QR kucing, mengambil foto kucing berkalung dari kamera, dan mengonfirmasi tanggung jawab. Server memeriksa ulang semua syarat; hasil sukses hanya setelah seluruh transaksi tersimpan. |
| ADP-07 | P0 | Uji bersamaan: satu transaksi aktif per kucing dan per adopter. Kucing ditahan sementara di adoption\_pickup\_locks selama 48 jam (default); kunci dilepas bila batal atau habis. |
| ADP-08 | P0 | Halaman Kucing Saya hanya menampilkan adopsi ACTIVE. Kelulusan calon adopter ditampilkan terpisah dari status adopsi. |
| ADP-09 | P0 | Follow-up pertama 14 hari setelah pengambilan, lalu tiap 14 hari selama tiga bulan kalender pertama (jika tanggal akhir tidak ada, pakai hari terakhir bulan). Periode unik per adopsi, disimpan UTC dan ditampilkan WIB. |
| ADP-10 | P0 | Tiap follow-up memuat foto kamera, kondisi, dan kendala. Pengiriman terlambat tetap diterima; periode tidak diduplikasi. |
| ADP-11 | P0 | Pengembalian biasa setelah tiga bulan kalender; sebelumnya lewat jalur darurat dengan alasan. Admin menerima, meminta perbaikan, atau menolak. |
| ADP-12 | P0 | Bukti pengembalian (QR, foto kamera, waktu server, lokasi bila tersedia) berarti menunggu verifikasi, bukan selesai. Adopsi tetap ACTIVE dan kuota terikat sampai admin memverifikasi. Verifikasi menutup adopsi, memulai masa tunggu 30 hari, dan tidak otomatis membuat kucing READY. |
| ADP-13 | P0 | Laporan kendala (sakit, hilang, meninggal, QR rusak, perawatan) tidak mewajibkan foto dan tidak otomatis menutup adopsi. Bila kucing butuh bantuan darurat, adopter dapat membuat tiket insiden dengan persetujuan; alamat adopter tidak disebar ke relawan dan tiket dari kucing teradopsi ditangani admin, bukan dispatch relawan kampus. |
| ADP-14 | P1 | Pengingat email: hari jatuh tempo dan hari ke-3. Hari ke-7 masuk daftar kontak manual admin. Membuka tautan WhatsApp bukan bukti pesan terkirim. |
| ADP-15 | P1 | Antrean admin untuk kelayakan, follow-up, keterlambatan, kendala, dan pengembalian dengan riwayat keputusan. |

Pengembalian fisik ke kampus hanya diaktifkan setelah pengelola mengesahkan kebijakan dan titiknya (bagian 16).

### 6.6 Emergency Incident Reporting (Optimind)

| ID | Prioritas | Kebutuhan dan kriteria penerimaan |
| --- | --- | --- |
| EIR-01 | P0 | Pengguna login membuat tiket: kategori, urgensi awal, deskripsi, lokasi, waktu server. cat\_id boleh kosong. Foto atau video opsional (maksimal 5 berkas) karena kondisi darurat. |
| EIR-02 | P0 | Kategori: SICK, INJURED, MISSING, FOUND, AGGRESSIVE, DECEASED, NEW\_CAT, DAMAGED\_QR, OTHER. Kategori tidak selalu berarti keadaan medis darurat. |
| EIR-03 | P0 | Lokasi dari GPS dengan koreksi pin manual. Koordinat divalidasi server. |
| EIR-04 | P0 | Tiket memiliki ID dan status RECEIVED hanya setelah server berhasil menyimpan. Kegagalan simpan tidak menghasilkan pesan sukses atau klaim relawan sudah diberi tahu. |
| EIR-05 | P0 | Pelapor melihat daftar dan detail tiket miliknya. Admin melihat antrean dengan filter status dan urgensi. Caretaker hanya melihat tugasnya. |
| EIR-06 | P0 | Admin menetapkan satu penanggung jawab utama. Tanpa relawan, tiket tetap di antrean. Penolakan dan pengalihan dicatat. Rekomendasi kandidat berdasarkan ketersediaan dan jarak bersifat tambahan. |
| EIR-07 | P0 | Relawan atau admin memperbarui status lewat transisi yang diizinkan dengan catatan; aktor dan waktu masuk riwayat. |
| EIR-08 | P0 | Tidak ada dua penanggung jawab utama aktif tanpa override admin yang dicatat. |
| EIR-09 | P0 | Peta operasional menampilkan lokasi tepat hanya kepada peran berwenang. Nomor kontak dan media tidak muncul di daftar. |
| EIR-10 | P0 | Tiket dari game atau profil membawa source dan source\_ref; tidak membuat dua tiket tanpa tindakan baru yang jelas. Kategori NEW\_CAT menambah baris di antrean kucing tak teridentifikasi. |
| EIR-11 | P1 | Notifikasi status ke pusat notifikasi dan push. Kegagalan tercatat. |
| EIR-12 | P1 | Kontak dokter hewan atau klinik; panggilan, WhatsApp, dan rute atas aksi pengguna. Data tidak diisi fiktif. |
| EIR-13 | P1 | Penautan potensi duplikat dan peta hotspot. |

## 7. Skema Database

Konvensi: primary key dan foreign key memakai ULID (`HasUlids`, `char(26)`). Lokasi memakai `geography(Point,4326)` (atau pasangan lat dan lng pada fallback). Waktu `timestamptz` UTC. Semua tabel punya created\_at dan updated\_at; deleted\_at hanya pada tabel bertanda (soft delete). Kolom pada tabel ini adalah kontrak minimum; kelompok boleh menambah kolom atau tabel pendukung miliknya.

Nama tabel mengikuti Eloquent dari model yang sudah ada di repo: Cat, IdentificationQuestion, IdentificationAttempt, FeedingSpot, FeedingActivity, CatEncounter, UserCatDex, AdoptionApplication, AdoptionFollowup, IncidentReport. Tabel baru memakai prefix modul (`feeding_`, `adoption_`, `incident_`). Karena `users.id` berupa ULID, ubah kolom model\_id pada tabel Spatie (model\_has\_roles, model\_has\_permissions) menjadi `char(26)` sebelum migration pertama.

### 7.1 Core

| Tabel | Kolom utama | Catatan |
| --- | --- | --- |
| users (soft delete) | id, name, email (unik), email\_verified\_at, password, user\_type (MAHASISWA, DOSEN, STAF), identity\_number (boleh kosong), phone (boleh kosong), avatar\_media\_id, is\_active, last\_login\_at | Role dasar user ditetapkan server |
| roles, permissions, model\_has\_roles, model\_has\_permissions, role\_has\_permissions | Standar Spatie | Seeder membuat role dan permission bagian 3 |
| personal\_access\_tokens | Standar Sanctum |  |
| email\_otps | id, user\_id, code\_hash, expires\_at, attempts, used\_at | OTP verifikasi email |
| device\_tokens | id, user\_id, token (unik), platform, last\_seen\_at | FCM |
| notifications | Tabel standar Laravel (channel database) dengan kolom status delivery | Sumber status in-app |
| media\_files (soft delete) | id, owner\_id, disk, path, mime, size\_bytes, sha256, purpose, visibility, related\_type, related\_id, captured\_at, retention\_until | sha256 untuk deteksi foto dobel (R6) |
| idempotency\_keys | id, user\_id, key, route, request\_hash, response\_code, response\_body (jsonb), expires\_at | Unik pada (user\_id, key, route); berlaku 24 jam |
| audit\_logs | id, actor\_id, action, subject\_type, subject\_id, result, reason, created\_at | Tanpa token atau data sensitif |
| territories | id, code (unik), name, area (boleh kosong) | Zona kampus |

### 7.2 Kucing dan Identifikasi (Cat, CatIdentification)

| Tabel | Kolom utama | Catatan |
| --- | --- | --- |
| cats (soft delete) | id, unique\_code (unik), name, gender, color\_pattern, age\_group, is\_sterilized (boleh kosong), description, traits (jsonb), territory\_id, primary\_photo\_media\_id, presence\_status, health\_status, adoption\_status, verification\_status, first\_seen\_at, last\_seen\_at | Default ON\_CAMPUS, HEALTHY, UNREVIEWED. Tanpa kolom koordinat last\_seen. |
| cat\_photos | id, cat\_id, media\_id, angle, sort\_order | Foto rujukan |
| cat\_qr\_tokens | id, cat\_id, token (unik), status (ACTIVE, REVOKED), issued\_by, issued\_at, revoked\_at, revoked\_reason | Indeks unik parsial: satu ACTIVE per kucing |
| cat\_sightings | id, cat\_id (boleh kosong), user\_id, source, request\_id (unik per user), location (boleh kosong), accuracy\_m, token\_id, occurred\_at, metadata (jsonb) | Satu log perjumpaan semua modul |
| unidentified\_sightings | id, reporter\_id, media\_id, location, notes, source (IDENTIFY\_FAILED, AKINATOR\_FAILED, INCIDENT\_NEW\_CAT), incident\_report\_id, status (OPEN, MATCHED, CAT\_CREATED, REJECTED), matched\_cat\_id, handled\_by, handled\_at | Antrean kurasi |
| identification\_questions | id, code (unik), question\_text, sort\_order, is\_active | Pertanyaan Akinator |
| cat\_trait\_answers | cat\_id, question\_id, answer (YES, NO) | Kunci utama gabungan |
| identification\_attempts | id, user\_id (boleh kosong), method (PHOTO, AKINATOR), model\_version, input\_media\_id, answers (jsonb), candidates (jsonb), result (MATCHED, INCONCLUSIVE, NOT\_CAT), confirmed\_cat\_id | Retensi sesuai kebijakan |
| cat\_status\_logs | id, cat\_id, dimension, from\_value, to\_value, reason, actor\_id, source\_module, ref\_type, ref\_id | Audit status |

### 7.3 Poin

| Tabel | Kolom utama | Catatan |
| --- | --- | --- |
| point\_rules | id, rule\_key (unik), module, points, daily\_cap\_count, daily\_cap\_points, is\_active, description | Dapat diubah super\_admin |
| point\_transactions | id, user\_id, rule\_key, points, source\_module, source\_type, source\_ref\_id, idempotency\_key (unik), status (CREDITED, REVERSED), reversal\_of, created\_at | Tambah-saja; reversal baris baru dengan points negatif |
| point\_balances | user\_id (PK), total\_points, updated\_at | Cache; diperbarui dalam transaksi yang sama |
| badges, user\_badges | id, code, name, module, criteria (jsonb); user\_id, badge\_id, awarded\_at | P1 |

### 7.4 Modul

| Modul | Tabel dan kolom utama |
| --- | --- |
| FeedingSpot | **feeding\_spots:** id, code, name, description, location, territory\_id, qr\_token (unik), status. **feeding\_spot\_cats:** spot\_id, cat\_id. **feeding\_activities (FeedingActivity):** id, feeding\_record\_ref (unik), user\_id, spot\_id, location (salinan dari spot), status, scanned\_at, intent\_at, intent\_deadline\_at, finalize\_deadline\_at, finalized\_at, food\_type, food\_amount, cat\_id, reward\_status, potential\_points, reward\_snapshot (jsonb: N, P, T, B, config\_version), flags (jsonb). **feeding\_evidence:** id, activity\_id, media\_id, captured\_at, sort\_order. **feeding\_rule\_results:** activity\_id, rule, result (PASS, REVIEW, FAIL), detail. **feeding\_reviews:** id, activity\_id, reviewer\_id, decision, reason, created\_at. **feeding\_aggregates:** spot\_id, window\_start, window\_end, verified\_count, pending\_count, computed\_at. **feeding\_settings:** key, value (jsonb). |
| CatHunter | **game\_cat\_profiles:** cat\_id (PK), rarity (COMMON, RARE, EPIC), is\_active. **cat\_encounters (CatEncounter):** id, user\_id, cat\_id, mood, trust, turn\_count, status (ACTIVE, TAMED, FAILED, ESCAPED, EXPIRED), started\_at, ended\_at, location (boleh kosong), points\_awarded. **cat\_encounter\_turns:** id, encounter\_id, turn\_no, action (PET, LEAVE), trust\_after. **user\_cat\_dex (UserCatDex):** id, user\_id, cat\_id, state (SEEN, TAMED), tamed\_at, times\_encountered, last\_greeted\_at; unik (user\_id, cat\_id). **game\_settings:** key, value (jsonb). |
| CatAdoption | **adoption\_applications (AdoptionApplication):** id, applicant\_id, cat\_id (boleh kosong), housing\_type, owner\_permission, can\_afford, long\_term\_plan, answers (jsonb), commitment\_version, commitment\_accepted\_at, precheck\_passed, status, submitted\_at, reviewed\_by, reviewed\_at, review\_note. **adoption\_application\_media:** application\_id, media\_id (privat). **adoption\_pickup\_locks:** id, cat\_id, adopter\_id, expires\_at, status (HELD, RELEASED, USED); unik parsial satu HELD per kucing. **adoptions:** id, application\_id, cat\_id, adopter\_id, status, picked\_up\_at, pickup\_media\_id, pickup\_location, trial\_ends\_at, closed\_at, rehome\_cooldown\_until; unik parsial satu ACTIVE per kucing dan per adopter. **adoption\_followups (AdoptionFollowup):** id, adoption\_id, period\_no, due\_at, submitted\_at, condition\_note, issue\_note, media\_id, status (PENDING, SUBMITTED, LATE, REVIEWED); unik (adoption\_id, period\_no). **adoption\_returns:** id, adoption\_id, type (REGULAR, EMERGENCY), reason, status, proof\_media\_id, return\_location, verified\_by, verified\_at. **adoption\_issues:** id, adoption\_id, type, description, media\_id, status, handled\_by, incident\_report\_id. |
| IncidentReport | **incident\_reports (IncidentReport):** id, ticket\_code (unik), reporter\_id, cat\_id (boleh kosong), category, urgency (LOW, MEDIUM, HIGH), description, location, location\_note, territory\_id, source (DIRECT, GAME, PROFILE, ADOPTION), source\_ref, status, assigned\_to, assigned\_at, resolved\_at, closed\_at, resolution\_note, notification\_status. **incident\_media:** incident\_id, media\_id. **incident\_status\_logs:** id, incident\_id, from\_status, to\_status, actor\_id, note, created\_at. **incident\_assignments:** id, incident\_id, caretaker\_id, assigned\_by, status (OFFERED, ACCEPTED, DECLINED, DONE), responded\_at; unik parsial satu aktif per tiket. **caretaker\_profiles:** user\_id, is\_available, phone, territory\_ids, last\_location. **vet\_contacts:** id, name, address, phone, whatsapp, location, open\_hours, is\_active. |

### 7.5 Tabel yang tidak boleh dibuat

Telcat tidak membuat tabel cats, saldo poin sendiri, laporan sakit sendiri, atau tabel QR sendiri. Rekans Caps tidak membuat tabel Perjumpaan sendiri. Modul lain tidak mengubah kolom status kucing secara langsung.

## 8. Kontrak API

Tanda † berarti endpoint wajib menerima header `Idempotency-Key`. Path dan fungsi di bawah adalah kontrak; kelompok menuliskan field request dan response lengkap di `docs/api/<modul>.yaml` (OpenAPI) pada PR pertama modul.

### 8.1 Konvensi

- Base URL `/api/v1`. Header `Authorization: Bearer <token>`. Semua endpoint selain register, login, dan verifikasi memerlukan login dan email terverifikasi.
- Respons sukses: `{ success, message, data, meta? }`. Respons gagal: `{ success: false, code, message, errors?, request_id }`. Tanpa stack trace atau data privat.
- Kode HTTP: 200, 201, 202 (hanya bila pekerjaan benar-benar diantrikan), 400, 401, 403, 404 (boleh menyamarkan 403), 409 (konflik status atau idempotensi), 422, 429, 5xx.
- Kode domain: VALIDATION\_ERROR, FORBIDDEN, CONFLICT, QR\_INVALID, QR\_REVOKED, QR\_WRONG\_TYPE, CAT\_NOT\_AVAILABLE, SESSION\_EXPIRED, COOLDOWN\_ACTIVE, DAILY\_CAP\_REACHED, ALREADY\_ADOPTING, NOT\_STUDENT, EMAIL\_NOT\_VERIFIED, RATE\_LIMITED.
- Waktu ISO 8601 UTC. Koordinat `{ lat, lng, accuracy_m? }`. Daftar berpaginasi (`page`, `per_page`).
- Unggah file selalu lewat `POST /media`; endpoint modul hanya menerima `media_id`.
- Rate limit: login dan verifikasi 10 per menit per IP, kirim ulang OTP 3 per jam, endpoint tulis 60 per menit per pengguna.
- Perubahan kontrak lewat PR yang memperbarui OpenAPI dan disetujui PM.

### 8.2 Core

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| POST /auth/register | publik | Buat akun, kirim OTP |
| POST /auth/email/otp/verify, POST /auth/email/otp/resend | login | Verifikasi atau kirim ulang OTP |
| POST /auth/login, POST /auth/logout | publik, login | Token Sanctum, cabut token |
| GET /me, PATCH /me, DELETE /me | login | Profil dan izin pemilik; ubah profil; permintaan hapus akun |
| POST /me/device-tokens, DELETE /me/device-tokens/{token} | login | Token FCM |
| GET /notifications, POST /notifications/{id}/read, POST /notifications/read-all | login | Notifikasi milik akun |
| POST /media † | login | Unggah satu berkas dengan field purpose; hasilnya media\_id |
| GET /media/{id}/url | pemilik atau permission | URL bertanda tangan 10 menit |
| GET /scan/resolve?code= | login | Terima isi QR atau kode manual; kembalikan type (cat atau spot) dan id. Tanpa efek samping |
| GET /points/me, GET /points/me/transactions | login | Saldo dan riwayat |
| GET /leaderboard?period=weekly atau all&source= | login | 50 teratas dan posisi pengguna |
| GET /badges/me | login | Badge pengguna |
| GET /map/layers/{cats, incidents, spots} | login | Titik sesuai bagian 4.6 |

Admin Core (Filament dan API): kelola pengguna dan role (`user.manage`), aturan poin (`points.config`).

### 8.3 Kucing dan Identifikasi

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| GET /cats, GET /cats/{id}, GET /cats/by-code/{unique\_code} | login | Daftar dengan filter, profil publik, pencarian kode manual |
| GET /cats/{id}/actions | login | Aksi hub yang tersedia |
| POST /cats/{id}/sightings † | login | Catat perjumpaan |
| POST /cats/identify/akinator/start, POST /cats/identify/akinator/answer | login | Sesi pertanyaan; hasil kandidat atau INCONCLUSIVE |
| POST /cats/identify/photo † | login | Kirim media\_id; diteruskan ke ml-service (P1) |
| POST /cats/unidentified † | login | Catat dugaan kucing baru |

Admin (`cat.edit`, `cat.curate`, `cat.qr.regenerate`): `POST/PATCH /admin/cats`, `POST /admin/cats/import`, `POST /admin/cats/{id}/qr/regenerate`, `GET /admin/cats/qr-sheet`, `GET /admin/unidentified`, `POST /admin/unidentified/{id}/resolve`, `PUT /admin/cats/{id}/traits`, `CRUD /admin/identification-questions`, `POST /admin/cats/{id}/merge`.

### 8.4 Feeding Spot

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| GET /feeding/spots, GET /feeding/spots/{id} | login | Spot dan agregat yang boleh ditampilkan |
| POST /feeding/activities † | login | Body: qr\_token spot. Membuat aktivitas DRAFT dengan lokasi dari spot; mengembalikan activity\_id dan batas waktu |
| POST /feeding/activities/{id}/intent † | pemilik | Konfirmasi memberi makan; server mencatat waktu |
| POST /feeding/activities/{id}/finalize † | pemilik | Body: media\_ids (1-3), food\_type, food\_amount (opsional), cat\_code (opsional dari QR kalung). Menjalankan aturan; hasil SUBMITTED, UNDER\_REVIEW, atau VERIFIED, dengan reward\_status terpisah |
| GET /feeding/activities/mine | login | Riwayat dan status |
| GET /feeding/heatmap?days=14 | login | Coverage per spot dan zona |

Admin (`spot.manage`, `feeding.review`): `CRUD /admin/feeding/spots`, `POST /admin/feeding/spots/{id}/qr/regenerate`, `GET /admin/feeding/spots/qr-sheet`, `GET /admin/feeding/review-queue`, `POST /admin/feeding/activities/{id}/review` (VERIFIED atau REJECTED dengan alasan; ditolak bila reviewer adalah pemilik), `GET/PUT /admin/feeding/settings`.

Contoh sukses finalize: `{ success: true, data: { activity_id, status: UNDER_REVIEW, reward_status: PENDING }, message: Pengajuan diterima untuk pemeriksaan }`. Contoh gagal: `{ success: false, code: SESSION_EXPIRED, message: Sesi kedaluwarsa. Pindai ulang QR spot. }` dan aktivitas tidak diubah menjadi SUBMITTED.

### 8.5 Cat Hunter

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| POST /game/encounters † | login | Body: cat\_code, mood, lokasi (opsional). Server memeriksa status kucing dan jeda. Mood sakit atau terluka tidak memulai game; respons berisi petunjuk ke form insiden |
| POST /game/encounters/{id}/turns † | pemilik | Body: action (PET atau LEAVE); server menghitung trust, hasil, dan poin |
| GET /game/collection | login | Koleksi dan siluet yang belum ditemui |
| POST /game/greet † | login | Sapa kucing jinak |
| GET /game/map | login | Titik atau heatmap tergeneralisasi |

Admin (`game.config`): `GET/PUT /admin/game/settings`, `PUT /admin/game/cats/{cat_id}/rarity`, `GET /admin/game/stats`.

### 8.6 Adopsi

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| GET /adoption/cats | mahasiswa | Katalog kucing READY tanpa adopsi aktif |
| POST /adoption/applications †, PUT /adoption/applications/{id} | mahasiswa | Buat atau simpan draf |
| POST /adoption/applications/{id}/submit † | mahasiswa | Kirim dan jalankan pemeriksaan awal |
| GET /adoption/applications/mine | mahasiswa | Status dan catatan admin |
| POST /adoption/pickups/start † | mahasiswa APPROVED | Body: cat\_code. Menahan kucing dan mengatur adoption\_status |
| POST /adoption/pickups/confirm † | mahasiswa | Body: pickup\_media\_id, lokasi, konfirmasi tanggung jawab. Transaksi atomik; adopsi ACTIVE |
| GET /adoption/mine | mahasiswa | Kucing Saya dan jadwal follow-up |
| POST /adoption/{id}/followups † | adopter | Kirim follow-up periode berjalan |
| POST /adoption/{id}/returns † | adopter | Ajukan pengembalian; unggah bukti setelah disetujui |
| POST /adoption/{id}/issues † | adopter | Laporan kendala |

Admin (`adoption.review`, `adoption.approve`, `adoption.set_ready`, `adoption.verify_return`): `GET /admin/adoption/applications`, `POST /admin/adoption/applications/{id}/decision`, `POST /admin/adoption/cats/{cat_id}/set-ready`, `GET /admin/adoption/adoptions`, `POST /admin/adoption/returns/{id}/decision`, `POST /admin/adoption/returns/{id}/verify`, `GET /admin/adoption/issues`, `POST /admin/adoption/issues/{id}/handle`.

### 8.7 Insiden

| Endpoint | Akses | Fungsi |
| --- | --- | --- |
| POST /incidents † | login | Buat tiket; body category, urgency, description, location, media\_ids, cat\_id (opsional), source, source\_ref. Respons 201 berisi ticket\_code dan status RECEIVED |
| GET /incidents/mine, GET /incidents/{id} | pelapor | Daftar dan detail dengan riwayat status |
| GET /vets | login | Kontak dokter hewan |
| GET /caretaker/tasks | caretaker | Tugas yang ditawarkan atau berjalan |
| POST /caretaker/tasks/{id}/accept, POST /caretaker/tasks/{id}/decline | caretaker | Respons penugasan |
| POST /incidents/{id}/status † | caretaker atau admin | Ubah status lewat transisi yang diizinkan dengan catatan |

Admin (`incident.view`, `incident.dispatch`, `incident.close`): `GET /admin/incidents`, `GET /admin/incidents/{id}/candidates`, `POST /admin/incidents/{id}/assign`, `POST /admin/incidents/{id}/close`, `GET /admin/incidents/hotspots`, `CRUD /admin/vets`, `CRUD /admin/caretakers`.

Penolakan relawan atau tidak ada respons dalam 15 menit mengembalikan tiket ke WAITING\_ASSIGNMENT. Notifikasi berstatus NOT\_REQUESTED, PENDING, SENT, atau FAILED sesuai kenyataan dan tidak mengklaim ada relawan yang merespons.

## 9. Layanan, Event, dan Aturan Poin

### 9.1 Layanan Core (satu-satunya pintu)

| Layanan | Metode | Aturan |
| --- | --- | --- |
| PointService | `award(User, ruleKey, sourceModule, sourceType, sourceRefId, idempotencyKey)`, `reverse(transactionId, reason)` | Membaca point\_rules; menegakkan batas harian per aturan dan total; mengembalikan transaksi yang sama jika idempotency\_key sudah ada; menulis ledger dan saldo dalam satu transaksi database. |
| CatStatusService | `change(Cat, dimension, newValue, actor, sourceModule, reason, ref)` | Satu-satunya jalur mengubah tiga status kucing. Memeriksa matriks di 9.2, menulis cat\_status\_logs, mengirim `CatStatusChanged`. |
| MediaService | `store(UploadedFile, purpose, owner)`, `signedUrl(Media)` | Menerapkan visibility dan retensi per purpose. |
| NotificationService | `send(User, type, payload)` | Menulis notifikasi database dan push FCM lewat queue; menyimpan status pengiriman. |
| ScanResolver | `resolve(code)` | Mengembalikan jenis (cat atau spot) dan id tujuan. Tanpa efek samping. |
| CatActionProvider (interface) | `actionsFor(Cat, User): array` | Diimplementasikan tiap modul dan didaftarkan lewat tag container `cat.actions`. |
| AuthProvider (interface) | `attempt(credentials)`, `register(data)` | Implementasi awal: email dan password dengan OTP. SSO kampus nanti mengganti implementasi ini. |

### 9.2 Siapa boleh mengubah status kucing

| Dimensi | Modul yang boleh memanggil change() |
| --- | --- |
| presence\_status | Core (listener event) dan Cat (kurasi data\_curator) |
| health\_status | IncidentReport |
| adoption\_status | CatAdoption |

Modul lain mengubah presence\_status hanya dengan mengirim event di 9.3; listener di Core yang memanggil change().

### 9.3 Katalog event

| Event | Pengirim | Isi | Efek |
| --- | --- | --- | --- |
| CatStatusChanged | CatStatusService | cat\_id, dimension, from, to | Notifikasi ke admin terkait |
| IncidentCreated | IncidentReport | report\_id, category, cat\_id, urgency | Notifikasi admin dan relawan; kategori NEW\_CAT menambah baris unidentified\_sightings |
| IncidentVerified | IncidentReport | report\_id, category, cat\_id | SICK atau INJURED: health\_status berubah; Core memberi poin aturan incident.report |
| IncidentResolved | IncidentReport | report\_id, category, cat\_id | health\_status kembali HEALTHY atau UNDER\_CARE; DECEASED atau MISSING masuk antrean konfirmasi admin |
| CatAdopted | CatAdoption | cat\_id, adopter\_id | Core mengubah presence\_status menjadi ADOPTED; Game dan Feeding berhenti menampilkan kucing |
| CatReturned | CatAdoption | cat\_id | Core mengembalikan presence\_status ke ON\_CAMPUS setelah verifikasi admin |
| FeedingVerified | FeedingSpot | activity\_id, user\_id, spot\_id | Feeding memanggil PointService; Core mencatat cat\_sightings bila cat\_id ada |
| EncounterCompleted | CatHunter | encounter\_id, result | Core mencatat cat\_sightings |
| PointsAwarded | PointService | user\_id, points, rule\_key | Cek badge |
| CatQrRegenerated | Cat | cat\_id | Notifikasi admin |

### 9.4 Aturan poin awal (seed point\_rules)

Nilai di bawah adalah default untuk uji coba dan dapat diubah super\_admin. Skala poin game diturunkan dari PRD Telcat (100, 200, 400) agar seimbang dengan reward pakan 5 sampai 20.

| rule\_key | Poin | Batas |
| --- | --- | --- |
| feeding.verified | 5 sampai 20 sesuai rumus Lampiran A.1 | 3 reward per hari |
| game.tame.common, game.tame.rare, game.tame.epic | 10, 20, 40 | 10 penjinakan per hari; satu kucing sekali per 6 jam |
| game.fail | 2 | 5 kali per hari |
| game.greet | 3 | 3 kali per hari |
| incident.report | 20, diberikan setelah admin memverifikasi laporan | 3 laporan per hari |
| cat.sighting dan identifikasi | 0 | Tidak ada poin |

Batas total semua sumber: 150 poin per hari per pengguna. Aktivitas pakan yang VERIFIED saat kuota habis tetap dihitung di agregat tetapi menghasilkan 0 poin, dan responsnya memuat `reward_capped: true`.

## 10. Frontend Flutter

### 10.1 Paket dan struktur

Ikuti paket yang sudah ada di `frontend/pubspec.yaml`, termasuk pendekatan state management yang sudah dipakai (folder `logic/*_provider.dart`); jangan mencampur dua pendekatan. Tambahkan hanya yang belum ada:

| Kebutuhan | Paket |
| --- | --- |
| HTTP (jika belum ada) | dio, dengan interceptor token, Idempotency-Key otomatis untuk endpoint bertanda †, dan pemetaan error ke `AppException` |
| Penyimpanan token | flutter\_secure\_storage |
| Scan QR | mobile\_scanner |
| Kamera | camera |
| Lokasi | geolocator (Cat Hunter dan Optimind; Acumalaka hanya untuk mengurutkan spot terdekat) |
| Peta | flutter\_map dan latlong2 |
| Push | firebase\_core, firebase\_messaging |

```
frontend/lib/
├── main.dart, app.dart
├── core/                      # milik PM
│   ├── constants/app_constants.dart
│   ├── network/               # api_client.dart, api_exception.dart
│   ├── router/app_router.dart # menggabungkan *_routes.dart semua fitur
│   ├── storage/token_storage.dart
│   ├── theme/app_theme.dart
│   ├── widgets/               # custom_button, error_view, loading_indicator
│   ├── scanner/               # BARU: ScannerPage, ScanPurpose, parseQr
│   ├── camera/                # BARU: CameraCapturePage dan unggah media
│   ├── hub/                   # BARU: CatActionRegistry
│   └── map/                   # BARU: widget peta dan layer
└── features/                  # tiap fitur: <fitur>_routes.dart, data/, logic/, ui/
    ├── shell/main_navigation_shell.dart
    ├── auth/                  # PM: login, registrasi, input OTP
    ├── cat/                   # profil kucing, QR (Rekans Caps)
    ├── cat_identification/    # Rekans Caps
    ├── incident_report/       # Optimind
    ├── cat_adoption/          # E-Nigma
    ├── cat_hunter/            # SUPER-SUB
    ├── feeding_spot/          # Acumalaka
    ├── home/                  # BARU: Beranda (PM)
    └── profile/               # BARU: Profil, poin, leaderboard (PM)
```

Navigasi bawah: Beranda (pintasan, daftar spot terdekat), Berburu, Peta, Lapor, Profil (poin, Kucing Saya, adopsi, riwayat). Tombol Scan di tengah membuka scanner pusat. Layar admin tidak ada di Flutter; admin memakai Filament.

### 10.2 Komponen bersama

**Scanner pusat.** `ScannerPage(purpose: ScanPurpose.profile | encounter | pickup | return | feeding)`. Membaca isi QR, mengurai dengan `parseQr`, lalu memanggil `GET /scan/resolve?code=`. Mendukung input kode manual. `scan_qr_page.dart` milik Rekans Caps menjadi pembungkus tipis yang memanggil ScannerPage.

```dart
enum QrKind { cat, spot, unknown }

class QrPayload {
  final QrKind kind;
  final String value;
  const QrPayload(this.kind, this.value);
}

QrPayload parseQr(String raw) {
  final p = raw.trim().split('.');
  if (p.length == 3 && p[0] == 'MTP1') {
    if (p[1] == 'C') return QrPayload(QrKind.cat, p[2]);
    if (p[1] == 'S') return QrPayload(QrKind.spot, p[2]);
  }
  return QrPayload(QrKind.unknown, raw.trim()); // dikirim ke server sebagai kode manual
}
```

**Kamera.** `CameraCapturePage(mode: cameraOnly | photoVideo, maxFiles)`. cameraOnly (tanpa galeri) untuk Acumalaka dan E-Nigma; photoVideo untuk Optimind. Hasil diunggah ke `POST /media` dan mengembalikan daftar media\_id.

**Hub aksi di profil kucing.** Halaman profil memanggil `GET /cats/{id}/actions` dan menampilkan tombol untuk id yang terdaftar di klien:

```dart
class CatActionSpec {
  final String id;          // contoh: 'game.encounter'
  final String label;
  final IconData icon;
  final void Function(BuildContext context, String catId) onTap;
  const CatActionSpec(this.id, this.label, this.icon, this.onTap);
}

class CatActionRegistry {
  static final Map<String, CatActionSpec> _items = {};
  static void register(CatActionSpec spec) => _items[spec.id] = spec;
  static CatActionSpec? byId(String id) => _items[id];
}
```

Setiap fitur menyediakan `register<Nama>Actions()` pada filenya sendiri. `core/hub/register_actions.dart` hanya memanggil kelima fungsi itu. Id aksi baku: `game.encounter`, `adoption.apply`, `incident.report`, `feeding.start`.

**Route.** Tiap fitur mengekspor daftar route di `<fitur>_routes.dart`; `core/router/app_router.dart` menggabungkannya. Perubahan satu baris di file Core boleh dilakukan kelompok lewat PR.

## 11. Struktur Repo dan Setup Lokal

```
SuperAppMeowtopia/
├── backend/
│   ├── app/
│   │   ├── Http/Controllers/Controller.php
│   │   ├── Models/User.php
│   │   ├── Providers/ModuleServiceProvider.php   # memuat routes.php dan Database/Migrations tiap modul
│   │   ├── Support/ApiResponse.php               # format respons seragam
│   │   └── Modules/
│   │       ├── Core/                 # PM: auth, RBAC, poin, media, notifikasi, idempotency
│   │       ├── Cat/                  # data kucing dan QR (Rekans Caps)
│   │       ├── CatIdentification/    # Rekans Caps
│   │       ├── IncidentReport/       # Optimind
│   │       ├── CatAdoption/          # E-Nigma
│   │       ├── CatHunter/            # SUPER-SUB
│   │       └── FeedingSpot/          # Acumalaka
│   ├── bootstrap/ config/ database/seeders/ routes/ tests/
├── frontend/                      # Flutter (bagian 10)
├── ml-service/                    # FastAPI milik Rekans Caps
├── docs/                          # api/, erd/, decisions/
├── docker-compose.yml
├── .github/ (workflows/, pull_request_template.md, CODEOWNERS)
└── README.md
```

Struktur satu modul backend:

```
Modules/IncidentReport/
├── routes.php                     # dimuat otomatis oleh ModuleServiceProvider
├── Database/Migrations/           # huruf besar M, sesuai repo
├── Controllers/  Requests/  Models/  Services/
└── (jika perlu) Policies/  Events/  Listeners/  Resources/  Tests/
```

`app/Providers/ModuleServiceProvider.php` harus memuat `routes.php` dan `Database/Migrations` dari semua folder di `Modules/`; PM memverifikasi ini pada checklist 13.1. Kelompok tidak mengedit `routes/api.php` atau `AppServiceProvider`. Karena CI berjalan di Linux yang membedakan huruf besar dan kecil, nama folder harus persis sama.

### 11.1 Docker Compose (dev)

```yaml
services:
  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: meowtopia
      POSTGRES_USER: meowtopia
      POSTGRES_PASSWORD: secret
    ports: ['5432:5432']
    volumes: ['dbdata:/var/lib/postgresql/data']
  redis:
    image: redis:7
    ports: ['6379:6379']
  mailpit:
    image: axllent/mailpit
    ports: ['1025:1025', '8025:8025']
  minio:
    image: minio/minio
    command: server /data --console-address ':9001'
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio12345
    ports: ['9000:9000', '9001:9001']
    volumes: ['miniodata:/data']
volumes:
  dbdata:
  miniodata:
```

### 11.2 Variabel lingkungan (backend/.env.example)

| Variabel | Nilai dev | Fungsi |
| --- | --- | --- |
| DB\_CONNECTION, DB\_HOST, DB\_PORT | pgsql, 127.0.0.1, 5432 | PostgreSQL |
| DB\_DATABASE, DB\_USERNAME, DB\_PASSWORD | meowtopia, meowtopia, secret | Sesuai compose |
| QUEUE\_CONNECTION, CACHE\_STORE | redis | Queue dan cache |
| FILESYSTEM\_DISK | s3 | Endpoint diarahkan ke MinIO di dev |
| MAIL\_HOST, MAIL\_PORT | 127.0.0.1, 1025 | Mailpit (OTP terlihat di http://localhost:8025) |
| ALLOWED\_EMAIL\_DOMAINS | domain kampus, dipisah koma | Pembatas registrasi |
| EMAIL\_DOMAIN\_TYPES | pemetaan domain ke MAHASISWA, DOSEN, STAF | Penentu user\_type |
| ML\_SERVICE\_URL, ML\_ENABLED | http://127.0.0.1:8001, false | Layanan Rekans Caps |
| FCM\_CREDENTIALS\_PATH | path JSON service account | Push |

Tidak ada variabel domain atau deep link karena QR hanya berisi kode. Alamat API tetap harus dapat dijangkau HP di jaringan yang sama (dev) atau lewat HTTPS (staging dan produksi).

### 11.3 Menjalankan proyek

```
git clone https://github.com/Meowtopiaa/SuperAppMeowtopia.git && cd SuperAppMeowtopia
git checkout development
docker compose up -d
cd backend
cp .env.example .env
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve            # terminal 1
php artisan queue:work       # terminal 2
cd ../frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` adalah alamat localhost untuk emulator Android. Untuk HP fisik, ganti dengan IP laptop di jaringan yang sama. Seeder dev membuat satu akun per role (password: password, hanya aktif di environment non-production), 20 kucing contoh, 3 spot pakan, dan aturan poin awal.

### 11.4 Aturan Git dan migration

- Branch: `main` (produksi), `development` (integrasi), `team/acumalaka`, `team/rekans-caps`, `team/super-sub`, `team/enigma`, `team/optimind`. Anggota membuat branch tugas dari branch tim (misalnya `team/acumalaka/feat-intent-finalize`) dan membuka PR internal ke branch tim. PR tim ke `development` direview PM. Rilis dari `development` ke `main` lewat PR terpisah setelah uji integrasi.
- Aktifkan proteksi pada `main` dan `development`: wajib PR, minimal 1 approval, tanpa direct push, CI harus hijau. Verifikasi pengaturan efektifnya, jangan hanya mengandalkan README.
- Sinkronkan `git merge development` ke branch tim sebelum mulai kerja harian dan sebelum PR. Jangan menulis ulang riwayat branch bersama.
- Commit: `tipe(modul): deskripsi`, contoh `feat(adoption): tambah form kelayakan`. Tipe: feat, fix, refactor, docs, test, chore.
- Migration hanya di `Modules/<Nama>/Database/Migrations`. Setiap migration punya `down()`. Migration yang sudah di-merge ke `development` tidak diedit; perbaikan lewat migration baru. Migration inti hanya diubah PM.
- Foreign key ke tabel inti memakai `foreignUlid` ke `users.id` dan `cats.id`. Kelompok tidak mengubah kolom tabel inti.
- Tidak ada rahasia, database pribadi, atau bukti pengguna nyata di repo. Data uji tidak memakai data pribadi nyata dan tidak mengisi kontak klinik, posisi spot, atau akun relawan dengan data seolah-olah benar.

**CODEOWNERS:**

```
*                                      @FrdMnhdl
/backend/app/Modules/Core/             @FrdMnhdl
/backend/app/Providers/                @FrdMnhdl
/backend/app/Support/                  @FrdMnhdl
/backend/bootstrap/                    @FrdMnhdl
/backend/routes/                       @FrdMnhdl
/backend/database/                     @FrdMnhdl
/frontend/lib/core/                    @FrdMnhdl
/backend/app/Modules/Cat/              @FrdMnhdl @REKANS-LEAD
```

**Template PR:** ringkasan masalah, ID kebutuhan (misalnya AFS-04) atau issue terkait, modul terkait, ada migration baru atau tidak, menyentuh file Core atau tidak, perubahan API (OpenAPI sudah diperbarui), dependency baru, langkah uji dan hasil aktual, tangkapan layar untuk perubahan UI, risiko dan rollback. Jika Core berubah, sertakan PM sebagai reviewer.

**CI (.github/workflows/ci.yml):**

```yaml
name: CI
on:
  pull_request:
    branches: [development, main]
jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env: { POSTGRES_DB: meowtopia_test, POSTGRES_USER: postgres, POSTGRES_PASSWORD: postgres }
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 5s --health-retries 10
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with: { php-version: '8.3', extensions: pdo_pgsql }
      - run: composer install --no-interaction --prefer-dist
      - run: cp .env.ci .env && php artisan key:generate
      - run: php artisan migrate --force
      - run: php artisan test
  frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

Buat `backend/.env.ci` dengan koneksi ke service postgres di atas. Samakan versi PHP dengan `composer.json`.

## 12. Perbaikan Fondasi dan Keamanan (P0)

Temuan FIX-01 sampai FIX-10 berasal dari pembacaan terbatas branch main pada 31 Oktober 2026 dan bukan audit keamanan lengkap. Sebelum mengerjakan, periksa ulang pada commit terbaru dan tulis issue per temuan. Semua temuan ini wajib selesai sebelum fitur terkait dibuka ke pengguna.

| ID | Temuan | Perbaikan dan kriteria penerimaan | Pemilik |
| --- | --- | --- | --- |
| FIX-01 | Registrasi menerima role termasuk admin. | Server menetapkan role dasar. Uji registrasi dengan role=admin tidak memberi izin admin. Role istimewa hanya oleh super\_admin dan diaudit. | PM |
| FIX-02 | Daftar dan detail insiden terlihat tanpa auth dan memuat nomor pelapor. | Policy berdasarkan pelapor, caretaker yang ditugaskan, dan admin. Uji akses anonim dan pengguna lain ditolak. | Optimind |
| FIX-03 | Pembuatan dan perubahan Cat hanya memeriksa login; authorize bernilai true. | Izin per aksi dan per field (cat.edit, cat.curate). Uji mahasiswa biasa tidak bisa menulis profil induk atau status adopsi. | Rekans Caps |
| FIX-04 | Koordinat last\_seen ditulis dari game dan model Cat dikembalikan oleh endpoint publik. | Resource publik yang mengecualikan koordinat mentah; hapus kolom last\_seen berkoordinat; peta lewat endpoint tergeneralisasi. Uji payload aktual. | SUPER-SUB dan Rekans Caps |
| FIX-05 | Default adoption\_status available bertentangan dengan kucing baru belum siap diadopsi. | Default UNREVIEWED dengan migrasi data aman; hanya adoption\_admin menetapkan READY. | E-Nigma dan PM |
| FIX-06 | Pengajuan adopsi membutuhkan cat\_id dan My Cats mencakup yang disetujui. | Pisahkan aplikasi kelayakan dari transaksi adopsi. Uji tanpa cat\_id, dan tidak tampil sebagai adopsi aktif sebelum pengambilan berhasil. | E-Nigma |
| FIX-07 | Feeding dan game menambah saldo langsung; feeding langsung verified. | Status aktivitas dan ledger idempoten lewat PointService. Sampai siap, reward dinonaktifkan dan statusnya dikomunikasikan. | Acumalaka, SUPER-SUB, PM |
| FIX-08 | Pencocokan mengembalikan confidence angka tetap dan pipeline foto belum ada. | Hapus label confidence yang tidak terukur; tampilkan kandidat atau INCONCLUSIVE. | Rekans Caps |
| FIX-09 | Respons insiden menyatakan relawan sudah diberi tahu tanpa proses notifikasi yang terlihat. | Tampilkan hanya status yang telah terjadi; simpan status notifikasi dan penugasan terpisah. | Optimind |
| FIX-10 | README mengarahkan PR ke main; branch development dan branch tim belum ada. | Terapkan alur di bagian 11.4, perbarui README, aktifkan proteksi dan uji. | PM |
| FIX-11 | Daftar file repo tidak mencatat backend config/, tests/, phpunit.xml, composer.lock, database/factories, serta frontend android/, ios/, test/. | Lengkapi dari skeleton Laravel dan Flutter baru dengan versi yang sama dengan composer.json dan pubspec.yaml; `php artisan test` dan `flutter test` berjalan. | PM |
| FIX-12 | Email di domain kampus belum cukup membuktikan pemilik akun. | Verifikasi OTP (CORE-02); user\_type dari domain; ADP-01 memeriksa user\_type dan email terverifikasi. | PM |

## 13. Rencana Kerja

Sisa waktu dari 3 November sampai 18 Desember 2026 sekitar 6 minggu. Jadwal mengikuti penomoran minggu proyek: minggu 8 (2 sampai 8 November) sampai minggu 14 (14 sampai 18 Desember).

### 13.1 Checklist fondasi PM

| # | Pekerjaan | Target |
| --- | --- | --- |
| 1 | Lengkapi skeleton (FIX-11), buat `.github` (CI, CODEOWNERS, template PR), `docker-compose.yml`, folder `docs`, perbarui README, aktifkan proteksi branch | Rabu 4 November |
| 2 | PR reset skeleton (13.2): migration ULID, tabel Core dan kolom kontrak bagian 7, penomoran ulang, FIX-01 sampai FIX-05, seeder | Jumat 6 November |
| 3 | Layanan Core (PointService, CatStatusService, MediaService, NotificationService, ScanResolver, middleware Idempotency, AuthProvider), endpoint Core bagian 8.2, Filament terpasang dengan resource role dan aturan poin, verifikasi ModuleServiceProvider | Senin 9 November |
| 4 | Flutter core: network dan interceptor, login dan OTP, scanner pusat, kamera, hub aksi, navigasi bawah, Beranda dan Profil dasar | Senin 9 November |
| 5 | Merge ke development, tag `v0.1-core`, buat lima branch tim dari development, umumkan `php artisan migrate:fresh --seed` | Senin 9 November |

Butir 4 boleh didelegasikan kepada satu anggota Rekans Caps dengan PM sebagai reviewer. Selama 3 sampai 8 November kelompok mengerjakan hal yang tidak bergantung fondasi: draf OpenAPI modul, desain layar Flutter dengan data tiruan, rancangan model dan service, serta unit test untuk logika murni (misalnya engine encounter dan aturan AFS). Kelompok tidak menyentuh migration inti.

### 13.2 PR reset skeleton (satu kali, oleh PM)

Migration skeleton memakai nomor 2026\_01\_01\_000000 sampai 000006 dan belum dikunci. Karena migration semua modul diurutkan berdasarkan nama file, tabel Core harus berada sebelum modul yang merujuknya. PR `chore/reset-skeleton`:

1. Menyelaraskan migration yang ada dengan bagian 7 (ULID, tiga status kucing, cat\_qr\_tokens, kolom kontrak tiap modul).
2. Menomori ulang: Core 2026\_01\_01\_0000xx, Cat 2026\_01\_01\_0001xx, lalu CatIdentification, FeedingSpot, CatHunter, CatAdoption, IncidentReport pada 0002xx sampai 0006xx.
3. Memperbarui DatabaseSeeder dengan role, akun uji, kucing contoh, dan point\_rules.
4. Setelah merge, semua kelompok menjalankan `php artisan migrate:fresh --seed` satu kali. Sesudahnya migration baru memakai timestamp setelah 2026\_01\_01\_000699 dan aturan di bagian 11.4 berlaku penuh.

### 13.3 Rencana per kelompok

| Kelompok | Minggu 8 (3 sampai 8 Nov), persiapan | Minggu 9 dan 10 (9 sampai 22 Nov), P0 inti | Minggu 11 dan 12 (23 Nov sampai 6 Des), P0 sisa, integrasi, P1 terpilih |
| --- | --- | --- | --- |
| Rekans Caps | OpenAPI cats, desain QR sheet, siapkan CSV import dan data uji | CAT-01 sampai CAT-05: endpoint cats, profil, scan dan kode manual, rotasi token; CAT-06 import; FIX-03 | CAT-07 dan CAT-08 (Akinator, antrean kurasi, panel kurasi); aksi hub; P1: foto ML dan evaluasi |
| Optimind | OpenAPI insiden, desain form, FIX-02 | EIR-01 sampai EIR-05: buat dan lihat tiket, antrean admin di Filament, status logs | EIR-06 sampai EIR-10: penugasan, aplikasi relawan, source dari Game, Adopsi, Profil; P1: notifikasi, hotspot, vets, poin laporan |
| E-Nigma | OpenAPI adopsi, desain form, FIX-05 dan FIX-06 | ADP-01 sampai ADP-05: kelayakan, pemeriksaan awal, review admin, set READY; ADP-06 dan ADP-07: pickup dengan lock | ADP-08 sampai ADP-13: Kucing Saya, follow-up terjadwal, pengembalian, kendala; P1: pengingat email |
| SUPER-SUB | OpenAPI game, unit test engine encounter, FIX-04 | GAME-01 sampai GAME-05: encounter, koleksi, poin lewat ledger | GAME-06 dan GAME-07: lokasi dan peta tergeneralisasi; GAME-08; P1: leaderboard, badge, offline |
| Acumalaka | OpenAPI pakai, rancangan aturan tanpa GPS, unit test aturan R1 sampai R8 | AFS-01 sampai AFS-05: spot, QR, aktivitas, intent, finalize | AFS-06 sampai AFS-10: cooldown, antrean review, agregat dan heatmap; P1: reward berformula dan reversal |
| PM (Core) | Fondasi 13.1 | Leaderboard dan notifikasi, dukungan integrasi, review PR | Uji integrasi IT-01 sampai IT-23, verifikasi FIX, siapkan UAT |

**Minggu 13 (7 sampai 13 Desember):** uji terpadu, perbaikan bug, UAT dengan pengguna kampus. **Minggu 14 (14 sampai 18 Desember):** dokumentasi akhir, rilis ke main, evaluasi. Fitur P1 yang belum selesai pada akhir minggu 12 diturunkan ke daftar lanjutan tanpa mengorbankan P0.

### 13.4 Definisi siap PR dan selesai

**Siap PR:** CI hijau (migrate, test, analyze); OpenAPI modul diperbarui; feature test untuk jalur sukses, validasi gagal, dan penolakan akses; izin memakai permission atau policy, bukan string role; endpoint † memakai middleware Idempotency; status kucing hanya lewat CatStatusService dan poin hanya lewat PointService; migration punya `down()` dan nama tabel berprefix modul; format respons dan kode error sesuai 8.1; tidak ada rahasia di commit; tangkapan layar untuk perubahan UI.

**Selesai:** kriteria penerimaan modul (bagian 6) dan skenario terkait (bagian 14) lulus; error dan izin diuji; API dan migration terdokumentasi; review ditindaklanjuti; tidak ada isu P0 terbuka untuk fitur itu; keputusan akhir oleh PM.

## 14. Uji Penerimaan Lintas Modul

| ID | Skenario | Hasil yang diharapkan |
| --- | --- | --- |
| IT-01 | Scan QR kucing dari identifikasi, game, dan adopsi | Semua merujuk cat\_id yang sama; hanya aksi spesifik yang menimbulkan efek samping |
| IT-02 | QR kalung diganti setelah hilang | Token lama QR\_REVOKED; token baru menunjuk cat\_id dan riwayat yang sama; log pencabutan ada |
| IT-03 | QR spot dipindai di fitur kucing dan QR kucing di fitur pakan | Ditolak QR\_WRONG\_TYPE; tidak ada data dibuat |
| IT-04 | Scan game lalu melaporkan kucing terluka | Form insiden membawa cat\_id; pengguna mengonfirmasi; satu tiket baru; tidak ada tiket ganda |
| IT-05 | Satu pengajuan pakan dikirim ulang karena jaringan putus | Satu aktivitas dan paling banyak satu transaksi reward |
| IT-06 | Aktivitas VERIFIED tetapi reward belum berhasil | Status VERIFIED tetap; reward PENDING atau FAILED; saldo tidak bertambah dua kali |
| IT-07 | Dua mahasiswa mengambil kucing yang sama bersamaan | Tepat satu berhasil; yang lain 409; tidak ada adopsi aktif ganda |
| IT-08 | Satu mahasiswa mengambil dua kucing bersamaan | Paling banyak satu adopsi ACTIVE |
| IT-09 | Kucing teradopsi dipindai di luar kampus | Tidak mempublikasikan lokasi presisi; tidak kembali ke peta kampus |
| IT-10 | Tiket tanpa cat\_id dan tanpa relawan tersedia | Tiket tersimpan di antrean admin; status akurat; tidak ada klaim petugas menerima |
| IT-11 | Pengguna biasa mengakses data insiden atau adopsi orang lain dan endpoint admin | Semua ditolak; respons dan file tidak memuat kontak, foto rumah, atau koordinat privat |
| IT-12 | Pengembalian diajukan, bukti diterima, belum diverifikasi | Adopsi masih ACTIVE; kuota terikat; masa tunggu belum jalan; kucing belum tersedia |
| IT-13 | Admin memverifikasi pengembalian | Adopsi ditutup sekali; masa tunggu 30 hari mulai; kucing belum READY; riwayat tetap |
| IT-14 | Izin kamera atau lokasi ditolak | Alasan dan pilihan ditampilkan; tidak ada data atau status palsu; fitur pakan hanya meminta lokasi untuk daftar spot terdekat; bila ditolak, daftar tetap tampil dan pengajuan tidak terpengaruh |
| IT-15 | Satu tiket ditugaskan dua admin bersamaan | Satu penanggung jawab utama aktif; konflik dicatat |
| IT-16 | Kode QR disalin atau dibagikan, atau foto dipakai ulang | Sistem tidak mengklaim bukti pasti asli; batas waktu sesi, cooldown, deteksi foto dobel, dan review berjalan |
| IT-17 | API publik cats, profil, dan peta diperiksa langsung | Tidak ada koordinat mentah, kontak pelapor, bukti pribadi, atau data internal |
| IT-18 | Poin game dan poin pakan untuk aktivitas berbeda | Masing-masing tercatat sekali; saldo global dan leaderboard game mengikuti filter |
| IT-19 | ML gagal mendeteksi kucing atau kandidat ambigu | Coba lagi atau beralih ke pertanyaan atau beberapa kandidat atau INCONCLUSIVE; tanpa confidence palsu |
| IT-20 | Email atau push gagal setelah transaksi berhasil | Status domain tetap benar; kegagalan tercatat; pengguna tidak diberi klaim terkirim |
| IT-21 | Registrasi dengan payload role=admin | Akun dasar user atau ditolak |
| IT-22 | Registrasi dengan email di luar domain, atau OTP salah atau kedaluwarsa | Ditolak dengan pesan jelas; akun belum terverifikasi tidak dapat memakai fitur |
| IT-23 | Dosen mencoba mengajukan adopsi | NOT\_STUDENT |

Jenis uji: unit (transisi status, validasi, tanggal kalender, kuota); API dan integrasi (role, relasi, idempotensi, transaksi, serialisasi publik); perangkat (kamera, izin, jaringan buruk, unggah ulang, peta); operasional (review AFS, antrean insiden tanpa relawan, pergantian QR, pengembalian, koreksi poin); keamanan (akses antar pengguna, URL media, koordinat dari API, token dicabut, rate limit, pemeriksaan rahasia); UAT (mahasiswa, admin, komunitas atau mitra, dicatat jumlah dan hasilnya tanpa mengklaim yang belum terjadi). Setiap kasus mencatat ID kebutuhan, data awal, langkah, hasil yang diharapkan, hasil aktual, commit, perangkat, penguji, dan status.

## 15. Kebutuhan Nonfungsional

| ID | Kebutuhan | Verifikasi |
| --- | --- | --- |
| NFR-01 | Semua lalu lintas staging dan produksi memakai HTTPS. Rahasia dan kredensial tidak ada di repo. | Pemeriksaan konfigurasi dan pemindaian rahasia sebelum rilis |
| NFR-02 | Izin ditegakkan di API berdasarkan peran dan hubungan objek. | Uji horizontal dan vertikal (IT-11, IT-21) |
| NFR-03 | Media privat memakai URL berumur terbatas dan otorisasi. | Permintaan langsung tanpa izin gagal |
| NFR-04 | Koordinat presisi kucing dan insiden tidak ada di respons publik; pengaburan dan penundaan di server. | Audit respons list, detail, dan peta (IT-17) |
| NFR-05 | Operasi krusial konsisten terhadap retry dan konkurensi. | IT-05, IT-07, IT-08, IT-15 |
| NFR-06 | Data minimum dikumpulkan; tujuan kamera dan lokasi dijelaskan; layar persetujuan penggunaan data saat login pertama; hapus akun tersedia. | Review tiap field |
| NFR-07 | Log menyertakan request\_id dan tidak memuat token, foto privat, nomor telepon lengkap, atau koordinat rinci. | Review contoh log |
| NFR-08 | Backup database dan storage harian; pulihkan diuji sekali sebelum pilot. Default RPO 24 jam dan RTO 8 jam sampai disepakati. | Latihan restore dan catatan |
| NFR-09 | Antarmuka berbahasa Indonesia, label jelas, kontras memadai, teks dapat diperbesar, status tidak hanya dibedakan warna. | Uji perangkat |
| NFR-10 | Versi minimum default: Android 8.0 (API 26) dan iOS 14, disesuaikan dengan hasil uji perangkat. | Matriks perangkat |
| NFR-11 | Pesan sukses hanya setelah penyimpanan relevan berhasil. | Matikan jaringan, storage, dan worker saat uji |
| NFR-12 | Target performa KPI-06 diukur di lingkungan yang dicatat (perangkat, jaringan, jumlah pengguna, ukuran foto). | Catatan hasil ukur |
| NFR-13 | Aplikasi meminimalkan dampak pada kucing: aksi game virtual, materi etika, tanpa keharusan kontak fisik. | Review dengan mitra |

## 16. Keputusan: Default dan Konfirmasi Eksternal

Tim memakai default berikut sampai pihak terkait mengonfirmasi, sehingga pengembangan tidak berhenti. PM mencatat setiap konfirmasi atau perubahan di Decision Log (tanggal, keputusan, pihak pemberi persetujuan, dampak ke kebutuhan, kontrak, dan uji).

| ID | Keputusan | Default yang berlaku | Dikonfirmasi oleh | Perubahan hanya menyentuh |
| --- | --- | --- | --- | --- |
| OQ-01 | AFS tanpa GPS | **Terkunci** (keputusan PM). Risiko QR disalin ditangani Lampiran A | PM |  |
| OQ-02 | Pemilik Core, QR, akun, poin, notifikasi, peta | **Terkunci:** PM | PM |  |
| OQ-03 | SSO kampus | Login email dan OTP. PM menanyakan ke kampus apakah SSO tersedia dan atribut apa yang menandai mahasiswa | Kampus dan PM | AuthProvider dan EMAIL\_DOMAIN\_TYPES |
| OQ-04 | QR membuka web | **Terkunci:** tidak. QR hanya berisi kode, dibaca di dalam aplikasi | PM |  |
| OQ-05 | Scan game tanpa lokasi | Diizinkan; lokasi kosong; tidak masuk peta. Geofence mati, radius 50 m bila dinyalakan | SUPER-SUB dan PM | game\_settings |
| OQ-06 | Pengaburan dan penundaan peta publik | Grid 50 m, tunda 60 menit | Pemilik data, mitra, PM | Konfigurasi peta |
| OQ-07 | Nominal poin, kuota, reward insiden | Bagian 9.4; reward insiden setelah verifikasi admin | PM dan tiga kelompok terkait | point\_rules |
| OQ-08 | Pengambilan tanpa pendamping dan pengembalian ke titik kampus | Pengambilan boleh dengan scan dan foto. Pengembalian fisik nonaktif lewat flag `adoption.return_enabled=false` sampai pengelola mengesahkan | Pengelola kampus atau mitra dan E-Nigma | Feature flag |
| OQ-09 | Toleransi lokasi pengembalian, lock, masa berlaku kelayakan | Lock 48 jam; kelayakan berlaku 30 hari; toleransi lokasi 100 m dengan akurasi yang dicatat | E-Nigma, PM, pengelola | Pengaturan adopsi |
| OQ-10 | Admin, relawan, jam layanan, urgensi, SLA | Akun relawan dan admin dibuat PM lewat panel. Urgensi: LOW perlu perhatian tidak mendesak; MEDIUM kondisi tidak normal perlu ditangani hari ini; HIGH luka berat atau darurat perlu tindakan segera. Tidak ada janji SLA di aplikasi; eskalasi manual oleh admin | Optimind dan pengelola | Teks bantuan form |
| OQ-11 | Foto insiden wajib | Opsional, maksimal 5 berkas | Optimind | Validasi form |
| OQ-12 | Kucing hilang atau meninggal saat adopsi | Tidak menutup adopsi otomatis. Dicatat sebagai adoption\_issues dan diputuskan admin; SOP menyusul | E-Nigma dan pengelola | Alur kendala |
| OQ-13 | Provider dan hosting | PostgreSQL dengan PostGIS di VPS dengan Docker; storage S3 atau MinIO; SMTP untuk email (Mailpit di dev); FCM; tile OpenStreetMap | PM | Konfigurasi environment |
| OQ-14 | Retensi media dan lokasi | Bagian 4.7 | Pengelola data | Job retensi |
| OQ-15 | Pengadaan, pemasangan, dan keamanan kalung dan QR | Kalung breakaway. Rekans Caps dan SUPER-SUB berkoordinasi dengan mitra; PM meminta persetujuan pengelola kucing. Format QR `MTP1` sudah final sehingga QR dapat dicetak kapan saja | Mitra dan pengelola | Pengadaan |
| OQ-16 | Scan umum otomatis membuat sighting | Tidak; aturan di bagian 4.4 | Rekans Caps dan SUPER-SUB | Aturan sighting |

**Yang perlu dikonfirmasi pihak luar sebelum pilot nyata:** akses SSO dan atribut mahasiswa (kampus); titik spot dan izin pemasangan QR spot (pengelola lokasi); kebijakan kalung dan QR (pengelola kucing atau mitra); kebijakan pengembalian dan SOP insiden (pengelola dan mitra); retensi dan penghapusan data (pengelola data). Aplikasi tidak menyatakan layanan, izin, atau kebijakan tersebut sudah ada sebelum konfirmasinya tercatat.

## 17. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Fondasi Core terlambat | Lima kelompok tertahan | Target 9 November, pekerjaan persiapan paralel, delegasi komponen Flutter |
| SSO kampus tidak tersedia atau tidak memberi status mahasiswa | Kelayakan adopsi kurang kuat | Verifikasi email dan OTP; ADP-01 memeriksa user\_type; ganti lewat AuthProvider saat SSO ada |
| QR spot disalin atau foto dipakai ulang (tanpa GPS) | Pengajuan palsu dan reward tidak tepat | QR dapat dicabut, batas waktu sesi, cooldown, deteksi foto dobel, review sampel dan flag, pembatasan harian; PM menerima risiko sisa |
| Pemilik Core dan reviewer belum ditunjuk | Persetujuan perubahan tertahan | PM menunjuk reviewer teknis dan owner layanan |
| Dataset ML kecil, kucing mirip | Salah identifikasi | Akinator sebagai jalur utama, kandidat atau INCONCLUSIVE, konfirmasi pengguna, ML\_ENABLED |
| Tidak ada relawan atau notifikasi gagal | Laporan terlambat | Antrean admin, status akurat, eskalasi manual, tanpa janji waktu respons |
| Kebocoran lokasi atau foto privat | Privasi dan keselamatan | Policy server, resource publik terpisah, storage privat, retensi, uji negatif |
| Adopsi ganda atau reward ganda | Konflik data dan saldo | Indeks unik parsial, transaksi, penguncian, idempotency key, uji bersamaan |
| Cakupan lima PRD melebihi 6 minggu | Keterlambatan | P0 dikunci; P1 diturunkan bila terlambat; tidak menghapus kebutuhan akademik secara sepihak |
| Konflik merge dan skema | Pekerjaan hilang atau rusak | Modul terpisah, CODEOWNERS, migration terkunci setelah reset, sinkronisasi harian |
| Hosting tanpa PostGIS atau layanan peta, email, push tidak siap | Fitur geospasial dan notifikasi terganggu | Fallback Haversine dan grid; notifikasi in-app sebagai sumber status; mock untuk pengembangan tanpa menyatakan layanan nyata aktif |
| Kesejahteraan kucing dan pemasangan tag | Gangguan fisik dan operasional | Konsultasi mitra, kalung breakaway, aturan interaksi, tanpa insentif untuk kontak fisik |

## Lampiran A. Aturan Verifikasi dan Reward Acumalaka

Parameter di sini adalah default dari PRD AFS, disimpan di `feeding_settings`, diuji pada pilot, dan hanya berubah lewat konfigurasi yang diaudit. Aturan R3 (pemeriksaan GPS pada scan dan intent) dan R9 (sinyal lokasi palsu) dari PRD sumber **dihapus** karena AFS tidak memakai GPS untuk verifikasi. Pemeriksaan lokasi dan semua ujinya tidak boleh diam-diam tetap berjalan.

| Aturan | Pemeriksaan dan hasil |
| --- | --- |
| R1 | Token QR spot aktif dan status spot ACTIVE saat sesi dibuat; simpan versi QR dan spot yang berlaku. Tidak valid berarti sesi tidak terbentuk. |
| R2 | Sesi milik pengguna, belum dipakai, dan belum lewat batas waktu. Retry idempoten mengembalikan hasil sebelumnya; sesi bekas atau kedaluwarsa ditolak. |
| R4 | Cooldown 6 jam dihitung dari waktu pengajuan lengkap terakhir per pengguna dan spot, termasuk yang ditolak. Retry dan banding untuk aktivitas yang sama bukan kegiatan baru. |
| R5 | Finalisasi membutuhkan 1 sampai 3 foto, format dan ukuran sah, dan dapat didekode. Foto tidak lengkap tetap DRAFT. |
| R6 | SHA-256 identik pada pengajuan lain menghasilkan flag PHOTO\_REUSED (review). Retry dengan ID dan byte yang sama bukan duplikasi. Hash tidak menjamin semua kecurangan terdeteksi. |
| R7 (P1) | pHash 64 bit dengan jarak Hamming 8 atau kurang dalam 90 hari memberi flag PHOTO\_SIMILAR untuk review, bukan penolakan otomatis. Tidak diklaim aktif bila belum tersedia. |
| R8 | Bila EXIF tersedia, selisih waktu lebih dari 15 menit dari intent server memberi flag TIME\_MISMATCH untuk review. EXIF dapat diubah dan bukan bukti mutlak. |

Urutan evaluasi: alasan penolakan, lalu alasan review, lalu VERIFIED bila tidak ada pemicu. Dua pengajuan pertama pengguna, sampel acak 10%, dan semua flag masuk review; hasil sampling disimpan agar retry tidak mengundi ulang. Reviewer tidak menilai pengajuannya sendiri. Foto membantu pemeriksaan tetapi tidak membuktikan kucing benar-benar makan, dan QR yang sah tidak membuktikan keberadaan fisik.

### A.1 Rumus agregat dan potensi reward (P1)

Pada waktu t, jendela W adalah 14 hari terakhir. N adalah jumlah aktivitas VERIFIED dengan waktu kejadian dalam W. P adalah jumlah aktivitas SUBMITTED atau UNDER\_REVIEW dalam W. Target T = 14 aktivitas per spot (bukan ukuran kebutuhan pakan).

- Coverage C = min(N / T, 1). Hanya N yang masuk heatmap.
- Need S = 1 - min((N + P) / T, 1).
- Multiplier M = 0,5 + 1,5 x S.
- Poin potensial = pembulatan setengah ke atas dari (B x M), dengan B = 10, sehingga berkisar 5 sampai 20.
- Kalibrasi: bila usia spot kurang dari 7 hari atau jumlah data seluruh kampus kurang dari 30 aktivitas, M = 1 dan potensi 10 poin, dengan label data belum cukup. Ambang ini perlu divalidasi.
- Potensi ditetapkan sekali saat finalisasi diterima server dan disimpan sebagai snapshot (N, P, T, B, config\_version). Review yang tertunda dan perubahan konfigurasi tidak menghitung ulang transaksi lama.
- Contoh: N = 6, P = 0 menghasilkan C sekitar 0,4286 dan 14 poin. Bila P = 1, potensi menjadi 13 poin. Aktivitas VERIFIED saat kuota harian habis tetap dihitung dalam N tetapi mendapat 0 poin.
- Zona memakai rerata C dari spot ACTIVE dengan data cukup, bukan pengali tambahan. Label di aplikasi menyebut aktivitas tercatat, bukan tingkat kenyang kucing.
- Snapshot diperbarui normal paling lambat tiap 60 detik dan dianggap usang bila lebih dari 60 menit. Gagal menghitung bukan angka nol.
- Sebelum reward dan ledger siap, reward dinonaktifkan dan potensi tidak ditampilkan sebagai saldo.

## Lampiran B. Perubahan dari PRD Masing-masing Kelompok

Ringkasan apa yang berbeda dari PRD asli tiap kelompok. Alasannya ada di bagian yang disebutkan.

| Kelompok | Yang berubah |
| --- | --- |
| SUPER-SUB (Telcat) | Aplikasi PWA atau React diganti Flutter dan scanner web diganti mobile\_scanner (bagian 2). Tabel cats, saldo poin (total\_points), dan laporan sakit milik sendiri dihapus: memakai tabel kucing bersama, ledger Core, dan form insiden Optimind (bagian 3.3, 4.5, 6.4). QR berupa kode MTP1, bukan alamat web (bagian 2). Poin penjinakan diturunkan dari 100, 200, 400 menjadi 10, 20, 40 sebagai default (bagian 9.4). Leaderboard dihitung dari ledger Core. |
| Rekans Caps | Alur mobile web diganti Flutter. Google Sheets hanya sumber impor awal, bukan database harian (CAT-06). Tabel Perjumpaan diganti catatan perjumpaan bersama (bagian 4.4). Unique\_id tetap dicetak sebagai kode cadangan, sedangkan isi QR adalah token MTP1 (bagian 4.2). Akinator berjalan di Laravel dan menjadi P0. Identifikasi foto menjadi P1 dengan layanan FastAPI dan flag ML\_ENABLED. |
| Optimind | Web React diganti Flutter untuk pelapor dan relawan, serta Filament untuk admin. Dispatch awal berupa rekomendasi lalu admin menetapkan. Kategori ditambah DAMAGED\_QR, dan laporan NEW\_CAT masuk antrean kurasi Rekans Caps. Poin laporan diberikan setelah admin memverifikasi. Kode status berbahasa Inggris (bagian 5.5). Optimind menjadi pemilik tunggal laporan insiden fisik di kampus. |
| E-Nigma | Status kesiapan adopsi memakai enum baru dan dipisahkan dari status keberadaan dan kesehatan kucing (bagian 5.1). Perubahan status lewat layanan dan event, bukan UPDATE langsung. Verifikasi mahasiswa lewat email terverifikasi dan user\_type, SSO menyusul. Kunci pengambilan 48 jam memakai tabel terpisah. Pengembalian fisik ke kampus dimatikan dulu lewat flag sampai kebijakan disahkan. Kendala adopsi tetap di E-Nigma dan hanya ditautkan ke Optimind bila insiden di kampus. |
| Acumalaka | Pemeriksaan GPS (aturan R3 dan R9) dihapus; lokasi sesi dari lokasi spot dan GPS hanya untuk mengurutkan spot terdekat di HP. Reviewer menjadi permission feeding.review, bukan role baru. Jalur Kasih Makan umum dengan 20 poin datar dihapus. Kuota 3 reward per hari ditegakkan PointService. Batas 15 menit untuk intent dan 60 menit untuk finalisasi serta cooldown 6 jam dipertahankan. Rumus reward 5 sampai 20 menjadi P1 (Lampiran A.1). |

## Lampiran C. Urutan Git dan Catatan untuk Agen Pengkodean

### C.1 Urutan Git dari fondasi sampai rilis

1. PM mengerjakan fondasi (checklist 13.1) di branch kerja seperti `chore/reset-skeleton`, lalu menggabungkannya ke `development`. Jika proteksi branch sudah mewajibkan approval, aktifkan proteksi setelah fondasi masuk atau minta satu orang lain menyetujui PR fondasi.
2. PM memberi tag `v0.1-core` di `development`.
3. PM membuat lima branch tim dari `development` (bukan dari `main`): `team/acumalaka`, `team/rekans-caps`, `team/super-sub`, `team/enigma`, `team/optimind`.
4. Anggota membuat branch tugas dari branch tim dan membuka PR ke branch tim. Ketua kelompok membuka PR dari branch tim ke `development`; PM mereview.
5. Sebelum mulai kerja, setiap kelompok menjalankan `git merge development` ke branch timnya.
6. `main` hanya diisi lewat PR dari `development` setelah uji integrasi di minggu 13.

Sebelum `v0.1-core` ada, kelompok tidak membuat migration atau tabel. Mereka hanya mengerjakan persiapan: rancangan API, desain layar dengan data tiruan, dan unit test untuk logika murni.

### C.2 Fondasi yang tidak boleh ditunda dan yang boleh ditunda

| Harus ada sebelum kelompok mulai (9 November) | Boleh menyusul setelah kode kelompok masuk |
| --- | --- |
| Urutan migration dan tipe ID ULID; tabel users dan cats beserta tiga status | Leaderboard dan badge (P1) |
| Kerangka PointService dan CatStatusService yang sudah bisa dipanggil | Push FCM dan penyempurnaan notifikasi |
| Login, role, dan permission dasar | Penataan tampilan Filament |
| Middleware Idempotency dan ApiResponse | Penyatuan komponen UI bersama |
| Pendaftaran otomatis route, migration, listener, resource Filament, dan tombol hub | Peta lintas modul dan uji integrasi lintas modul |

### C.3 Catatan untuk agen pengkodean (misalnya di IDE agen)

- Simpan dokumen ini sebagai `docs/PRD.md` di repo dan tambahkan `AGENTS.md` di root repo yang merangkum aturan keras bagian 2, 3, 4, 5, dan 9.
- Dokumen ini disusun dari daftar file repo dan dokumen lain, bukan dari pembacaan kode. Sebelum mengubah apa pun, agen membaca `backend/composer.json`, `frontend/pubspec.yaml`, `ModuleServiceProvider.php`, migration Core dan Cat, lalu melaporkan selisihnya dengan PRD dan menunggu persetujuan PM.
- Jika kode dan PRD berbeda, ikuti bagian 2 (Keputusan Terkunci). Untuk hal lain, tanyakan kepada PM; jangan menebak.
- Kerjakan satu butir checklist 13.1 per PR. Jalankan `php artisan test` dan `flutter analyze` sebelum menyatakan selesai.
- Agen tidak mengubah Core, Providers, Support, routes, atau migration inti kecuali tugasnya memang itu.
