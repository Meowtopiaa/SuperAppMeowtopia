<?php

namespace App\Modules\CatIdentification\Requests;

use App\Modules\CatIdentification\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;

class UpdateCatTraitsRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->updateTraits($user);
    }

    public function rules(): array
    {
        return [
            'traits' => ['required', 'array', 'min:1'],
            'traits.*.question_id' => ['required', 'string', 'size:26', 'exists:identification_questions,id'],
            'traits.*.answer' => ['required', 'in:YES,NO'],
        ];
    }
}
