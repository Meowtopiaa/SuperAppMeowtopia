<?php

namespace App\Modules\CatAdoption\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Pengajuan pengembalian (ADP-11, ADP-12).
 */
class AdoptionReturn extends Model
{
    use HasUlids;

    public const TYPE_REGULAR = 'REGULAR';
    public const TYPE_EMERGENCY = 'EMERGENCY';

    public const STATUS_PENDING = 'PENDING';
    public const STATUS_APPROVED = 'APPROVED';
    public const STATUS_REJECTED = 'REJECTED';
    public const STATUS_VERIFIED = 'VERIFIED';

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'type' => self::TYPE_REGULAR,
        'status' => self::STATUS_PENDING,
    ];

    protected $fillable = [
        'adoption_id',
        'type',
        'reason',
        'status',
        'proof_media_id',
        'return_location',
        'verified_by',
        'verified_at',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
    ];

    public function adoption(): BelongsTo
    {
        return $this->belongsTo(Adoption::class, 'adoption_id');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
