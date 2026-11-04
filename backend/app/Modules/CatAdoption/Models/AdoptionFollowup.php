<?php

namespace App\Modules\CatAdoption\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdoptionFollowup extends Model
{
    use HasFactory, HasUlids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'adoption_id',
        'period_no',
        'due_at',
        'submitted_at',
        'condition_note',
        'issue_note',
        'media_id',
        'status',             // PENDING, SUBMITTED, LATE, REVIEWED
    ];

    protected $casts = [
        'due_at' => 'datetime',
        'submitted_at' => 'datetime',
    ];
}
