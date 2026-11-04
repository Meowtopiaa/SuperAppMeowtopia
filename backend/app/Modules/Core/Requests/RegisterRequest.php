<?php

namespace App\Modules\Core\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $allowedDomains = explode(',', env('ALLOWED_EMAIL_DOMAINS', 'student.telkomuniversity.ac.id,telkomuniversity.ac.id'));

        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                'unique:users,email',
                function ($attribute, $value, $fail) use ($allowedDomains) {
                    $parts = explode('@', $value);
                    $domain = end($parts);
                    if (!empty($allowedDomains) && !in_array($domain, $allowedDomains, true)) {
                        $fail("Domain email tidak diizinkan. Gunakan email kampus resmi.");
                    }
                },
            ],
            'password' => ['required', 'string', 'min:8'],
            'identity_number' => ['nullable', 'string', 'max:30'],
            'phone' => ['nullable', 'string', 'max:20'],
        ];
    }
}
