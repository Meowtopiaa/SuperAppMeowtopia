<?php

namespace App\Modules\CatIdentification\Models;

use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CatPhoto extends Model
{
    use HasFactory, HasUlids;

    public const ANGLES = ['front', 'left', 'right', 'tail', 'face', 'candid'];

    protected $table = 'cat_photos';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'sort_order' => 0,
    ];

    protected $fillable = [
        'cat_id',
        'media_id',
        'angle',
        'sort_order',
    ];

    protected $casts = [
        'sort_order' => 'integer',
    ];

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function scopeOrdered(Builder $query): Builder
    {
        return $query->orderBy('sort_order')->orderBy('created_at');
    }
}
