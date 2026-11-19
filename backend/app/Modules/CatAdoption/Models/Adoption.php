<?php

namespace App\Modules\CatAdoption\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Transaksi adopsi (PRD 5.3). Hanya transaksi pengambilan yang berhasil membuat ACTIVE.
 * Hanya verifikasi admin yang menutup (CLOSED_RETURNED).
 */
class Adoption extends Model
{
    use HasUlids;

    public const STATUS_ACTIVE = 'ACTIVE';
    public const STATUS_RETURN_REQUESTED = 'RETURN_REQUESTED';
    public const STATUS_RETURN_APPROVED = 'RETURN_APPROVED';
    public const STATUS_RETURN_EVIDENCE_PENDING = 'RETURN_EVIDENCE_PENDING';
    public const STATUS_CLOSED_RETURNED = 'CLOSED_RETURNED';

    public const STATUSES = [
        self::STATUS_ACTIVE,
        self::STATUS_RETURN_REQUESTED,
        self::STATUS_RETURN_APPROVED,
        self::STATUS_RETURN_EVIDENCE_PENDING,
        self::STATUS_CLOSED_RETURNED,
    ];

    public const REHOME_COOLDOWN_DAYS = 30;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_ACTIVE,
    ];

    protected $fillable = [
        'application_id',
        'cat_id',
        'adopter_id',
        'status',
        'picked_up_at',
        'pickup_media_id',
        'pickup_location',
        'trial_ends_at',
        'closed_at',
        'rehome_cooldown_until',
    ];

    protected $casts = [
        'picked_up_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'closed_at' => 'datetime',
        'rehome_cooldown_until' => 'datetime',
    ];

    public function application(): BelongsTo
    {
        return $this->belongsTo(AdoptionApplication::class, 'application_id');
    }

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function adopter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'adopter_id');
    }

    public function followups(): HasMany
    {
        return $this->hasMany(AdoptionFollowup::class, 'adoption_id')->orderBy('period_no');
    }

    public function returns(): HasMany
    {
        return $this->hasMany(AdoptionReturn::class, 'adoption_id');
    }

    public function issues(): HasMany
    {
        return $this->hasMany(AdoptionIssue::class, 'adoption_id');
    }

    /** Adopsi yang belum ditutup (kuota masih terikat, ADP-12). */
    public function scopeOpen(Builder $query): Builder
    {
        return $query->where('status', '<>', self::STATUS_CLOSED_RETURNED);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE);
    }
}
