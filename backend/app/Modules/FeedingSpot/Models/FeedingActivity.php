<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class FeedingActivity extends Model
{
    use HasFactory;

    protected $fillable = [
        'feeding_spot_id',
        'user_id',
        'photo_proof_url',
        'food_type',          // dry_food, wet_food, water
        'notes',
        'status',             // pending_verification, verified, rejected
        'points_awarded',
    ];

    public function feedingSpot()
    {
        return $this->belongsTo(FeedingSpot::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
