# Entity Relationship Diagram (ERD) - Adopt Feeding Spot (AFS)

Modul **Adopt Feeding Spot (AFS)** mengelola titik stasiun pakan kucing kampus, sesi pemberian pakan relawan berbasis QR token, pemeriksaan bukti otomatis tanpa GPS pengguna, serta agregasi kebutuhan pakan 14 hari.

## Diagram Hubungan Entitas (Mermaid)

```mermaid
erDiagram
    USERS ||--o{ FEEDING_ACTIVITIES : "melakukan"
    FEEDING_SPOTS ||--o{ FEEDING_ACTIVITIES : "lokasi pakan"
    FEEDING_SPOTS ||--o{ FEEDING_SPOT_CATS : "dihuni"
    CATS ||--o{ FEEDING_SPOT_CATS : "berada di spot"
    CATS ||--o{ FEEDING_ACTIVITIES : "kucing yang diberi makan (opsional)"
    TERRITORIES ||--o{ FEEDING_SPOTS : "wilayah teritorial"
    FEEDING_SPOTS ||--o{ FEEDING_AGGREGATES : "agregat berkala"
    FEEDING_ACTIVITIES ||--o{ FEEDING_ACTIVITY_MEDIA : "bukti foto (1-3)"
    MEDIA_FILES ||--o{ FEEDING_ACTIVITY_MEDIA : "relasi media core"
    FEEDING_ACTIVITIES ||--o{ FEEDING_RULE_RESULTS : "hasil evaluasi rule"

    FEEDING_SPOTS {
        char(26) id PK "ULID"
        string code UK "FS-TULT-01"
        string name "Nama Spot"
        text description "Keterangan titik lokasi"
        decimal latitude "Koordinat spot resmi"
        decimal longitude "Koordinat spot resmi"
        char(26) territory_id FK "Wilayah/zona kampus"
        string qr_token UK "Token QR spot resmi"
        string status "ACTIVE, MAINTENANCE, TEMPORARILY_UNAVAILABLE, INACTIVE"
        timestamps created_at_updated_at
    }

    FEEDING_SPOT_CATS {
        char(26) spot_id PK,FK "ID Spot"
        char(26) cat_id PK,FK "ID Kucing"
        timestamps created_at_updated_at
    }

    FEEDING_ACTIVITIES {
        char(26) id PK "ULID"
        string feeding_record_ref UK "Kode referensi unik (REF-MTP-...)"
        char(26) user_id FK "Relawan / Pengguna"
        char(26) spot_id FK "Feeding Spot"
        char(26) cat_id FK "Kucing (opsional, AFS-10/13)"
        string food_type "dry_food, wet_food, dll"
        string food_amount "1 mangkuk, setengah kaleng, dll"
        decimal location_lat "Disalin dari spot (Aturan Keras #8)"
        decimal location_lng "Disalin dari spot (Aturan Keras #8)"
        string status "DRAFT, SUBMITTED, UNDER_REVIEW, VERIFIED, REJECTED, EXPIRED"
        string reward_status "PENDING, CREDITED, NOT_ELIGIBLE"
        integer potential_points "Poin potensial"
        json reward_snapshot "Snapshot perhitungan poin & capped flag"
        timestamp scanned_at "Waktu scan QR pembuka sesi"
        timestamp intent_at "Waktu konfirmasi niat pakan"
        timestamp intent_deadline_at "Batas waktu intent (scanned_at + 15m)"
        timestamp finalize_deadline_at "Batas waktu finalisasi (scanned_at + 60m)"
        timestamp finalized_at "Waktu submit bukti foto"
        timestamps created_at_updated_at
    }

    FEEDING_ACTIVITY_MEDIA {
        char(26) id PK "ULID"
        char(26) activity_id FK "Feeding Activity"
        char(26) media_id FK "Media File Core (purpose: feeding_proof)"
        integer sort_order "Urutan foto (1-3)"
        timestamps created_at_updated_at
    }

    FEEDING_RULE_RESULTS {
        char(26) id PK "ULID"
        char(26) activity_id FK "Feeding Activity"
        string rule "R1_COOLDOWN, R2_NEW_USER, R4_PHOTO_REUSED, R5_RATE_LIMIT, R6_TIME_VALIDITY, R8_COMMUNITY_FLAG"
        string result "PASS, REVIEW, REJECT"
        text detail "Alasan keputusan rule engine"
        timestamps created_at_updated_at
    }

    FEEDING_AGGREGATES {
        char(26) id PK "ULID"
        char(26) spot_id FK "Feeding Spot"
        integer window_days "14 hari"
        integer total_feedings "Total pemberian pakan"
        integer verified_count "Jumlah terverifikasi"
        integer pending_count "Jumlah antrean review"
        timestamp last_fed_at "Waktu pakan terakhir tercatat"
        timestamp computed_at "Waktu penghitungan berkala"
        timestamps created_at_updated_at
    }

    FEEDING_SETTINGS {
        char(26) id PK "ULID"
        string key UK "Kunci konfigurasi"
        text value "Nilai setting"
        string type "string, integer, float, boolean, json"
        text description "Penjelasan parameter"
        timestamps created_at_updated_at
    }
```

## Karakteristik Khusus Skema AFS
1. **Aturan Keras #1 & #8 (Tanpa Tabel Duplikat Kucing & Tanpa GPS Pengguna):**
   - Tidak ada tabel `cats` buatan sendiri di modul ini; relasi merujuk ke tabel inti `cats`.
   - Koordinat pada `feeding_activities` (`location_lat`, `location_lng`) disalin langsung dari `feeding_spots` saat QR dipindai. Tidak ada pengiriman/penyimpanan koordinat GPS dari perangkat relawan ke server.
2. **Pemisahan Status Aktivitas dan Status Reward:**
   - `status`: status siklus hidup sesi pemberian pakan (`DRAFT` -> `UNDER_REVIEW` / `VERIFIED` / `REJECTED` / `EXPIRED`).
   - `reward_status`: status perolehan poin relawan (`PENDING`, `CREDITED`, `NOT_ELIGIBLE`). Jika relawan telah melampaui kuota harian (`daily_cap_count`), aktivitas tetap berstatus `VERIFIED` namun `reward_status` berstatus `NOT_ELIGIBLE` (`reward_capped: true`).
3. **Relasi Spot-Kucing (`feeding_spot_cats`):**
   - Mendukung hub kucing (`CatActionProviderInterface`) sehingga aksi tombol pakan pada profil kucing hanya muncul jika kucing terdaftar aktif pada spot di sekitar.
