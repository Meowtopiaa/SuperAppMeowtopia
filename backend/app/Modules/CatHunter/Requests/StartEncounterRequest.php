<?php

namespace App\Modules\CatHunter\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StartEncounterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cat_qr_token' => ['required', 'string'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'condition' => ['required', 'string'],
        ];
    }
}
