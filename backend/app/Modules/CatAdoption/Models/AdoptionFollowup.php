<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdoptionFollowup extends Model
{
    use HasFactory;

    protected $fillable = [
        'adoption_application_id',
        'period_number',      // 1, 2, 3 (bi-weekly reports)
        'photo_proof_url',
        'condition_notes',
        'health_condition',   // excellent, good, sick
        'status',             // submitted, reviewed
    ];

    public function application()
    {
        return $this->belongsTo(AdoptionApplication::class, 'adoption_application_id');
    }
}
