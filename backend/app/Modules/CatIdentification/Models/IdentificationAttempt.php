<?php

namespace App\Modules\CatIdentification\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IdentificationAttempt extends Model
{
    use HasFactory, HasUlids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'method',             // PHOTO, AKINATOR
        'model_version',
        'input_media_id',
        'answers',
        'candidates',
        'result',             // MATCHED, INCONCLUSIVE, NOT_CAT
        'confirmed_cat_id',
    ];

    protected $casts = [
        'answers' => 'array',
        'candidates' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function confirmedCat()
    {
        return $this->belongsTo(Cat::class, 'confirmed_cat_id');
    }
}
