<?php

namespace App\Modules\Core\Contracts;

use App\Models\User;
use App\Modules\Cat\Models\Cat;

interface CatActionProviderInterface
{
    /**
     * Provide available module actions for a specific cat and authenticated user.
     * Return array of action specs:
     * [
     *   'id' => 'game.encounter',
     *   'module' => 'CatHunter',
     *   'label' => 'Dekati Kucing',
     *   'enabled' => true,
     *   'reason' => null
     * ]
     */
    public function actionsFor(Cat $cat, ?User $user): array;
}

