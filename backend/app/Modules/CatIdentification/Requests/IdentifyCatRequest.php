<?php

namespace App\Modules\CatIdentification\Requests;

use Illuminate\Foundation\Http\FormRequest;

class IdentifyCatRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'method' => ['required', 'in:qr,photo_ai,questionnaire'],
            'qr_token' => ['nullable', 'string'],
            'photo' => ['nullable', 'string'],
            'answers' => ['nullable', 'array'],
        ];
    }
}
