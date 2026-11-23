<?php

namespace App\Modules\Cat\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CatQrToken extends Model
{
    use HasFactory, HasUlids;

    public const STATUS_ACTIVE = 'ACTIVE';
    public const STATUS_REVOKED = 'REVOKED';

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_ACTIVE,
    ];

    protected $fillable = [
        'cat_id',
        'token',
        'status', // ACTIVE, REVOKED
        'issued_by',
        'issued_at',
        'revoked_at',
        'revoked_reason',
    ];

    protected $casts = [
        'issued_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function issuer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'issued_by');
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACTIVE);
    }

    public function scopeRevoked(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_REVOKED);
    }
}
