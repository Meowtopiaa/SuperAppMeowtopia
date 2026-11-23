<?php

namespace App\Modules\CatIdentification\Resources;

use App\Modules\CatIdentification\Models\CatPhoto;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Public-safe representation of a Cat (PRD 4.2, CAT-09, FIX-04).
 * Never exposes raw coordinates, QR tokens, or private/internal metadata.
 */
class CatPublicResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $photos = CatPhoto::where('cat_id', $this->id)
            ->orderBy('sort_order')
            ->get()
            ->map(fn ($photo) => [
                'id' => $photo->id,
                'media_id' => $photo->media_id,
                'angle' => $photo->angle,
                'sort_order' => $photo->sort_order,
            ])
            ->values()
            ->all();

        return [
            'id' => $this->id,
            'unique_code' => $this->unique_code,
            'name' => $this->name,
            'gender' => $this->gender,
            'color_pattern' => $this->color_pattern,
            'age_group' => $this->age_group,
            'is_sterilized' => $this->is_sterilized,
            'description' => $this->description,
            'traits' => $this->traits,
            'territory_id' => $this->territory_id,
            'primary_photo_media_id' => $this->primary_photo_media_id,
            'presence_status' => $this->presence_status,
            'health_status' => $this->health_status,
            'adoption_status' => $this->adoption_status,
            'status_badges' => $this->statusBadges(),
            'verification_status' => $this->verification_status,
            'first_seen_at' => $this->first_seen_at?->toIso8601String(),
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
            'photos' => $photos,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
