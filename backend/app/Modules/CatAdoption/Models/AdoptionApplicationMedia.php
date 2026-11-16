<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Tautan media privat (foto tempat tinggal) ke aplikasi kelayakan.
 */
class AdoptionApplicationMedia extends Model
{
    use HasUlids;

    protected $table = 'adoption_application_media';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'application_id',
        'media_id',
    ];

    public function application(): BelongsTo
    {
        return $this->belongsTo(AdoptionApplication::class, 'application_id');
    }
}
