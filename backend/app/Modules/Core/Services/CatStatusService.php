<?php

namespace App\Modules\Core\Services;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Core\Events\CatStatusChanged;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;
use InvalidArgumentException;

class CatStatusService
{
    /**
     * Allowed status transitions per dimension
     */
    protected array $allowedTransitions = [
        'presence_status' => [
            'ON_CAMPUS' => ['ADOPTED', 'MISSING', 'DECEASED'],
            'MISSING' => ['ON_CAMPUS', 'DECEASED'],
            'ADOPTED' => ['ON_CAMPUS'], // upon verified return
            'DECEASED' => [],
        ],
        'health_status' => [
            'HEALTHY' => ['SICK', 'INJURED', 'UNDER_CARE'],
            'SICK' => ['HEALTHY', 'UNDER_CARE', 'INJURED'],
            'INJURED' => ['HEALTHY', 'UNDER_CARE', 'SICK'],
            'UNDER_CARE' => ['HEALTHY', 'SICK', 'INJURED'],
        ],
        'adoption_status' => [
            'UNREVIEWED' => ['READY'],
            'READY' => ['ADOPTED'],
            'ADOPTED' => ['RETURN_PENDING'],
            'RETURN_PENDING' => ['RETURNED_REVIEW', 'ADOPTED'],
            'RETURNED_REVIEW' => ['READY'],
        ],
    ];

    /**
     * Module ownership per dimension
     */
    protected array $dimensionOwnership = [
        'presence_status' => ['Core', 'Cat'],
        'health_status' => ['IncidentReport', 'Core'],
        'adoption_status' => ['CatAdoption', 'Core'],
    ];

    /**
     * The single official door to update a cat's status dimension.
     */
    public function change(
        Cat $cat,
        string $dimension,
        string $newValue,
        ?User $actor,
        string $sourceModule,
        ?string $reason = null,
        ?string $refType = null,
        ?string $refId = null
    ): Cat {
        if (!array_key_exists($dimension, $this->allowedTransitions)) {
            throw new InvalidArgumentException("Invalid status dimension '{$dimension}'.");
        }

        $currentValue = $cat->{$dimension};

        // If same value, no-op
        if ($currentValue === $newValue) {
            return $cat;
        }

        // Verify transition rule
        $validNextStates = $this->allowedTransitions[$dimension][$currentValue] ?? [];
        if (!in_array($newValue, $validNextStates, true)) {
            throw new ConflictHttpException(
                "Invalid status transition for {$dimension} from {$currentValue} to {$newValue}."
            );
        }

        return DB::transaction(function () use ($cat, $dimension, $currentValue, $newValue, $actor, $sourceModule, $reason, $refType, $refId) {
            // 1. Record in cat_status_logs
            DB::table('cat_status_logs')->insert([
                'id' => (string) Str::ulid(),
                'cat_id' => $cat->id,
                'dimension' => $dimension,
                'from_value' => $currentValue,
                'to_value' => $newValue,
                'reason' => $reason,
                'actor_id' => $actor?->id,
                'source_module' => $sourceModule,
                'ref_type' => $refType,
                'ref_id' => $refId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 2. Update Cat model
            $cat->{$dimension} = $newValue;
            $cat->save();

            // 3. Dispatch event
            CatStatusChanged::dispatch(
                $cat,
                $dimension,
                $currentValue,
                $newValue,
                $actor?->id,
                $reason
            );

            return $cat;
        });
    }
}

