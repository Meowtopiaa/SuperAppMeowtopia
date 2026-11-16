<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Follow-up berkala tiap 14 hari (ADP-09, ADP-10). Unik per (adoption_id, period_no).
 */
class AdoptionFollowup extends Model
{
    use HasFactory, HasUlids;

    public const STATUS_PENDING = 'PENDING';
    public const STATUS_SUBMITTED = 'SUBMITTED';
    public const STATUS_LATE = 'LATE';
    public const STATUS_REVIEWED = 'REVIEWED';

    public const INTERVAL_DAYS = 14;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_PENDING,
    ];

    protected $fillable = [
        'adoption_id',
        'period_no',
        'due_at',
        'submitted_at',
        'condition_note',
        'issue_note',
        'media_id',
        'status',
    ];

    protected $casts = [
        'period_no' => 'integer',
        'due_at' => 'datetime',
        'submitted_at' => 'datetime',
    ];

    public function adoption(): BelongsTo
    {
        return $this->belongsTo(Adoption::class, 'adoption_id');
    }
}
