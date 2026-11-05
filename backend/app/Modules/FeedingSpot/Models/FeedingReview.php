<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingReview extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_reviews';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'activity_id',
        'reviewer_id',
        'decision', // VERIFIED, REJECTED, REVERSED
        'reason',
    ];

    public function activity()
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewer_id');
    }
}

