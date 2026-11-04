<?php

namespace App\Modules\IncidentReport\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IncidentReport extends Model
{
    use HasFactory, HasUlids;

    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'ticket_code',
        'reporter_id',
        'cat_id',
        'category',           // SICK, INJURED, MISSING, FOUND, AGGRESSIVE, DECEASED, NEW_CAT, DAMAGED_QR, OTHER
        'urgency',            // LOW, MEDIUM, HIGH
        'description',
        'location_lat',
        'location_lng',
        'location_note',
        'territory_id',
        'source',             // DIRECT, GAME, PROFILE, ADOPTION
        'source_ref',
        'status',             // RECEIVED, WAITING_ASSIGNMENT, ASSIGNED, IN_PROGRESS, RESOLVED, CLOSED, REJECTED, DUPLICATE
        'assigned_to',
        'assigned_at',
        'resolved_at',
        'closed_at',
        'resolution_note',
        'notification_status',
    ];

    protected $casts = [
        'location_lat' => 'double',
        'location_lng' => 'double',
        'assigned_at' => 'datetime',
        'resolved_at' => 'datetime',
        'closed_at' => 'datetime',
    ];

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function cat()
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function assignee()
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }
}
