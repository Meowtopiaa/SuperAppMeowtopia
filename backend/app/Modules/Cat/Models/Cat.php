<?php

namespace App\Modules\Cat\Models;

use App\Modules\CatIdentification\Models\CatPhoto;
use App\Modules\CatIdentification\Models\CatSighting;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cat extends Model
{
    use HasFactory, HasUlids, SoftDeletes;

    public const PRESENCE_ON_CAMPUS = 'ON_CAMPUS';
    public const PRESENCE_ADOPTED = 'ADOPTED';
    public const PRESENCE_MISSING = 'MISSING';
    public const PRESENCE_DECEASED = 'DECEASED';

    public const HEALTH_HEALTHY = 'HEALTHY';
    public const HEALTH_SICK = 'SICK';
    public const HEALTH_INJURED = 'INJURED';
    public const HEALTH_UNDER_CARE = 'UNDER_CARE';

    public const ADOPTION_UNREVIEWED = 'UNREVIEWED';
    public const ADOPTION_READY = 'READY';
    public const ADOPTION_ADOPTED = 'ADOPTED';
    public const ADOPTION_RETURN_PENDING = 'RETURN_PENDING';
    public const ADOPTION_RETURNED_REVIEW = 'RETURNED_REVIEW';

    public const PRESENCE_STATUSES = [
        self::PRESENCE_ON_CAMPUS,
        self::PRESENCE_ADOPTED,
        self::PRESENCE_MISSING,
        self::PRESENCE_DECEASED,
    ];

    public const HEALTH_STATUSES = [
        self::HEALTH_HEALTHY,
        self::HEALTH_SICK,
        self::HEALTH_INJURED,
        self::HEALTH_UNDER_CARE,
    ];

    public const ADOPTION_STATUSES = [
        self::ADOPTION_UNREVIEWED,
        self::ADOPTION_READY,
        self::ADOPTION_ADOPTED,
        self::ADOPTION_RETURN_PENDING,
        self::ADOPTION_RETURNED_REVIEW,
    ];

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'gender' => 'UNKNOWN',
        'age_group' => 'UNKNOWN',
        'presence_status' => self::PRESENCE_ON_CAMPUS,
        'health_status' => self::HEALTH_HEALTHY,
        'adoption_status' => self::ADOPTION_UNREVIEWED,
        'verification_status' => 'VERIFIED',
    ];

    protected $fillable = [
        'unique_code',
        'name',
        'gender',             // MALE, FEMALE, UNKNOWN
        'color_pattern',
        'age_group',          // KITTEN, ADULT, SENIOR, UNKNOWN
        'is_sterilized',
        'description',
        'traits',
        'territory_id',
        'primary_photo_media_id',
        'presence_status',    // ON_CAMPUS, ADOPTED, MISSING, DECEASED
        'health_status',      // HEALTHY, SICK, INJURED, UNDER_CARE
        'adoption_status',    // UNREVIEWED, READY, ADOPTED, RETURN_PENDING, RETURNED_REVIEW
        'verification_status', // UNVERIFIED, VERIFIED
        'first_seen_at',
        'last_seen_at',
    ];

    protected $casts = [
        'is_sterilized' => 'boolean',
        'traits' => 'array',
        'first_seen_at' => 'datetime',
        'last_seen_at' => 'datetime',
    ];

    public function photos(): HasMany
    {
        return $this->hasMany(CatPhoto::class, 'cat_id')->orderBy('sort_order');
    }

    public function sightings(): HasMany
    {
        return $this->hasMany(CatSighting::class, 'cat_id')->orderByDesc('occurred_at');
    }

    public function qrTokens(): HasMany
    {
        return $this->hasMany(CatQrToken::class, 'cat_id')->orderByDesc('issued_at');
    }

    public function activeQrToken(): HasOne
    {
        return $this->hasOne(CatQrToken::class, 'cat_id')->where('status', CatQrToken::STATUS_ACTIVE);
    }

    public function statusLogs(): HasMany
    {
        return $this->hasMany(CatStatusLog::class, 'cat_id')->orderByDesc('created_at');
    }

    public function scopeOnCampus(Builder $query): Builder
    {
        return $query->where('presence_status', self::PRESENCE_ON_CAMPUS);
    }

    public function scopeReadyForAdoption(Builder $query): Builder
    {
        return $query->where('presence_status', self::PRESENCE_ON_CAMPUS)
            ->where('adoption_status', self::ADOPTION_READY);
    }

    public function scopeVerified(Builder $query): Builder
    {
        return $query->where('verification_status', 'VERIFIED');
    }

    /**
     * Structured badge metadata for Beranda, Profil Forum, and Admin View (PRD 0 & 5.1).
     */
    public function statusBadges(): array
    {
        $presenceLabels = [
            self::PRESENCE_ON_CAMPUS => 'Di Kampus',
            self::PRESENCE_ADOPTED => 'Teradopsi',
            self::PRESENCE_MISSING => 'Hilang',
            self::PRESENCE_DECEASED => 'Meninggal',
        ];

        $healthLabels = [
            self::HEALTH_HEALTHY => 'Sehat',
            self::HEALTH_SICK => 'Sakit',
            self::HEALTH_INJURED => 'Terluka',
            self::HEALTH_UNDER_CARE => 'Dalam Perawatan',
        ];

        $adoptionLabels = [
            self::ADOPTION_UNREVIEWED => 'Belum Siap Adopsi',
            self::ADOPTION_READY => 'Siap Diadopsi',
            self::ADOPTION_ADOPTED => 'Sudah Diadopsi',
            self::ADOPTION_RETURN_PENDING => 'Proses Pengembalian',
            self::ADOPTION_RETURNED_REVIEW => 'Evaluasi Pasca Kembali',
        ];

        return [
            'presence' => [
                'code' => $this->presence_status,
                'label' => $presenceLabels[$this->presence_status] ?? $this->presence_status,
            ],
            'health' => [
                'code' => $this->health_status,
                'label' => $healthLabels[$this->health_status] ?? $this->health_status,
            ],
            'adoption' => [
                'code' => $this->adoption_status,
                'label' => $adoptionLabels[$this->adoption_status] ?? $this->adoption_status,
            ],
        ];
    }
}
