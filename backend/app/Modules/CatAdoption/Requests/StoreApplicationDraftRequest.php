<?php

namespace App\Modules\CatAdoption\Requests;

use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

/**
 * Draf kelayakan (ADP-02). Semua field boleh kosong; kucing tidak dipilih di sini (FIX-06).
 */
class StoreApplicationDraftRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cat_id' => ['prohibited'],
            'housing_type' => ['nullable', 'string', 'max:50'],
            'owner_permission' => ['nullable', 'boolean'],
            'can_afford' => ['nullable', 'boolean'],
            'long_term_plan' => ['nullable', 'string', 'max:2000'],
            'answers' => ['nullable', 'array'],
        ];
    }

    public function messages(): array
    {
        return [
            'cat_id.prohibited' => 'Kucing tidak dipilih saat pengajuan kelayakan, melainkan saat pengambilan.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            ApiResponse::error('Data yang dikirim tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors())
        );
    }
}
