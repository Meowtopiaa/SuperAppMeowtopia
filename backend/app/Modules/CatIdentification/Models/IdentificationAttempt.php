<?php

namespace App\Modules\CatIdentification\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class IdentificationAttempt extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'matched_cat_id',
        'photo_path',
        'answers',          // JSON answers to questions
        'confidence_score', // 0 - 100
        'method',           // qr, photo_ai, questionnaire
        'status',           // confirmed, rejected, inconclusive
    ];

    protected $casts = [
        'answers' => 'array',
        'confidence_score' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function matchedCat()
    {
        return $this->belongsTo(Cat::class, 'matched_cat_id');
    }
}
