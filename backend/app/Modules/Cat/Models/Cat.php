<?php

namespace App\Modules\Cat\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Cat extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'qr_code_token',
        'gender',             // male, female
        'breed',
        'primary_color',
        'pattern',            // solid, tabby, calico, tuxedo, etc.
        'sterilization_status',
        'health_status',      // healthy, under_treatment, critical
        'adoption_status',    // available, pending, adopted, not_for_adoption
        'description',
        'primary_photo_url',
        'gallery_photos',
        'last_seen_lat',
        'last_seen_lng',
        'last_seen_location_name',
    ];

    protected $casts = [
        'sterilization_status' => 'boolean',
        'gallery_photos' => 'array',
        'last_seen_lat' => 'double',
        'last_seen_lng' => 'double',
    ];
}
