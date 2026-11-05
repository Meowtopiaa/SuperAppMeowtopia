<?php

namespace App\Modules\FeedingSpot\Models;

use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingSpot extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_spots';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'name',
        'code',             // e.g. SPOT-TULT-01
        'description',
        'latitude',
        'longitude',
        'territory_id',
        'qr_token',
        'status',           // ACTIVE, TEMPORARILY_UNAVAILABLE, INACTIVE
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
    ];

    public function activities()
    {
        return $this->hasMany(FeedingActivity::class, 'spot_id');
    }

    public function verifiedActivities()
    {
        return $this->hasMany(FeedingActivity::class, 'spot_id')
            ->where('status', 'VERIFIED');
    }

    public function latestVerifiedActivity()
    {
        return $this->hasOne(FeedingActivity::class, 'spot_id')
            ->where('status', 'VERIFIED')
            ->latestOfMany('finalized_at');
    }

    public function aggregates()
    {
        return $this->hasMany(FeedingAggregate::class, 'spot_id');
    }

    public function latestAggregate()
    {
        return $this->hasOne(FeedingAggregate::class, 'spot_id')
            ->latestOfMany('computed_at');
    }

    public function cats()
    {
        return $this->belongsToMany(Cat::class, 'feeding_spot_cats', 'spot_id', 'cat_id')
            ->withTimestamps();
    }
}
