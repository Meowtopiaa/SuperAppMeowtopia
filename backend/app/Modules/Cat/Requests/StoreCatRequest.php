<?php

namespace App\Modules\Cat\Requests;

use App\Modules\Cat\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;

class StoreCatRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->create($user);
    }

    public function rules(): array
    {
        return [
            'unique_code' => ['nullable', 'string', 'max:32', 'regex:/^[A-Z0-9\-_]+$/', 'unique:cats,unique_code'],
            'name' => ['required', 'string', 'max:100'],
            'gender' => ['nullable', 'in:MALE,FEMALE,UNKNOWN'],
            'color_pattern' => ['nullable', 'string', 'max:100'],
            'age_group' => ['nullable', 'in:KITTEN,ADULT,SENIOR,UNKNOWN'],
            'is_sterilized' => ['nullable', 'boolean'],
            'description' => ['nullable', 'string', 'max:2000'],
            'traits' => ['nullable', 'array'],
            'territory_id' => ['nullable', 'string', 'size:26', 'exists:territories,id'],
            'primary_photo_media_id' => ['nullable', 'string', 'size:26', 'exists:media_files,id'],
            'verification_status' => ['nullable', 'in:UNVERIFIED,VERIFIED'],
            'photos' => ['nullable', 'array', 'max:10'],
            'photos.*.media_id' => ['required_with:photos', 'string', 'size:26', 'exists:media_files,id'],
            'photos.*.angle' => ['nullable', 'string', 'max:30'],
            'photos.*.sort_order' => ['nullable', 'integer', 'min:0'],

            // Status dimensions are governed by CatStatusService and module ownership (PRD 5.1, FIX-03, FIX-05)
            'presence_status' => ['prohibited'],
            'health_status' => ['prohibited'],
            'adoption_status' => ['prohibited'],
        ];
    }
}
