<?php

namespace App\Modules\CatIdentification\Services;

use App\Modules\Cat\Models\Cat;

class CatMatcherService
{
    /**
     * Match cat by questionnaire traits (e.g. pattern, primary_color)
     */
    public function matchByTraits(array $answers): array
    {
        $query = Cat::query();

        if (!empty($answers['primary_color'])) {
            $query->where('primary_color', 'like', '%' . $answers['primary_color'] . '%');
        }

        if (!empty($answers['pattern'])) {
            $query->where('pattern', 'like', '%' . $answers['pattern'] . '%');
        }

        if (!empty($answers['gender'])) {
            $query->where('gender', $answers['gender']);
        }

        $candidates = $query->take(5)->get();

        return [
            'candidates' => $candidates,
            'confidence' => $candidates->isNotEmpty() ? 85.0 : 20.0,
            'top_match' => $candidates->first(),
        ];
    }
}
