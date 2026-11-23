<?php

namespace App\Modules\Cat\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Cat extends Model
{
    use HasFactory, HasUlids, SoftDeletes;

    protected $keyType = 'string';
    public $incrementing = false;

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
        'health_status',        // HEALTHY, SICK, INJURED, UNDER_CARE
        'adoption_status',      // UNREVIEWED, READY, ADOPTED, RETURN_PENDING, RETURNED_REVIEW
        'verification_status',  // UNVERIFIED, VERIFIED
        'first_seen_at',
        'last_seen_at',
    ];

    protected $casts = [
        'is_sterilized' => 'boolean',
        'traits' => 'array',
        'first_seen_at' => 'datetime',
        'last_seen_at' => 'datetime',
    ];

    public function qrTokens(): HasMany
    {
        return $this->hasMany(CatQrToken::class, 'cat_id');
    }

    public function activeQrToken(): HasOne
    {
        return $this->hasOne(CatQrToken::class, 'cat_id')->where('status', 'ACTIVE');
    }

    public function statusLogs(): HasMany
    {
        return $this->hasMany(CatStatusLog::class, 'cat_id');
    }
}
