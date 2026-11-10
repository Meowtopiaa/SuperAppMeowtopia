<?php

namespace App\Modules\CatHunter\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserCatDex extends Model
{
    use HasFactory, HasUlids;

    protected $table = 'user_cat_dex';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'cat_id',
        'state',              // SEEN, TAMED
        'tamed_at',
        'times_encountered',
        'last_greeted_at',
    ];

    protected $casts = [
        'tamed_at' => 'datetime',
        'last_greeted_at' => 'datetime',
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
