<?php

namespace App\Modules\CatHunter\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class CatEncounter extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'cat_id',
        'latitude',
        'longitude',
        'reported_condition', // sehat, tidur, luka_ringan, lapar
        'turns_count',
        'encounter_result',   // captured, fled, timed_out
        'affinity_points',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class);
    }
}
