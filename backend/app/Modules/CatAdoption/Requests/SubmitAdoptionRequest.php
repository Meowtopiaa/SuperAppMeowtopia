<?php

namespace App\Modules\CatAdoption\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SubmitAdoptionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cat_id' => ['required', 'exists:cats,id'],
            'housing_type' => ['required', 'string'],
            'financial_readiness' => ['required', 'boolean'],
            'family_permission' => ['required', 'boolean'],
            'commitment_answers' => ['nullable', 'array'],
        ];
    }
}
