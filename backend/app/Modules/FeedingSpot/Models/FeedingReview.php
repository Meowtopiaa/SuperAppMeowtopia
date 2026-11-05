<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeedingReview extends Model
{
    use HasUlids;

    protected $table = 'feeding_reviews';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'activity_id',
        'reviewer_id',
        'decision',
        'reason',
    ];

    public function activity(): BelongsTo
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}
