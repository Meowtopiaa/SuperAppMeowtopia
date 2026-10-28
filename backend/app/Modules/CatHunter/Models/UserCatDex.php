<?php

namespace App\Modules\CatHunter\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class UserCatDex extends Model
{
    use HasFactory;

    protected $table = 'user_cat_dex';

    protected $fillable = [
        'user_id',
        'cat_id',
        'encounters_count',
        'first_captured_at',
        'last_interacted_at',
        'friendship_level',
    ];

    protected $casts = [
        'first_captured_at' => 'datetime',
        'last_interacted_at' => 'datetime',
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
