<?php

namespace App\Modules\FeedingSpot\Models;

use App\Modules\Core\Models\Territory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class FeedingSpot extends Model
{
    use HasUlids;

    protected $table = 'feeding_spots';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'code',
        'name',
        'description',
        'latitude',
        'longitude',
        'territory_id',
        'qr_token',
        'status',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function territory(): BelongsTo
    {
        return $this->belongsTo(Territory::class, 'territory_id');
    }

    public function activities(): HasMany
    {
        return $this->hasMany(FeedingActivity::class, 'spot_id');
    }

    public function aggregates(): HasMany
    {
        return $this->hasMany(FeedingAggregate::class, 'spot_id');
    }

    public function latestAggregate(): HasOne
    {
        return $this->hasOne(FeedingAggregate::class, 'spot_id')->latestOfMany('computed_at');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereIn('status', ['ACTIVE', 'MAINTENANCE']);
    }
}
