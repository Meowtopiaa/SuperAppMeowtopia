<?php

namespace App\Modules\CatAdoption\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Penahanan sementara kucing saat proses pengambilan (ADP-07).
 * Bukan baris adopsi. Default 48 jam.
 */
class AdoptionPickupLock extends Model
{
    use HasUlids;

    public const STATUS_HELD = 'HELD';
    public const STATUS_RELEASED = 'RELEASED';
    public const STATUS_USED = 'USED';

    public const DEFAULT_HOLD_HOURS = 48;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_HELD,
    ];

    protected $fillable = [
        'cat_id',
        'adopter_id',
        'expires_at',
        'status',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function adopter(): BelongsTo
    {
        return $this->belongsTo(User::class, 'adopter_id');
    }

    /** Lock HELD yang belum kedaluwarsa. */
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_HELD)->where('expires_at', '>', now());
    }

    public function isExpired(): bool
    {
        return $this->expires_at !== null && $this->expires_at->isPast();
    }
}
