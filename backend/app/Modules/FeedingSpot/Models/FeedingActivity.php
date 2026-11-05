<?php

namespace App\Modules\FeedingSpot\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class FeedingActivity extends Model
{
    use HasUlids;

    protected $table = 'feeding_activities';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'feeding_record_ref',
        'user_id',
        'spot_id',
        'location_lat',
        'location_lng',
        'status',
        'scanned_at',
        'intent_at',
        'intent_deadline_at',
        'finalize_deadline_at',
        'finalized_at',
        'food_type',
        'food_amount',
        'cat_id',
        'reward_status',
        'potential_points',
        'reward_snapshot',
        'flags',
    ];

    protected $casts = [
        'location_lat' => 'float',
        'location_lng' => 'float',
        'potential_points' => 'integer',
        'reward_snapshot' => 'array',
        'flags' => 'array',
        'scanned_at' => 'datetime',
        'intent_at' => 'datetime',
        'intent_deadline_at' => 'datetime',
        'finalize_deadline_at' => 'datetime',
        'finalized_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::creating(function (FeedingActivity $activity) {
            if (empty($activity->feeding_record_ref)) {
                $activity->feeding_record_ref = 'AFS-' . strtoupper(Str::ulid()->toBase32());
            }
            if (($activity->location_lat === null || $activity->location_lng === null) && $activity->spot_id) {
                $spot = FeedingSpot::find($activity->spot_id);
                $activity->location_lat = $spot ? $spot->latitude : -6.9740000;
                $activity->location_lng = $spot ? $spot->longitude : 107.6300000;
            }
        });
    }

    public function getNotesAttribute(): ?string
    {
        return $this->reward_snapshot['notes'] ?? null;
    }

    public function getPointsAwardedAttribute(): int
    {
        return (int) ($this->reward_snapshot['points_awarded'] ?? ($this->reward_status === 'CREDITED' ? $this->potential_points : 0));
    }

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
        return $this->hasMany(FeedingEvidence::class, 'activity_id')->orderBy('sort_order');
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
