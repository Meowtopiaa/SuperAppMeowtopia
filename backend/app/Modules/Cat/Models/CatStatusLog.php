<?php

namespace App\Modules\Cat\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CatStatusLog extends Model
{
    use HasFactory, HasUlids;

    public const DIMENSION_PRESENCE = 'presence_status';
    public const DIMENSION_HEALTH = 'health_status';
    public const DIMENSION_ADOPTION = 'adoption_status';

    public const DIMENSIONS = [
        self::DIMENSION_PRESENCE,
        self::DIMENSION_HEALTH,
        self::DIMENSION_ADOPTION,
    ];

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'cat_id',
        'dimension',
        'from_value',
        'to_value',
        'reason',
        'actor_id',
        'source_module',
        'ref_type',
        'ref_id',
    ];

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }

    public function scopeForDimension(Builder $query, string $dimension): Builder
    {
        return $query->where('dimension', $dimension);
    }

    public function scopeLatestFirst(Builder $query): Builder
    {
        return $query->orderByDesc('created_at');
    }
}
