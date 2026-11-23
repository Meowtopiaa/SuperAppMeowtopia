<?php

namespace App\Modules\CatIdentification\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordSightingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'source' => ['nullable', 'in:manual_sighting,encounter,feeding,adoption_pickup,adoption_return'],
            'location_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'location_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'accuracy_m' => ['nullable', 'numeric', 'min:0', 'max:10000'],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
