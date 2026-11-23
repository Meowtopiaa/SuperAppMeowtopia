<?php

namespace App\Modules\CatIdentification\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CatSighting extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'cat_sightings';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'cat_id',
        'user_id',
        'source',
        'request_id',
        'location_lat',
        'location_lng',
        'accuracy_m',
        'token_id',
        'occurred_at',
        'metadata',
    ];

    protected $casts = [
        'location_lat' => 'float',
        'location_lng' => 'float',
        'accuracy_m' => 'float',
        'occurred_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
