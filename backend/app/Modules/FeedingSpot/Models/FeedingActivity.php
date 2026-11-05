<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use App\Modules\Core\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FeedingActivity extends Model
{
    use HasUlids;

    protected $table = 'feeding_activities';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'spot_id',
        'cat_id',
        'status',
        'reward_status',
        'points_awarded',
        'food_type',
        'food_amount',
        'notes',
        'scanned_at',
        'intent_confirmed_at',
        'submitted_at',
        'verified_at',
    ];

    protected $casts = [
        'points_awarded' => 'integer',
        'scanned_at' => 'datetime',
        'intent_confirmed_at' => 'datetime',
        'submitted_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function spot(): BelongsTo
    {
        return $this->belongsTo(FeedingSpot::class, 'spot_id');
    }

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function evidence(): HasMany
    {
        return $this->hasMany(FeedingEvidence::class, 'activity_id');
    }

    public function ruleResults(): HasMany
    {
        return $this->hasMany(FeedingRuleResult::class, 'activity_id');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(FeedingReview::class, 'activity_id');
    }
}
