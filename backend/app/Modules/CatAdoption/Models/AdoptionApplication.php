<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class AdoptionApplication extends Model
{
    use HasFactory, HasUlids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'applicant_id',
        'cat_id',
        'housing_type',
        'owner_permission',
        'can_afford',
        'long_term_plan',
        'answers',
        'commitment_version',
        'commitment_accepted_at',
        'precheck_passed',
        'status',             // DRAFT, SUBMITTED, REVISION_REQUESTED, APPROVED, REJECTED
        'submitted_at',
        'reviewed_by',
        'reviewed_at',
        'review_note',
    ];

    protected $casts = [
        'owner_permission' => 'boolean',
        'can_afford' => 'boolean',
        'precheck_passed' => 'boolean',
        'answers' => 'array',
        'commitment_accepted_at' => 'datetime',
        'submitted_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public function applicant()
    {
        return $this->belongsTo(User::class, 'applicant_id');
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class);
    }
}
