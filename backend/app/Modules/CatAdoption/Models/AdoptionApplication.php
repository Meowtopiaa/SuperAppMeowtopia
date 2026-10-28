<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class AdoptionApplication extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'cat_id',
        'status',             // submitted, reviewing, approved, rejected, handed_over
        'housing_type',       // kos, rumah_kontrakan, rumah_pribadi
        'financial_readiness',// boolean or text
        'family_permission',  // boolean
        'commitment_answers', // JSON
        'admin_notes',
        'handed_over_at',
    ];

    protected $casts = [
        'financial_readiness' => 'boolean',
        'family_permission' => 'boolean',
        'commitment_answers' => 'array',
        'handed_over_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class);
    }

    public function followups()
    {
        return $this->hasMany(AdoptionFollowup::class);
    }
}
