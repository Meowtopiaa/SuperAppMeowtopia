<?php

namespace App\Modules\CatIdentification\Requests;

use App\Modules\CatIdentification\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCatRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->update($user);
    }

    public function rules(): array
    {
        $catId = $this->route('id');

        return [
            'unique_code' => [
                'sometimes',
                'string',
                'max:32',
                'regex:/^[A-Z0-9\-_]+$/',
                Rule::unique('cats', 'unique_code')->ignore($catId),
            ],
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'gender' => ['sometimes', 'in:MALE,FEMALE,UNKNOWN'],
            'color_pattern' => ['nullable', 'string', 'max:100'],
            'age_group' => ['sometimes', 'in:KITTEN,ADULT,SENIOR,UNKNOWN'],
            'is_sterilized' => ['nullable', 'boolean'],
            'description' => ['nullable', 'string', 'max:2000'],
            'traits' => ['nullable', 'array'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'primary_photo_media_id' => ['nullable', 'string', 'size:26', 'exists:media_files,id'],
            'verification_status' => ['sometimes', 'in:UNVERIFIED,VERIFIED'],

            'presence_status' => ['sometimes', 'in:ON_CAMPUS,MISSING,DECEASED'],
            'status_reason' => ['required_with:presence_status', 'string', 'max:500'],

            'health_status' => ['prohibited'],
            'adoption_status' => ['prohibited'],
        ];
    }
}
