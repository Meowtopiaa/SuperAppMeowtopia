<?php

namespace App\Modules\FeedingSpot\Models;

use App\Modules\Core\Models\MediaFile;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FeedingEvidence extends Model
{
    use HasUlids;

    protected $table = 'feeding_evidence';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'activity_id',
        'media_id',
        'created_at',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function activity(): BelongsTo
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }

    public function media(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'media_id');
    }
}
