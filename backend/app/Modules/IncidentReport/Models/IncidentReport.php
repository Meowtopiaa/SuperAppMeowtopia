<?php

namespace App\Modules\IncidentReport\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;
use App\Modules\Cat\Models\Cat;

class IncidentReport extends Model
{
    use HasFactory;

    protected $fillable = [
        'reporter_id',
        'cat_id',
        'title',
        'incident_type',      // injured, severely_ill, trapped, abuse, missing
        'urgency_level',      // low, medium, high, critical
        'description',
        'photo_url',
        'latitude',
        'longitude',
        'location_note',
        'status',             // reported, dispatched, handling, resolved, rejected
        'resolver_notes',
    ];

    protected $casts = [
        'latitude' => 'double',
        'longitude' => 'double',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }
}
