<?php

namespace App\Modules\CatHunter\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class CatEncounter extends Model
{
    use HasFactory, HasUlids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'cat_id',
        'mood',               // CALM, PLAYFUL, SHY, AGGRESSIVE
        'trust',
        'turn_count',
        'status',             // ACTIVE, TAMED, FAILED, ESCAPED, EXPIRED
        'started_at',
        'ended_at',
        'location_lat',
        'location_lng',
        'points_awarded',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
        'location_lat' => 'double',
        'location_lng' => 'double',
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
