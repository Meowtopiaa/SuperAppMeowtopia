<?php

namespace App\Modules\CatAdoption\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Laporan kendala adopter (ADP-13). Foto tidak wajib, tidak menutup adopsi.
 */
class AdoptionIssue extends Model
{
    use HasUlids;

    public const STATUS_OPEN = 'OPEN';

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_OPEN,
    ];

    protected $fillable = [
        'adoption_id',
        'type',
        'description',
        'media_id',
        'status',
        'handled_by',
        'incident_report_id',
    ];

    public function adoption(): BelongsTo
    {
        return $this->belongsTo(Adoption::class, 'adoption_id');
    }

    public function handler(): BelongsTo
    {
        return $this->belongsTo(User::class, 'handled_by');
    }
}
