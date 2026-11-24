<?php

namespace App\Modules\FeedingSpot\Services;

use App\Models\User;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Models\FeedingSpotHistory;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class FeedingSpotManagementService
{
    public const ALLOWED_STATUSES = [
        'ACTIVE',
        'MAINTENANCE',
        'TEMPORARILY_UNAVAILABLE',
        'INACTIVE',
    ];

    /**
     * Referensi Resmi 38 Lokasi Kampus Telkom University Berdasarkan Denah Resmi Kampus.
     * Setiap entri memiliki nomor denah (1..38), nama resmi sesuai denah, prefix kode spot,
     * kode territory, dan titik koordinat bangunan di dalam poligon kampus.
     */
    public const CAMPUS_LOCATIONS = [
        [
            'number' => 1,
            'name' => 'Telkom University Landmark Tower (TULT)',
            'short_name' => 'Landmark Tower (TULT)',
            'code_prefix' => 'SPOT-TULT',
            'territory_code' => 'TULT',
            'lat' => -6.9693000,
            'lng' => 107.6281500,
        ],
        [
            'number' => 2,
            'name' => 'Kantin TULT',
            'short_name' => 'Kantin TULT',
            'code_prefix' => 'SPOT-KTULT',
            'territory_code' => 'TULT',
            'lat' => -6.9698500,
            'lng' => 107.6281000,
        ],
        [
            'number' => 3,
            'name' => 'Asrama Putra',
            'short_name' => 'Asrama Putra',
            'code_prefix' => 'SPOT-ASPA',
            'territory_code' => 'ASRAMA_PA',
            'lat' => -6.9704500,
            'lng' => 107.6279500,
        ],
        [
            'number' => 4,
            'name' => 'Gedung Batek - BTP (Bandung Techno Park)',
            'short_name' => 'Gedung Batek (BTP)',
            'code_prefix' => 'SPOT-BTP',
            'territory_code' => 'GKU',
            'lat' => -6.9703500,
            'lng' => 107.6299500,
        ],
        [
            'number' => 5,
            'name' => 'Sport Center',
            'short_name' => 'Sport Center',
            'code_prefix' => 'SPOT-SPORT',
            'territory_code' => 'ASRAMA_PA',
            'lat' => -6.9712500,
            'lng' => 107.6283500,
        ],
        [
            'number' => 6,
            'name' => 'Asrama Putri',
            'short_name' => 'Asrama Putri',
            'code_prefix' => 'SPOT-ASRP',
            'territory_code' => 'ASRAMA_PI',
            'lat' => -6.9722000,
            'lng' => 107.6286500,
        ],
        [
            'number' => 7,
            'name' => 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)',
            'short_name' => 'Gedung Tokong Nanas (GKU)',
            'code_prefix' => 'SPOT-GKU',
            'territory_code' => 'GKU',
            'lat' => -6.9719500,
            'lng' => 107.6295500,
        ],
        [
            'number' => 8,
            'name' => 'Tel-U Coffee',
            'short_name' => 'Tel-U Coffee',
            'code_prefix' => 'SPOT-COFFEE',
            'territory_code' => 'GKU',
            'lat' => -6.9717500,
            'lng' => 107.6290500,
        ],
        [
            'number' => 9,
            'name' => 'Gedung Lingian - Gd.L (Lab. Perhotelan)',
            'short_name' => 'Gedung Lingian',
            'code_prefix' => 'SPOT-LING',
            'territory_code' => 'FIT',
            'lat' => -6.9727500,
            'lng' => 107.6294500,
        ],
        [
            'number' => 10,
            'name' => 'Research & Recreation Area',
            'short_name' => 'Research & Recreation Area',
            'code_prefix' => 'SPOT-RRA',
            'territory_code' => 'GKU',
            'lat' => -6.9711000,
            'lng' => 107.6297500,
        ],
        [
            'number' => 11,
            'name' => 'Gedung Benggala - TUCH (Tel-U Convention Center)',
            'short_name' => 'Gedung Benggala (TUCH)',
            'code_prefix' => 'SPOT-TUCH',
            'territory_code' => 'GKU',
            'lat' => -6.9716500,
            'lng' => 107.6307500,
        ],
        [
            'number' => 12,
            'name' => 'Gedung Sebatik (FIK)',
            'short_name' => 'Gedung Sebatik (FIK)',
            'code_prefix' => 'SPOT-FIK',
            'territory_code' => 'GKU',
            'lat' => -6.9720500,
            'lng' => 107.6311500,
        ],
        [
            'number' => 13,
            'name' => 'Gd. Miossu & Maratua (Gd. C & D - FEB)',
            'short_name' => 'Gedung Miossu & Maratua',
            'code_prefix' => 'SPOT-FEB',
            'territory_code' => 'GKU',
            'lat' => -6.9715500,
            'lng' => 107.6319500,
        ],
        [
            'number' => 14,
            'name' => 'Open Library',
            'short_name' => 'Open Library',
            'code_prefix' => 'SPOT-LIB',
            'territory_code' => 'GKU',
            'lat' => -6.9719500,
            'lng' => 107.6322500,
        ],
        [
            'number' => 15,
            'name' => 'Kantin Dekanat',
            'short_name' => 'Kantin Dekanat',
            'code_prefix' => 'SPOT-KDEK',
            'territory_code' => 'GKU',
            'lat' => -6.9722000,
            'lng' => 107.6326500,
        ],
        [
            'number' => 16,
            'name' => 'Gd. Kawalusu & Intata (Gd. A & B - FKS)',
            'short_name' => 'Gedung Kawalusu & Intata',
            'code_prefix' => 'SPOT-FKS',
            'territory_code' => 'GKU',
            'lat' => -6.9725500,
            'lng' => 107.6329000,
        ],
        [
            'number' => 17,
            'name' => 'Gedung Selaru (FIT)',
            'short_name' => 'Gedung Selaru (FIT)',
            'code_prefix' => 'SPOT-FIT',
            'territory_code' => 'FIT',
            'lat' => -6.9731500,
            'lng' => 107.6324500,
        ],
        [
            'number' => 18,
            'name' => 'Danau (Situ Techno)',
            'short_name' => 'Danau (Situ Techno)',
            'code_prefix' => 'SPOT-DANAU',
            'territory_code' => 'GKU',
            'lat' => -6.9729500,
            'lng' => 107.6311500,
        ],
        [
            'number' => 19,
            'name' => 'Gedung Bangkit (Gd. Rektorat)',
            'short_name' => 'Gedung Bangkit (Rektorat)',
            'code_prefix' => 'SPOT-REKT',
            'territory_code' => 'GKU',
            'lat' => -6.9734500,
            'lng' => 107.6301500,
        ],
        [
            'number' => 20,
            'name' => 'Gedung Damar - Gd. K (Gedung Auditorium)',
            'short_name' => 'Gedung Damar (Auditorium)',
            'code_prefix' => 'SPOT-DAMAR',
            'territory_code' => 'GKU',
            'lat' => -6.9738500,
            'lng' => 107.6295500,
        ],
        [
            'number' => 21,
            'name' => 'Grha Wiyata Cacuk Sudarijanto',
            'short_name' => 'Grha Wiyata Cacuk Sudarijanto',
            'code_prefix' => 'SPOT-CACUK',
            'territory_code' => 'GKU',
            'lat' => -6.9740500,
            'lng' => 107.6306500,
        ],
        [
            'number' => 22,
            'name' => 'Gedung Deli (Gd. P)',
            'short_name' => 'Gedung Deli',
            'code_prefix' => 'SPOT-DELI',
            'territory_code' => 'GKU',
            'lat' => -6.9742500,
            'lng' => 107.6290500,
        ],
        [
            'number' => 23,
            'name' => 'Gedung Arakula (Gd. O)',
            'short_name' => 'Gedung Arakula',
            'code_prefix' => 'SPOT-ARAK',
            'territory_code' => 'GKU',
            'lat' => -6.9747500,
            'lng' => 107.6288500,
        ],
        [
            'number' => 24,
            'name' => 'Gedung Barung (Gd. N)',
            'short_name' => 'Gedung Barung',
            'code_prefix' => 'SPOT-BARUNG',
            'territory_code' => 'GKU',
            'lat' => -6.9752500,
            'lng' => 107.6291800,
        ],
        [
            'number' => 25,
            'name' => 'Gedung Penambulai (Gd. D)',
            'short_name' => 'Gedung Penambulai',
            'code_prefix' => 'SPOT-PENAM',
            'territory_code' => 'GKU',
            'lat' => -6.9747000,
            'lng' => 107.6298500,
        ],
        [
            'number' => 26,
            'name' => 'Gedung Panehan (Gd. G - Pascasarjana)',
            'short_name' => 'Gedung Panehan',
            'code_prefix' => 'SPOT-PANEH',
            'territory_code' => 'GKU',
            'lat' => -6.9749500,
            'lng' => 107.6303500,
        ],
        [
            'number' => 27,
            'name' => 'Gedung Karang (Gd. C - Pascasarjana)',
            'short_name' => 'Gedung Karang',
            'code_prefix' => 'SPOT-KARANG',
            'territory_code' => 'GKU',
            'lat' => -6.9748000,
            'lng' => 107.6308500,
        ],
        [
            'number' => 28,
            'name' => 'Gedung Pelampong - GSG (Gd. H - GD. Serba Guna)',
            'short_name' => 'Gedung Pelampong (GSG)',
            'code_prefix' => 'SPOT-GSG',
            'territory_code' => 'GKU',
            'lat' => -6.9755500,
            'lng' => 107.6295500,
        ],
        [
            'number' => 29,
            'name' => 'Gd. Kultubai Utara (Gd. E)',
            'short_name' => 'Gedung Kultubai Utara',
            'code_prefix' => 'SPOT-KULTU',
            'territory_code' => 'GKU',
            'lat' => -6.9755000,
            'lng' => 107.6301500,
        ],
        [
            'number' => 30,
            'name' => 'Gd. Kultubai Selatan (Gd. F)',
            'short_name' => 'Gedung Kultubai Selatan',
            'code_prefix' => 'SPOT-KULTS',
            'territory_code' => 'GKU',
            'lat' => -6.9759500,
            'lng' => 107.6304500,
        ],
        [
            'number' => 31,
            'name' => 'Gedung Karaweira (Gd. Student Center)',
            'short_name' => 'Gedung Karaweira (Student Center)',
            'code_prefix' => 'SPOT-SC',
            'territory_code' => 'GKU',
            'lat' => -6.9761500,
            'lng' => 107.6291500,
        ],
        [
            'number' => 32,
            'name' => 'Lapangan Tenis',
            'short_name' => 'Lapangan Tenis',
            'code_prefix' => 'SPOT-TENIS',
            'territory_code' => 'GKU',
            'lat' => -6.9763500,
            'lng' => 107.6294500,
        ],
        [
            'number' => 33,
            'name' => 'Gedung Alor (Gd. Business Center)',
            'short_name' => 'Gedung Alor (Business Center)',
            'code_prefix' => 'SPOT-ALOR',
            'territory_code' => 'GKU',
            'lat' => -6.9762500,
            'lng' => 107.6299000,
        ],
        [
            'number' => 34,
            'name' => 'Kantin Teknik',
            'short_name' => 'Kantin Teknik',
            'code_prefix' => 'SPOT-KTEK',
            'territory_code' => 'GKU',
            'lat' => -6.9765500,
            'lng' => 107.6303500,
        ],
        [
            'number' => 35,
            'name' => 'Greenhouse',
            'short_name' => 'Greenhouse',
            'code_prefix' => 'SPOT-GH',
            'territory_code' => 'GKU',
            'lat' => -6.9764500,
            'lng' => 107.6309500,
        ],
        [
            'number' => 36,
            'name' => 'Pool KBM',
            'short_name' => 'Pool KBM',
            'code_prefix' => 'SPOT-KBM',
            'territory_code' => 'GKU',
            'lat' => -6.9759500,
            'lng' => 107.6317500,
        ],
        [
            'number' => 37,
            'name' => 'Masjid Syamsul Ulum',
            'short_name' => 'Masjid Syamsul Ulum',
            'code_prefix' => 'SPOT-MSU',
            'territory_code' => 'GKU',
            'lat' => -6.9752500,
            'lng' => 107.6316500,
        ],
        [
            'number' => 38,
            'name' => 'Jogging Track',
            'short_name' => 'Jogging Track',
            'code_prefix' => 'SPOT-JOG',
            'territory_code' => 'GKU',
            'lat' => -6.9743500,
            'lng' => 107.6318500,
        ],
    ];

    /**
     * Resolusi lokasi resmi berdasarkan denah 38 lokasi Telkom University.
     * Memprioritaskan kecocokan prefix kode spot bila eksplisit, lalu jarak koordinat terdekat.
     */
    public static function resolveCampusLocation(
        float $latitude,
        float $longitude,
        ?string $spotCode = null,
        ?string $spotName = null
    ): array {
        if ($spotCode !== null && $spotCode !== '') {
            $upperCode = strtoupper(trim($spotCode));
            foreach (self::CAMPUS_LOCATIONS as $loc) {
                $prefix = strtoupper($loc['code_prefix']);
                $shortPrefix = str_replace('SPOT-', 'FS-', $prefix);
                if (str_starts_with($upperCode, $prefix . '-') || str_starts_with($upperCode, $shortPrefix . '-')) {
                    return $loc;
                }
            }
        }

        $bestMatch = self::CAMPUS_LOCATIONS[0];
        $minDistSq = PHP_FLOAT_MAX;

        foreach (self::CAMPUS_LOCATIONS as $loc) {
            $dLat = $latitude - (float) $loc['lat'];
            $dLng = $longitude - (float) $loc['lng'];
            $distSq = ($dLat * $dLat) + ($dLng * $dLng);
            if ($distSq < $minDistSq) {
                $minDistSq = $distSq;
                $bestMatch = $loc;
            }
        }

        return $bestMatch;
    }

    /**
     * Hasilkan kode spot unik secara otomatis berdasarkan lokasi denah kampus (MEOW-29).
     * Format: <CODE_PREFIX>-<NN> (contoh: SPOT-TULT-01, SPOT-GKU-02, SPOT-MSU-01).
     * Aman terhadap kondisi paralel/konkurensi dengan pemeriksaan keunikan di database.
     */
    public function generateUniqueSpotCode(
        float $latitude,
        float $longitude,
        ?string $preferredPrefix = null
    ): string {
        if ($preferredPrefix !== null && trim($preferredPrefix) !== '') {
            $prefix = strtoupper(trim($preferredPrefix));
            $prefix = rtrim($prefix, '-');
        } else {
            $campusLoc = self::resolveCampusLocation($latitude, $longitude);
            $prefix = strtoupper((string) ($campusLoc['code_prefix'] ?? 'SPOT-TELU'));
        }

        if (!str_starts_with($prefix, 'SPOT-') && !str_starts_with($prefix, 'FS-')) {
            $prefix = 'SPOT-' . $prefix;
        }

        $existingCodes = FeedingSpot::query()
            ->where('code', 'like', $prefix . '-%')
            ->lockForUpdate()
            ->pluck('code')
            ->all();

        $maxSeq = 0;
        $pattern = '/^' . preg_quote($prefix, '/') . '-(\d+)$/i';
        foreach ($existingCodes as $existing) {
            if (preg_match($pattern, (string) $existing, $matches)) {
                $num = (int) $matches[1];
                if ($num > $maxSeq) {
                    $maxSeq = $num;
                }
            }
        }

        $nextSeq = $maxSeq + 1;
        while (true) {
            $suffix = str_pad((string) $nextSeq, 2, '0', STR_PAD_LEFT);
            $candidate = "{$prefix}-{$suffix}";
            if (!FeedingSpot::query()->where('code', $candidate)->exists()) {
                return $candidate;
            }
            $nextSeq++;
        }
    }

    /**
     * Simpan foto dokumentasi feeding spot melalui mekanisme storage project dan tabel media_files (MEOW-21).
     * Terpisah dari foto bukti pemberian makan (purpose: spot_photo vs feeding_proof).
     */
    public function storeSpotPhoto(UploadedFile $file, ?User $actor = null): array
    {
        if ($file->getSize() > 5 * 1024 * 1024) {
            throw new InvalidArgumentException('Ukuran foto spot melebihi batas maksimal 5 MB.');
        }

        $ext = strtolower($file->getClientOriginalExtension() ?: $file->extension() ?: 'jpg');
        if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'], true)) {
            throw new InvalidArgumentException('Format file foto tidak didukung. Gunakan JPG, PNG, atau WEBP.');
        }

        $realPath = $file->getRealPath();
        $sha256 = $realPath && file_exists($realPath)
            ? hash_file('sha256', $realPath)
            : hash('sha256', $file->getContent());

        $disk = config('filesystems.default', 'local');
        $mediaId = (string) Str::ulid();
        $fileName = "{$mediaId}.{$ext}";
        $storedPath = 'media/spot_photo/' . $fileName;

        Storage::disk($disk)->put($storedPath, $file->getContent());

        $ownerId = $actor?->id ?? DB::table('users')->value('id');
        if ($ownerId && Schema::hasTable('media_files')) {
            DB::table('media_files')->insert([
                'id' => $mediaId,
                'owner_id' => $ownerId,
                'disk' => $disk,
                'path' => $storedPath,
                'mime' => $file->getMimeType() ?: 'image/jpeg',
                'size_bytes' => (int) $file->getSize(),
                'sha256' => $sha256,
                'purpose' => 'spot_photo',
                'visibility' => 'public',
                'captured_at' => now(),
                'retention_until' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return [
            'media_id' => $ownerId && Schema::hasTable('media_files') ? $mediaId : null,
            'path' => $storedPath,
        ];
    }

    private function deleteSpotPhoto(?string $mediaId, ?string $photoPath): void
    {
        $disk = config('filesystems.default', 'local');

        if ($mediaId && Schema::hasTable('media_files')) {
            $row = DB::table('media_files')
                ->where('id', $mediaId)
                ->where('purpose', 'spot_photo')
                ->first();
            if ($row) {
                $rowDisk = $row->disk ?? $disk;
                if (!empty($row->path) && Storage::disk($rowDisk)->exists($row->path)) {
                    Storage::disk($rowDisk)->delete($row->path);
                }
                DB::table('media_files')->where('id', $mediaId)->delete();
            }
        }

        if ($photoPath && Storage::disk($disk)->exists($photoPath)) {
            Storage::disk($disk)->delete($photoPath);
        }
    }

    /**
     * Polygon Perimeter Resmi Wilayah Kampus Telkom University Bandung
     * (76 titik presisi OSM Way 557649490 + Kantin Teknik, sinkron dengan Flutter CampusSpotMap).
     */
    public const TELKOM_BOUNDARY = [
        [-6.9697046, 107.6307312],
        [-6.9702850, 107.6309752],
        [-6.9703549, 107.6310401],
        [-6.9704453, 107.6311774],
        [-6.9709586, 107.6319851],
        [-6.9714512, 107.6326704],
        [-6.9720409, 107.6335066],
        [-6.9721221, 107.6334442],
        [-6.9721713, 107.6335354],
        [-6.9730965, 107.6334992],
        [-6.9731498, 107.6334415],
        [-6.9732669, 107.6333047],
        [-6.9739019, 107.6326382],
        [-6.9739511, 107.6326248],
        [-6.9740250, 107.6326088],
        [-6.9740603, 107.6325980],
        [-6.9744437, 107.6325403],
        [-6.9747597, 107.6324340],
        [-6.9748191, 107.6324698],
        [-6.9750573, 107.6325926],
        [-6.9752184, 107.6326986],
        [-6.9754460, 107.6329333],
        [-6.9755306, 107.6329688],
        [-6.9756371, 107.6329654],
        [-6.9760504, 107.6329319],
        [-6.9761877, 107.6328865],
        [-6.9762394, 107.6327978],
        [-6.9774654, 107.6315466],
        [-6.9776200, 107.6313900],
        [-6.9779500, 107.6317500],
        [-6.9786500, 107.6310800],
        [-6.9778500, 107.6306200],
        [-6.9777357, 107.6305917],
        [-6.9776897, 107.6301411],
        [-6.9776505, 107.6299500],
        [-6.9776405, 107.6298387],
        [-6.9776425, 107.6297320],
        [-6.9776837, 107.6294491],
        [-6.9777157, 107.6292425],
        [-6.9777250, 107.6290642],
        [-6.9771872, 107.6290481],
        [-6.9756444, 107.6290561],
        [-6.9753076, 107.6290521],
        [-6.9752314, 107.6290444],
        [-6.9752204, 107.6290434],
        [-6.9751658, 107.6289844],
        [-6.9748710, 107.6287074],
        [-6.9743039, 107.6282313],
        [-6.9738060, 107.6277861],
        [-6.9732909, 107.6282461],
        [-6.9731484, 107.6283976],
        [-6.9719577, 107.6283936],
        [-6.9719437, 107.6284074],
        [-6.9719344, 107.6284312],
        [-6.9719360, 107.6284644],
        [-6.9719360, 107.6284781],
        [-6.9713819, 107.6284996],
        [-6.9713727, 107.6281416],
        [-6.9713512, 107.6280972],
        [-6.9712548, 107.6268379],
        [-6.9712235, 107.6267521],
        [-6.9707124, 107.6267702],
        [-6.9702045, 107.6267943],
        [-6.9696254, 107.6275329],
        [-6.9696164, 107.6275597],
        [-6.9694956, 107.6277231],
        [-6.9685079, 107.6275742],
        [-6.9684786, 107.6280342],
        [-6.9684853, 107.6284620],
        [-6.9692014, 107.6286001],
        [-6.9696267, 107.6303470],
        [-6.9697046, 107.6307312],
    ];

    /**
     * Ray-casting algorithm untuk memvalidasi apakah titik koordinat berada di dalam poligon Telkom University.
     */
    public static function isPointInsideTelkomCampus(float $latitude, float $longitude): bool
    {
        $inside = false;
        $boundary = self::TELKOM_BOUNDARY;
        $count = count($boundary);

        for ($i = 0, $j = $count - 1; $i < $count; $j = $i++) {
            $xi = $boundary[$i][0];
            $yi = $boundary[$i][1];
            $xj = $boundary[$j][0];
            $yj = $boundary[$j][1];

            $intersect = (($yi > $longitude) !== ($yj > $longitude))
                && ($latitude < ($xj - $xi) * ($longitude - $yi) / (($yj - $yi) ?: 1e-12) + $xi);

            if ($intersect) {
                $inside = !$inside;
            }
        }

        return $inside;
    }

    /**
     * Daftar spot untuk admin (termasuk INACTIVE), mendukung filter status,
     * pencarian nama/kode, dan paginasi (AFS-01, Bagian 8.4).
     */
    public function paginateAdminSpots(array $filters = [], int $perPage = 15): LengthAwarePaginator
    {
        $perPage = max(1, min(100, $perPage));

        $query = FeedingSpot::query()
            ->with(['latestAggregate', 'cats:id,unique_code,name,presence_status,health_status'])
            ->withCount('cats')
            ->orderBy('code');

        if (!empty($filters['status'])) {
            $status = strtoupper(trim((string) $filters['status']));
            if (in_array($status, self::ALLOWED_STATUSES, true)) {
                $query->where('status', $status);
            }
        }

        if (!empty($filters['territory_id'])) {
            $query->where('territory_id', trim((string) $filters['territory_id']));
        }

        $search = trim((string) ($filters['search'] ?? $filters['q'] ?? ''));
        if ($search !== '') {
            $needle = '%' . mb_strtolower($search) . '%';
            $query->where(function ($q) use ($needle) {
                $q->whereRaw('LOWER(name) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(code) LIKE ?', [$needle])
                    ->orWhereRaw('LOWER(COALESCE(description, \'\')) LIKE ?', [$needle]);
            });
        }

        $paginator = $query->paginate($perPage);
        $spots = collect($paginator->items());

        if ($spots->isNotEmpty()) {
            $spotIds = $spots->pluck('id');

            $latestVerifiedMap = FeedingActivity::query()
                ->whereIn('spot_id', $spotIds)
                ->where('status', 'VERIFIED')
                ->selectRaw('spot_id, MAX(COALESCE(finalized_at, updated_at)) as last_fed_at')
                ->groupBy('spot_id')
                ->pluck('last_fed_at', 'spot_id');

            $pendingSpotIds = FeedingActivity::query()
                ->whereIn('spot_id', $spotIds)
                ->where('status', 'UNDER_REVIEW')
                ->pluck('spot_id')
                ->unique()
                ->flip();

            $territoryIds = $spots->pluck('territory_id')->filter()->unique()->values();
            $territoryMap = $territoryIds->isNotEmpty()
                ? DB::table('territories')
                    ->whereIn('id', $territoryIds)
                    ->select(['id', 'code', 'name'])
                    ->get()
                    ->keyBy('id')
                : collect();

            $paginator->setCollection(
                $spots->map(function (FeedingSpot $spot) use ($latestVerifiedMap, $pendingSpotIds, $territoryMap) {
                    $territoryRow = $spot->territory_id ? ($territoryMap[$spot->territory_id] ?? null) : null;
                    $hasPending = isset($pendingSpotIds[$spot->id]) || (($spot->latestAggregate?->pending_count ?? 0) > 0);

                    return $this->formatAdminSpot(
                        $spot,
                        $latestVerifiedMap[$spot->id] ?? null,
                        $territoryRow ? (array) $territoryRow : null,
                        $hasPending
                    );
                })
            );
        }

        return $paginator;
    }

    /**
     * Detail lengkap spot untuk admin, termasuk status_reason, token QR aktif,
     * kucing terkait, riwayat aktivitas, dan log audit perubahan (AFS-01, Bagian 8.4).
     */
    public function getAdminSpotDetail(FeedingSpot $spot): array
    {
        $spot->loadMissing(['latestAggregate']);
        $spot->loadCount('cats');

        $latestVerified = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->where('status', 'VERIFIED')
            ->selectRaw('MAX(COALESCE(finalized_at, updated_at)) as last_fed_at')
            ->value('last_fed_at');

        $hasPending = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->where('status', 'UNDER_REVIEW')
            ->exists() || (($spot->latestAggregate?->pending_count ?? 0) > 0);

        $detail = $this->formatAdminSpot(
            $spot,
            $latestVerified ? (string) $latestVerified : null,
            $spot->territory_data,
            $hasPending
        );

        $detail['cats'] = $spot->cats()
            ->select(['cats.id', 'cats.unique_code', 'cats.name', 'cats.presence_status', 'cats.health_status'])
            ->get()
            ->map(fn ($c) => [
                'id' => $c->id,
                'unique_code' => $c->unique_code,
                'name' => $c->name,
                'presence_status' => $c->presence_status,
                'health_status' => $c->health_status,
            ])
            ->values()
            ->all();

        $detail['activities_count'] = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->count();

        $detail['recent_activities'] = FeedingActivity::query()
            ->where('spot_id', $spot->id)
            ->with(['user:id,name', 'cat:id,unique_code,name'])
            ->orderByDesc('created_at')
            ->limit(10)
            ->get()
            ->map(fn (FeedingActivity $a) => [
                'id' => $a->id,
                'feeding_record_ref' => $a->feeding_record_ref,
                'status' => $a->status,
                'reward_status' => $a->reward_status,
                'food_type' => $a->food_type,
                'food_amount' => $a->food_amount,
                'feeder_name' => $a->user?->name ?? 'Relawan Kampus',
                'cat_name' => $a->cat?->name,
                'scanned_at' => $a->scanned_at?->toIso8601String(),
                'finalized_at' => $a->finalized_at?->toIso8601String(),
            ])
            ->values()
            ->all();

        $detail['audit_logs'] = $this->getSpotAuditLogs($spot->id, 15);
        $detail['histories'] = Schema::hasTable('feeding_spot_histories')
            ? FeedingSpotHistory::query()
                ->where('spot_id', $spot->id)
                ->with('actor:id,name')
                ->orderByDesc('created_at')
                ->limit(20)
                ->get()
                ->map(fn (FeedingSpotHistory $h) => [
                    'id' => $h->id,
                    'spot_id' => $h->spot_id,
                    'actor_id' => $h->actor_id,
                    'actor_name' => $h->actor?->name ?? 'Sistem / Admin',
                    'action' => $h->action,
                    'changes' => $h->changes,
                    'reason' => $h->reason,
                    'created_at' => $h->created_at?->toIso8601String(),
                ])
                ->values()
                ->all()
            : [];

        return $detail;
    }

    /**
     * Buat titik feeding spot baru, hasilkan kode spot unik otomatis bila tidak ditentukan,
     * serta catat di feeding_spot_histories & audit_logs dalam transaksi yang sama (MEOW-29).
     */
    public function createSpot(array $data, ?User $actor = null): FeedingSpot
    {
        $attempts = 0;
        $rawInputCode = isset($data['code']) ? strtoupper(trim((string) $data['code'])) : '';
        $forceAutoCode = !empty($data['auto_code']) || $rawInputCode === '';

        while (true) {
            $attempts++;
            try {
                return DB::transaction(function () use ($data, $actor, $rawInputCode, $forceAutoCode) {
                    $lat = (float) $data['latitude'];
                    $lng = (float) $data['longitude'];

                    $code = $forceAutoCode
                        ? $this->generateUniqueSpotCode($lat, $lng)
                        : $rawInputCode;

                    $status = strtoupper(trim((string) ($data['status'] ?? 'ACTIVE')));
                    $statusReason = isset($data['status_reason']) && trim((string) $data['status_reason']) !== ''
                        ? trim((string) $data['status_reason'])
                        : null;

                    $territoryId = !empty($data['territory_id']) ? (string) $data['territory_id'] : null;
                    if ($territoryId === null) {
                        $campusLoc = self::resolveCampusLocation($lat, $lng, $code);
                        $tCode = $campusLoc['territory_code'] ?? null;
                        if ($tCode) {
                            $territoryId = DB::table('territories')->where('code', $tCode)->value('id');
                        }
                    }

                    $photoMediaId = !empty($data['photo_media_id']) ? (string) $data['photo_media_id'] : null;
                    $photoPath = !empty($data['photo_path']) ? (string) $data['photo_path'] : null;

                    if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
                        $storedPhoto = $this->storeSpotPhoto($data['photo'], $actor);
                        $photoMediaId = $storedPhoto['media_id'];
                        $photoPath = $storedPhoto['path'];
                    } elseif ($photoMediaId && !$photoPath && Schema::hasTable('media_files')) {
                        $photoPath = DB::table('media_files')->where('id', $photoMediaId)->value('path');
                    }

                    $spot = FeedingSpot::create([
                        'code' => $code,
                        'name' => trim((string) $data['name']),
                        'description' => isset($data['description']) && trim((string) $data['description']) !== ''
                            ? trim((string) $data['description'])
                            : null,
                        'latitude' => $lat,
                        'longitude' => $lng,
                        'territory_id' => $territoryId,
                        'qr_token' => Str::random(32),
                        'status' => $status,
                        'status_reason' => $status === 'ACTIVE' ? null : $statusReason,
                        'photo_media_id' => $photoMediaId,
                        'photo_path' => $photoPath,
                    ]);

                    if (Schema::hasTable('feeding_spot_qr_tokens')) {
                        DB::table('feeding_spot_qr_tokens')->insert([
                            'id' => (string) Str::ulid(),
                            'spot_id' => $spot->id,
                            'token' => $spot->qr_token,
                            'status' => 'ACTIVE',
                            'issued_by' => $actor?->id,
                            'issued_at' => now(),
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }

                    $snapshot = $this->extractSnapshot($spot);

                    $this->recordSpotHistory(
                        spotId: $spot->id,
                        actor: $actor,
                        action: 'CREATED',
                        oldValues: null,
                        newValues: $snapshot,
                        reason: $spot->status_reason
                    );

                    $this->recordAuditLog(
                        actor: $actor,
                        action: 'SPOT_CREATED',
                        spotId: $spot->id,
                        oldValues: null,
                        newValues: $snapshot
                    );

                    return $spot;
                });
            } catch (UniqueConstraintViolationException $e) {
                if (!$forceAutoCode || $attempts >= 3) {
                    throw $e;
                }
            }
        }
    }

    /**
     * Perbarui lokasi, informasi, atau status spot (termasuk nonaktifkan ke INACTIVE tanpa hapus)
     * serta catat perubahan (aktor, waktu, nilai lama dan baru) di feeding_spot_histories & audit_logs.
     * Kode spot dipertahankan tetap sama ketika spot diedit.
     */
    public function updateSpot(FeedingSpot $spot, array $data, ?User $actor = null): FeedingSpot
    {
        return DB::transaction(function () use ($spot, $data, $actor) {
            $oldValues = $this->extractSnapshot($spot);

            $updates = [];

            if (array_key_exists('name', $data)) {
                $updates['name'] = trim((string) $data['name']);
            }
            if (array_key_exists('description', $data)) {
                $updates['description'] = $data['description'] !== null && trim((string) $data['description']) !== ''
                    ? trim((string) $data['description'])
                    : null;
            }
            if (array_key_exists('latitude', $data)) {
                $updates['latitude'] = (float) $data['latitude'];
            }
            if (array_key_exists('longitude', $data)) {
                $updates['longitude'] = (float) $data['longitude'];
            }
            if (array_key_exists('territory_id', $data)) {
                $updates['territory_id'] = !empty($data['territory_id']) ? (string) $data['territory_id'] : null;
            }
            if (array_key_exists('status', $data)) {
                $updates['status'] = strtoupper(trim((string) $data['status']));
            }

            if (array_key_exists('status_reason', $data)) {
                $updates['status_reason'] = $data['status_reason'] !== null && trim((string) $data['status_reason']) !== ''
                    ? trim((string) $data['status_reason'])
                    : null;
            } elseif (($updates['status'] ?? null) === 'ACTIVE') {
                $updates['status_reason'] = null;
            }

            if (!empty($data['remove_photo'])) {
                $this->deleteSpotPhoto($spot->photo_media_id, $spot->photo_path);
                $updates['photo_media_id'] = null;
                $updates['photo_path'] = null;
            }

            if (isset($data['photo']) && $data['photo'] instanceof UploadedFile) {
                $this->deleteSpotPhoto($spot->photo_media_id, $spot->photo_path);
                $storedPhoto = $this->storeSpotPhoto($data['photo'], $actor);
                $updates['photo_media_id'] = $storedPhoto['media_id'];
                $updates['photo_path'] = $storedPhoto['path'];
            } elseif (array_key_exists('photo_media_id', $data) && empty($data['remove_photo'])) {
                $newMediaId = !empty($data['photo_media_id']) ? (string) $data['photo_media_id'] : null;
                if ($newMediaId !== $spot->photo_media_id) {
                    $this->deleteSpotPhoto($spot->photo_media_id, $spot->photo_path);
                    $updates['photo_media_id'] = $newMediaId;
                    $updates['photo_path'] = $newMediaId && Schema::hasTable('media_files')
                        ? DB::table('media_files')->where('id', $newMediaId)->value('path')
                        : null;
                }
            }

            $spot->update($updates);
            $spot->refresh();

            $newValues = $this->extractSnapshot($spot);

            $statusChanged = $oldValues['status'] !== $newValues['status'];
            $locationChanged = (float) $oldValues['latitude'] !== (float) $newValues['latitude']
                || (float) $oldValues['longitude'] !== (float) $newValues['longitude'];

            $auditAction = match (true) {
                $statusChanged && $locationChanged => 'SPOT_LOCATION_AND_STATUS_CHANGED',
                $statusChanged => 'SPOT_STATUS_CHANGED',
                $locationChanged => 'SPOT_LOCATION_CHANGED',
                default => 'SPOT_UPDATED',
            };

            $historyAction = match (true) {
                $statusChanged && $newValues['status'] === 'INACTIVE' => 'DEACTIVATED',
                $statusChanged && $oldValues['status'] === 'INACTIVE' && $newValues['status'] === 'ACTIVE' => 'REACTIVATED',
                $statusChanged && $newValues['status'] === 'TEMPORARILY_UNAVAILABLE' => 'MARKED_UNAVAILABLE',
                default => 'UPDATED',
            };

            $this->recordSpotHistory(
                spotId: $spot->id,
                actor: $actor,
                action: $historyAction,
                oldValues: $oldValues,
                newValues: $newValues,
                reason: $newValues['status_reason'] ?? null
            );

            $this->recordAuditLog(
                actor: $actor,
                action: $auditAction,
                spotId: $spot->id,
                oldValues: $oldValues,
                newValues: $newValues
            );

            return $spot;
        });
    }

    /**
     * Regenerasi token QR spot dan catat di feeding_spot_histories & audit_logs.
     */
    public function regenerateQr(FeedingSpot $spot, ?User $actor = null): FeedingSpot
    {
        return DB::transaction(function () use ($spot, $actor) {
            $oldToken = $spot->qr_token;
            $newToken = Str::random(32);
            while ($newToken === $oldToken || FeedingSpot::query()->where('qr_token', $newToken)->exists()) {
                $newToken = Str::random(32);
            }

            if (Schema::hasTable('feeding_spot_qr_tokens')) {
                $existingOld = DB::table('feeding_spot_qr_tokens')
                    ->where('token', $oldToken)
                    ->first();

                if ($existingOld) {
                    DB::table('feeding_spot_qr_tokens')
                        ->where('id', $existingOld->id)
                        ->update([
                            'status' => 'REVOKED',
                            'revoked_at' => now(),
                            'revoked_reason' => 'Dicabut melalui aksi Ganti QR oleh admin.',
                            'updated_at' => now(),
                        ]);
                } else {
                    DB::table('feeding_spot_qr_tokens')->insert([
                        'id' => (string) Str::ulid(),
                        'spot_id' => $spot->id,
                        'token' => $oldToken,
                        'status' => 'REVOKED',
                        'issued_by' => $actor?->id,
                        'issued_at' => $spot->created_at ?? now(),
                        'revoked_at' => now(),
                        'revoked_reason' => 'Dicabut melalui aksi Ganti QR oleh admin.',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                DB::table('feeding_spot_qr_tokens')->insert([
                    'id' => (string) Str::ulid(),
                    'spot_id' => $spot->id,
                    'token' => $newToken,
                    'status' => 'ACTIVE',
                    'issued_by' => $actor?->id,
                    'issued_at' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            $spot->update(['qr_token' => $newToken]);
            $spot->refresh();

            // MEOW-29: Token QR tidak disimpan di kolom changes pada feeding_spot_histories; cukup tercatat bahwa QR diganti.
            if (Schema::hasTable('feeding_spot_histories')) {
                FeedingSpotHistory::create([
                    'spot_id' => $spot->id,
                    'actor_id' => $actor?->id,
                    'action' => 'QR_REGENERATED',
                    'changes' => [
                        'qr_regenerated' => true,
                        'changed_fields' => ['qr_token'],
                    ],
                    'reason' => 'Token QR digenerate ulang oleh admin.',
                ]);
            }

            $this->recordAuditLog(
                actor: $actor,
                action: 'SPOT_QR_REGENERATED',
                spotId: $spot->id,
                oldValues: ['qr_token' => $oldToken],
                newValues: ['qr_token' => $newToken]
            );

            return $spot;
        });
    }

    /**
     * Periksa apakah sebuah token QR spot merupakan token lama yang sudah dicabut (QR_REVOKED).
     */
    public function isRevokedSpotQrToken(string $token): bool
    {
        $clean = trim($token);
        if (str_starts_with($clean, 'MTP1.S.')) {
            $clean = substr($clean, 7);
        } elseif (str_starts_with($clean, 'SPOT:')) {
            $clean = substr($clean, 5);
        }

        if ($clean === '') {
            return false;
        }

        if (Schema::hasTable('feeding_spot_qr_tokens')) {
            $revoked = DB::table('feeding_spot_qr_tokens')
                ->where('token', $clean)
                ->where('status', 'REVOKED')
                ->exists();
            if ($revoked) {
                return true;
            }
        }

        if (Schema::hasTable('audit_logs')) {
            $logs = DB::table('audit_logs')
                ->where('subject_type', 'feeding_spot')
                ->where('action', 'SPOT_QR_REGENERATED')
                ->pluck('reason');

            foreach ($logs as $reasonJson) {
                $decoded = is_string($reasonJson) ? json_decode($reasonJson, true) : null;
                if (is_array($decoded) && (($decoded['old']['qr_token'] ?? null) === $clean)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Format representasi spot untuk endpoint Admin (menyertakan status_reason & qr_token aktif).
     */
    public function formatAdminSpot(
        FeedingSpot $spot,
        ?string $fallbackLastFedAt = null,
        ?array $territory = null,
        bool $hasPendingReview = false
    ): array {
        $agg = $spot->latestAggregate;
        $lastFedIso = $fallbackLastFedAt ? Carbon::parse($fallbackLastFedAt)->toIso8601String() : null;
        $verifiedCount = (int) ($agg?->verified_count ?? 0);
        $needScore = round(max(0.0, min(100.0, (1.0 - min(1.0, $verifiedCount / 28.0)) * 100.0)), 1);

        $campusLoc = self::resolveCampusLocation(
            (float) $spot->latitude,
            (float) $spot->longitude,
            $spot->code,
            $spot->name
        );

        return [
            'id' => $spot->id,
            'code' => $spot->code,
            'name' => $spot->name,
            'location_number' => $campusLoc['number'],
            'location_name' => $campusLoc['name'],
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'territory' => $territory,
            'status' => $spot->status,
            'status_reason' => $spot->status_reason,
            'photo_media_id' => $spot->photo_media_id,
            'photo_url' => $spot->image_url,
            'image_url' => $spot->image_url,
            'qr_token' => $spot->qr_token,
            'qr_payload' => "MTP1.S.{$spot->qr_token}",
            'cats_count' => (int) ($spot->cats_count ?? ($spot->relationLoaded('cats') ? $spot->cats->count() : 0)),
            'cats' => $spot->relationLoaded('cats')
                ? $spot->cats->map(fn ($c) => [
                    'id' => $c->id,
                    'unique_code' => $c->unique_code,
                    'name' => $c->name,
                    'presence_status' => $c->presence_status,
                    'health_status' => $c->health_status,
                ])->values()->all()
                : [],
            'last_fed_at' => $lastFedIso,
            'has_pending_review' => $hasPendingReview,
            'aggregate' => [
                'window_days' => 14,
                'total_feedings' => $verifiedCount,
                'verified_count' => $verifiedCount,
                'pending_count' => (int) ($agg?->pending_count ?? 0),
                'need_score' => $needScore,
                'last_fed_at' => $lastFedIso,
                'computed_at' => $agg?->computed_at ? Carbon::parse($agg->computed_at)->toIso8601String() : null,
                'is_stale' => $agg ? Carbon::parse($agg->computed_at)->lt(now()->subHours(1)) : true,
            ],
            'created_at' => $spot->created_at?->toIso8601String(),
            'updated_at' => $spot->updated_at?->toIso8601String(),
        ];
    }

    /**
     * Ambil daftar audit_logs terbaru untuk spot tertentu atau seluruh modul FeedingSpot
     * (mencakup perubahan lokasi/status spot dan keputusan review pemberian pakan).
     */
    public function getSpotAuditLogs(?string $spotId = null, int $limit = 30): array
    {
        $query = DB::table('audit_logs')
            ->leftJoin('users', 'audit_logs.actor_id', '=', 'users.id')
            ->select([
                'audit_logs.id',
                'audit_logs.actor_id',
                'users.name as actor_name',
                'audit_logs.action',
                'audit_logs.subject_type',
                'audit_logs.subject_id',
                'audit_logs.result',
                'audit_logs.reason',
                'audit_logs.created_at',
            ])
            ->orderByDesc('audit_logs.created_at')
            ->limit($limit);

        if ($spotId !== null) {
            $query->where('audit_logs.subject_type', 'feeding_spot')
                ->where('audit_logs.subject_id', $spotId);
        } else {
            $query->whereIn('audit_logs.subject_type', ['feeding_spot', 'feeding_activity']);
        }

        return $query->get()->map(function ($row) {
            $decoded = is_string($row->reason) ? json_decode($row->reason, true) : null;

            return [
                'id' => $row->id,
                'actor_id' => $row->actor_id,
                'actor_name' => $row->actor_name ?? 'Sistem / Admin',
                'action' => $row->action,
                'subject_type' => $row->subject_type,
                'subject_id' => $row->subject_id,
                'result' => $row->result,
                'changes' => is_array($decoded) ? $decoded : ['raw' => $row->reason],
                'created_at' => $row->created_at,
            ];
        })->all();
    }

    private function extractSnapshot(FeedingSpot $spot): array
    {
        return [
            'code' => $spot->code,
            'name' => $spot->name,
            'description' => $spot->description,
            'latitude' => (float) $spot->latitude,
            'longitude' => (float) $spot->longitude,
            'territory_id' => $spot->territory_id,
            'status' => $spot->status,
            'status_reason' => $spot->status_reason,
            'photo_media_id' => $spot->photo_media_id,
            'photo_path' => $spot->photo_path,
        ];
    }

    private function recordSpotHistory(
        string $spotId,
        ?User $actor,
        string $action,
        ?array $oldValues,
        array $newValues,
        ?string $reason = null
    ): void {
        if (!Schema::hasTable('feeding_spot_histories')) {
            return;
        }

        $changedFields = [];
        $oldDiff = [];
        $newDiff = [];

        if ($oldValues !== null) {
            foreach ($newValues as $key => $val) {
                if (($oldValues[$key] ?? null) !== $val) {
                    $changedFields[] = $key;
                    $oldDiff[$key] = $oldValues[$key] ?? null;
                    $newDiff[$key] = $val;
                }
            }
        } else {
            $changedFields = array_keys($newValues);
            $oldDiff = null;
            $newDiff = $newValues;
        }

        FeedingSpotHistory::create([
            'spot_id' => $spotId,
            'actor_id' => $actor?->id,
            'action' => $action,
            'changes' => [
                'old' => $oldDiff,
                'new' => $newDiff,
                'changed_fields' => $changedFields,
            ],
            'reason' => $reason,
        ]);
    }

    private function recordAuditLog(
        ?User $actor,
        string $action,
        string $spotId,
        ?array $oldValues,
        array $newValues
    ): void {
        $changedFields = [];
        if ($oldValues !== null) {
            foreach ($newValues as $key => $val) {
                if (($oldValues[$key] ?? null) !== $val) {
                    $changedFields[] = $key;
                }
            }
        } else {
            $changedFields = array_keys($newValues);
        }

        DB::table('audit_logs')->insert([
            'id' => (string) Str::ulid(),
            'actor_id' => $actor?->id,
            'action' => $action,
            'subject_type' => 'feeding_spot',
            'subject_id' => $spotId,
            'result' => 'SUCCESS',
            'reason' => json_encode([
                'old' => $oldValues,
                'new' => $newValues,
                'changed_fields' => $changedFields,
            ], JSON_UNESCAPED_UNICODE),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}

