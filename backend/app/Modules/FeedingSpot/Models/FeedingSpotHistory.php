<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeedingSpotHistory extends Model
{
    use HasUlids;

    protected $table = 'feeding_spot_histories';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'spot_id',
        'actor_id',
        'action',
        'changes',
        'reason',
    ];

    protected $casts = [
        'changes' => 'array',
    ];

    public function spot(): BelongsTo
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }

    public function actor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'actor_id');
    }
}
