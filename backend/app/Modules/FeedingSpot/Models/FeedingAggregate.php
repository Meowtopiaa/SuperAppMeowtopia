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

    public function spot(): BelongsTo
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }
}
