<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingActivity extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_activities';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'feeding_record_ref',
        'user_id',
        'spot_id',
        'location_lat',
        'location_lng',
        'status',           // DRAFT, SUBMITTED, UNDER_REVIEW, VERIFIED, REJECTED, EXPIRED
        'scanned_at',
        'intent_at',
        'intent_deadline_at',
        'finalize_deadline_at',
        'finalized_at',
        'food_type',
        'food_amount',
        'cat_id',
        'reward_status',    // NOT_ELIGIBLE, PENDING, CREDITED, FAILED, REVERSED
        'potential_points',
        'reward_snapshot',
        'flags',
    ];

    protected $casts = [
        'scanned_at' => 'datetime',
        'intent_at' => 'datetime',
        'intent_deadline_at' => 'datetime',
        'finalize_deadline_at' => 'datetime',
        'finalized_at' => 'datetime',
        'reward_snapshot' => 'array',
        'flags' => 'array',
        'location_lat' => 'double',
        'location_lng' => 'double',
        'potential_points' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function spot()
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function evidence()
    {
        return $this->hasMany(FeedingEvidence::class, 'activity_id')->orderBy('sort_order');
    }

    public function ruleResults()
    {
        return $this->hasMany(FeedingRuleResult::class, 'activity_id');
    }

    public function reviews()
    {
        return $this->hasMany(FeedingReview::class, 'activity_id')->latest();
    }
}
