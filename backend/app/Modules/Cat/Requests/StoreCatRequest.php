<?php

namespace App\Modules\Cat\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCatRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:100'],
            'gender' => ['required', 'in:male,female'],
            'breed' => ['nullable', 'string', 'max:100'],
            'primary_color' => ['nullable', 'string', 'max:50'],
            'pattern' => ['nullable', 'string', 'max:50'],
            'sterilization_status' => ['boolean'],
            'health_status' => ['nullable', 'in:healthy,under_treatment,critical'],
            'adoption_status' => ['nullable', 'in:available,pending,adopted,not_for_adoption'],
            'description' => ['nullable', 'string'],
            'primary_photo_url' => ['nullable', 'string'],
            'last_seen_lat' => ['nullable', 'numeric'],
            'last_seen_lng' => ['nullable', 'numeric'],
            'last_seen_location_name' => ['nullable', 'string'],
        ];
    }
}
