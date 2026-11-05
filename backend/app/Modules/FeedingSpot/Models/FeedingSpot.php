<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingSpot extends Model
{
    use HasFactory, HasUlids;

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
}
