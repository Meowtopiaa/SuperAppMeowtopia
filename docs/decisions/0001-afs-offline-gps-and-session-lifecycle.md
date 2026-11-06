# ADR 0001: Arsitektur Siklus Hidup Sesi, Privasi Tanpa GPS, dan Pemisahan Reward pada Modul AFS

- **Status:** Diterima (Accepted)
- **Tanggal:** 2026-11-06
- **Pengambil Keputusan:** Tim Acumalaka & PM Meowtopia

---

## 1. Konteks dan Masalah
Modul **Adopt Feeding Spot (AFS)** bertanggung jawab atas pencatatan aktivitas pemberian pakan di kampus Telkom University. Terdapat beberapa tantangan desain:
1. **Privasi & Keakuratan Lokasi:** GPS perangkat mahasiswa sering kali tidak akurat di dalam lorong/gedung kampus dan memiliki implikasi privasi data jika koordinat personal mahasiswa dilacak secara langsung (Aturan Keras #8 & OQ-01).
2. **Kecurangan & Duplikasi:** Risiko mahasiswa mengunggah foto berulang atau mengklaim pakan dari luar spot.
3. **Penyalahgunaan Reward:** Mahasiswa dapat mencoba melakukan spam klaim poin melebihi batas wajar harian.

---

## 2. Keputusan Arsitektur

### D1: Eliminasi GPS Pengguna di Sisi Server (Aturan Keras #8)
- Backend **tidak pernah** menerima atau menyimpan koordinat GPS dari perangkat mahasiswa.
- Koordinat sesi pakan (`location_lat`, `location_lng`) disalin langsung dari entitas `FeedingSpot` saat relawan memindai token QR resmi spot.
- GPS pengguna hanya diakses di sisi aplikasi mobile (Flutter) secara lokal untuk menghitung jarak haversine dan mengurutkan daftar spot dari yang terdekat. Jika izin lokasi ditolak oleh pengguna, aplikasi otomatis fallback ke pengurutan menurut abjad nama spot.

### D2: Dual Countdown Timer Siklus Hidup Sesi
Sesi pemberian pakan menerapkan mekanisme berjangka waktu ganda (dual-window):
1. **Window Niat (Intent Window - 15 Menit):** Mahasiswa wajib mengonfirmasi niat memberi makan dalam waktu maksimal 15 menit setelah memindai QR spot (`POST /feeding/activities/{id}/intent`).
2. **Window Finalisasi (Finalize Window - 60 Menit):** Mahasiswa memiliki waktu hingga 60 menit sejak pemindaian QR awal untuk mengunggah 1–3 foto bukti pakan (`POST /feeding/activities/{id}/finalize`).
3. **Command Terjadwal Pengusiran Sesi:** Artisan command `feeding:expire-sessions` berjalan terjadwal untuk menandai sesi yang melewati batas waktu sebagai `EXPIRED`.

### D3: Pemisahan Siklus Hidup Status Aktivitas dan Status Reward (IT-06)
- Status aktivitas pakan (`status`: `DRAFT`, `UNDER_REVIEW`, `VERIFIED`, `REJECTED`, `EXPIRED`) dipisahkan secara tegas dari status penghargaan poin (`reward_status`: `PENDING`, `CREDITED`, `NOT_ELIGIBLE`).
- Apabila kuota poin harian mahasiswa telah habis (`daily_cap_count` atau `daily_cap_points`), aktivitas pakan yang valid tetap berstatus `VERIFIED` untuk kepentingan data kesehatan kucing, namun `reward_status` diset ke `NOT_ELIGIBLE` dengan flag `reward_capped: true` dan `credited_points: 0`.

### D4: Idempotensi Sisi Server & Replay Aman
- Seluruh endpoint tulis rawan duplikasi (`POST /feeding/activities`, `/intent`, `/finalize`) mewajibkan header `Idempotency-Key`.
- Pemanggilan ulang endpoint finalisasi dengan kunci yang sama mengembalikan status idempotensi replay (`is_replay: true`) tanpa menduplikasi kredit poin di `PointService`.

---

## 3. Konsekuensi
- **Positif:** Menjamin kepatuhan privasi (tidak ada tracking GPS pengguna di database), mencegah eksploitasi poin ganda, dan menjaga konsistensi data riwayat kucing.
- **Toleransi:** Mahasiswa harus berada di lokasi fisik untuk memindai token QR spot yang tertempel.
