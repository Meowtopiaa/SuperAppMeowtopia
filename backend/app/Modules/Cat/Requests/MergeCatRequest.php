<?php

namespace App\Modules\Cat\Requests;

use App\Modules\Cat\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;

class MergeCatRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->merge($user);
    }

    public function rules(): array
    {
        return [
            'duplicate_cat_id' => ['required', 'string', 'size:26', 'exists:cats,id'],
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }
}
