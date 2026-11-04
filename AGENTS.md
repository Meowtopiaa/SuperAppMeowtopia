# Meowtopia: Panduan untuk Agen Pengkodean

Sumber kebenaran: `docs/PRD.md` (PRD Final v1.1). Jika kode dan PRD berbeda, laporkan ke PM. Jangan menebak.

## Stack
- **Backend:** Laravel (REST `/api/v1`, `backend/app/Modules/*`)
- **Frontend:** Flutter (`frontend/lib`)
- **Database:** PostgreSQL + PostGIS (ULID untuk semua ID, `char(26)`)
- **Admin Panel:** Filament (`/admin`)

## Aturan Keras
1. **Satu tabel cats:** Hanya satu tabel `cats`. Jangan buat tabel kucing, poin, atau laporan sendiri di modul.
2. **Poin & Status Kucing:** Poin hanya lewat `PointService::award()`. Status kucing hanya lewat `CatStatusService::change()`.
3. **RBAC & Autentikasi:** Izin lewat permission atau policy (Spatie), bukan string role. Registrasi tidak menerima role dari input.
4. **Idempotensi:** Endpoint tulis yang rawan duplikat (bertanda † di PRD) wajib memakai header `Idempotency-Key`.
5. **Format Respons API:** Selalu lewat `app/Support/ApiResponse`:
   - Sukses: `{ success, message, data, meta? }`
   - Gagal: `{ success: false, code, message, errors?, request_id }`
6. **Migration:** Hanya di `Modules/<Nama>/Database/Migrations` (M besar), wajib punya `down()`, nama tabel berawalan prefix modul (`feeding_`, `adoption_`, `incident_`). Jangan edit migration yang sudah di-merge.
7. **Integritas Core:** Jangan ubah Core, Providers, Support, routes, database inti, atau `frontend/lib/core` kecuali tugasnya memang itu.
8. **Acumalaka & GPS:** Tidak ada GPS untuk verifikasi. GPS hanya untuk mengurutkan spot terdekat di HP tanpa dikirim atau disimpan di server.
9. **Privasi Data:** Data privat (nomor telepon, foto rumah, koordinat presisi) tidak boleh ada di respons publik.
10. **Pesan Sukses:** Pesan sukses hanya dikembalikan setelah data benar-benar tersimpan.

## Cara Kerja
- Satu langkah per PR. Branch: `chore/<nama>` atau `team/<kelompok>/<tugas>`. Commit: `tipe(modul): deskripsi`.
- Sebelum mengubah, baca file terkait dan jelaskan rencana singkat.
- Setelah mengubah, jalankan `php artisan test` dan `flutter analyze`.
- Setiap endpoint punya tes: sukses, validasi gagal, akses ditolak.
- Jika ragu, berhenti dan tanya PM.

