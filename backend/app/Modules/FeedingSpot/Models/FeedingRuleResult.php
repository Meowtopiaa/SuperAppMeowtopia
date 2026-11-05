<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingRuleResult extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_rule_results';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'activity_id',
        'rule',
        'result', // PASS, REVIEW, FAIL
        'detail',
    ];

    public function activity()
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }
}

