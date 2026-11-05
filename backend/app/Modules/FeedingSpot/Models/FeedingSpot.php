<?php

namespace App\Modules\FeedingSpot\Models;

use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Support\Facades\DB;

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

    public function getTerritoryDataAttribute(): ?array
    {
        if (!$this->territory_id) {
            return null;
        }

        $row = DB::table('territories')
            ->select(['id', 'code', 'name'])
            ->where('id', $this->territory_id)
            ->first();

        return $row ? (array) $row : null;
    }

    public function cats(): BelongsToMany
    {
        return $this->belongsToMany(Cat::class, 'feeding_spot_cats', 'spot_id', 'cat_id')
            ->withTimestamps();
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
        return $query->whereIn('status', ['ACTIVE', 'MAINTENANCE', 'TEMPORARILY_UNAVAILABLE']);
    }
}
