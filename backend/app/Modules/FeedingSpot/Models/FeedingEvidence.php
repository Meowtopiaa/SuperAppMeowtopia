<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedingEvidence extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'feeding_evidence';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'activity_id',
        'media_id',
        'captured_at',
        'sort_order',
    ];

    protected $casts = [
        'captured_at' => 'datetime',
        'sort_order' => 'integer',
    ];

    public function activity()
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }
}

