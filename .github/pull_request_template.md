## Ringkasan Perubahan
<!-- Jelaskan secara singkat perubahan apa yang dilakukan -->

## ID Kebutuhan PRD
<!-- Contoh: AFS-04, CAT-02, FIX-01, dll -->

## Modul Terkait
- [ ] Core
- [ ] Cat
- [ ] FeedingSpot (Acumalaka)
- [ ] CatHunter (SUPER-SUB)
- [ ] CatAdoption (E-Nigma)
- [ ] IncidentReport (Optimind)
- [ ] CatIdentification (Rekans Caps)
- [ ] Frontend Core

## Checklist
- [ ] Ada migrasi database baru? (Wajib berawalan prefix modul & memiliki `down()`)
- [ ] Menyentuh file Core/Providers/Support? (Jika ya, wajib assign PM sebagai reviewer)
- [ ] Perubahan API terdokumentasi di OpenAPI (`docs/api/<modul>.yaml`)?
- [ ] Ada dependency package baru?
- [ ] `php artisan test` berhasil?
- [ ] `flutter analyze` & `flutter test` berhasil?
- [ ] Endpoint tulis rawan duplikat menggunakan header `Idempotency-Key`?
- [ ] Izin otorisasi dicek lewat permission/policy, bukan string role?
- [ ] Format respons mematuhi `ApiResponse`?
- [ ] Tidak ada rahasia, kredensial, atau data pribadi di dalam commit?

## Bukti Pengujian & Tangkapan Layar
<!-- Cantumkan hasil pengujian unit/feature test dan tangkapan layar UI jika ada -->

## Risiko & Rencana Rollback
<!-- Jelaskan potensi risiko dan bagaimana cara rollback jika terjadi masalah -->

