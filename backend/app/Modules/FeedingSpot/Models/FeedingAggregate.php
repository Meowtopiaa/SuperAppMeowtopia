<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingAggregate extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_aggregates';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'spot_id',
        'window_start',
        'window_end',
        'verified_count',
        'pending_count',
        'computed_at',
    ];

    protected $casts = [
        'window_start' => 'datetime',
        'window_end' => 'datetime',
        'verified_count' => 'integer',
        'pending_count' => 'integer',
        'computed_at' => 'datetime',
    ];

    public function spot()
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }
}

