<?php

namespace App\Modules\IncidentReport\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReportIncidentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cat_id' => ['nullable', 'exists:cats,id'],
            'title' => ['required', 'string', 'max:150'],
            'incident_type' => ['required', 'in:injured,severely_ill,trapped,abuse,missing,other'],
            'urgency_level' => ['required', 'in:low,medium,high,critical'],
            'description' => ['required', 'string'],
            'photo_url' => ['nullable', 'string'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'location_note' => ['nullable', 'string', 'max:255'],
        ];
    }
}
