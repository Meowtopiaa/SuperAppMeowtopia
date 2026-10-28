<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingSpot extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'code',             // e.g. FS-FIT-01
        'qr_token',
        'location_name',
        'latitude',
        'longitude',
        'status',           // active, maintenance, inactive
        'bowl_condition',   // empty, partially_filled, full, needs_cleaning
        'last_fed_at',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
        'last_fed_at' => 'datetime',
    ];

    public function activities()
    {
        return $this->hasMany(FeedingActivity::class);
    }
}
