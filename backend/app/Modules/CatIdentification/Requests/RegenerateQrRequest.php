<?php

namespace App\Modules\CatIdentification\Requests;

use App\Modules\CatIdentification\Policies\CatPolicy;
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
