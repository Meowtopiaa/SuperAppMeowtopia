<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeedingRuleResult extends Model
{
    use HasUlids;

    protected $table = 'feeding_rule_results';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'activity_id',
        'rule_code',
        'passed',
        'detail',
        'evaluated_at',
    ];

    protected $casts = [
        'passed' => 'boolean',
        'evaluated_at' => 'datetime',
    ];

    public function activity(): BelongsTo
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }
}
