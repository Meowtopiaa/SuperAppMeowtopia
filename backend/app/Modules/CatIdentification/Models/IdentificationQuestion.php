<?php

namespace App\Modules\CatIdentification\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IdentificationQuestion extends Model
{
    use HasFactory;

    protected $fillable = [
        'question_text',
        'trait_category', // color, ear_shape, tail_shape, pattern
        'options',        // JSON array of selectable options
        'order',
        'is_active',
    ];

    protected $casts = [
        'options' => 'array',
        'is_active' => 'boolean',
    ];
}
