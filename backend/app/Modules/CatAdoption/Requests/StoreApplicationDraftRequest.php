<?php

namespace App\Modules\CatAdoption\Requests;

use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Support\ApiResponse;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Validation\Rule;

/**
 * Draf kelayakan (ADP-02), dipakai POST dan PUT. Semua field boleh kosong; kucing tidak dipilih di sini (FIX-06).
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
            // Foto tempat tinggal harus diunggah sendiri lewat POST /media.
            'housing_media_id' => ['nullable', 'string', Rule::exists('media_files', 'id')
                ->where('owner_id', $this->user()->id)
                ->where('purpose', 'adoption_evidence')
                ->whereNull('deleted_at')],
            'commitment_accepted' => ['nullable', 'boolean'],
            'commitment_version' => ['required_if_accepted:commitment_accepted', 'nullable', 'string', Rule::in([AdoptionApplication::COMMITMENT_VERSION])],
        ];
    }

    public function messages(): array
    {
        return [
            'cat_id.prohibited' => 'Kucing tidak dipilih saat pengajuan kelayakan, melainkan saat pengambilan.',
            'housing_media_id.exists' => 'Foto tempat tinggal tidak ditemukan atau bukan milikmu.',
            'commitment_version.in' => 'Versi komitmen sudah tidak berlaku. Baca dan setujui komitmen terbaru.',
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(
            ApiResponse::error('Data yang dikirim tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors())
        );
    }
}
