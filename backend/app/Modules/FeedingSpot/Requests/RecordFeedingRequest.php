<?php

namespace App\Modules\FeedingSpot\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecordFeedingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'feeding_spot_id' => ['required', 'exists:feeding_spots,id'],
            'qr_token' => ['required', 'string'],
            'food_type' => ['required', 'in:dry_food,wet_food,water'],
            'photo_proof_url' => ['nullable', 'string'],
            'notes' => ['nullable', 'string', 'max:500'],
        ];
    }
}
