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
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'student_id' => ['nullable', 'string', 'max:30'],
            'role' => ['nullable', 'in:student,adopter,volunteer,admin'],
            'phone' => ['nullable', 'string', 'max:20'],
        ];
    }
}
