<?php

namespace App\Modules\Cat\Requests;

use App\Modules\Cat\Policies\CatPolicy;
use Illuminate\Foundation\Http\FormRequest;

class ImportCatsRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && app(CatPolicy::class)->import($user);
    }

    public function rules(): array
    {
        return [
            'file' => ['required', 'file', 'mimes:csv,txt', 'max:5120'],
        ];
    }
}
