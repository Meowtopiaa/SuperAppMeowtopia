<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeedingAggregate extends Model
{
    use HasUlids;

    protected $table = 'feeding_aggregates';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'spot_id',
        'window_start',
        'window_end',
        'total_feedings',
        'unique_feeders',
        'last_fed_at',
        'need_score',
        'computed_at',
    ];

    protected $casts = [
        'window_start' => 'date',
        'window_end' => 'date',
        'total_feedings' => 'integer',
        'unique_feeders' => 'integer',
        'last_fed_at' => 'datetime',
        'need_score' => 'float',
        'computed_at' => 'datetime',
    ];

    public function spot(): BelongsTo
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }
}
