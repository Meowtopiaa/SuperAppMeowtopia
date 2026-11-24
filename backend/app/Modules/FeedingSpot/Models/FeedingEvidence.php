<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\URL;

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

    protected $appends = [
        'signed_url',
        'media_url',
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

    /**
     * URL bertanda tangan sementara (berlaku 10 menit) untuk foto bukti pakan (CORE-05, MEOW-22).
     */
    public function getSignedUrlAttribute(): string
    {
        if (Route::has('admin.feeding.evidence.file')) {
            return URL::temporarySignedRoute(
                'admin.feeding.evidence.file',
                now()->addMinutes(10),
                ['mediaId' => $this->media_id]
            );
        }

        return url("/api/v1/admin/feeding/evidence/{$this->media_id}/file");
    }

    public function getMediaUrlAttribute(): string
    {
        return $this->signed_url;
    }
}
