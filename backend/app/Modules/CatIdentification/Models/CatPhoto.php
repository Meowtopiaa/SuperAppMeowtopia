<?php

namespace App\Modules\CatIdentification\Models;

use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CatPhoto extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'cat_photos';
    protected $keyType = 'string';
    public $incrementing = false;

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
}
