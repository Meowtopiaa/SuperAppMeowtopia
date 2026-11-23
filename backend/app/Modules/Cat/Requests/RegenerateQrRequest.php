<?php

namespace App\Modules\Cat\Requests;

use App\Modules\Cat\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;

class RegenerateQrRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->regenerateQr($user);
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }
}
