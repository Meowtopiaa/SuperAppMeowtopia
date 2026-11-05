<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\DB;

class FeedingEvidence extends Model
{
    use HasUlids;

    protected $table = 'feeding_evidence';
    public $incrementing = false;
    protected $keyType = 'string';

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

    public function activity(): BelongsTo
    {
        return $this->belongsTo(FeedingActivity::class, 'activity_id');
    }

    public function getMediaDataAttribute(): ?array
    {
        $row = DB::table('media_files')
            ->where('id', $this->media_id)
            ->first();

        return $row ? (array) $row : null;
    }
}
