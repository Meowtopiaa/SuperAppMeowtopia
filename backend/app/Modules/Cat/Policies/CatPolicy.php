<?php

namespace App\Modules\Cat\Policies;

use App\Models\User;
use App\Modules\Cat\Models\Cat;

/**
 * Permission-based Policy for Cat domain (PRD 3.1, 3.2, FIX-03).
 * Checks Spatie permissions only, never role strings.
 */
class CatPolicy
{
    public function create(User $user): bool
    {
        return $user->can('cat.edit');
    }

    public function update(User $user, ?Cat $cat = null): bool
    {
        return $user->can('cat.edit');
    }

    public function curate(User $user, ?Cat $cat = null): bool
    {
        return $user->can('cat.curate');
    }

    public function regenerateQr(User $user, ?Cat $cat = null): bool
    {
        return $user->can('cat.qr.regenerate');
    }

    public function viewQrSheet(User $user): bool
    {
        return $user->can('cat.qr.regenerate') || $user->can('cat.curate');
    }

    public function import(User $user): bool
    {
        return $user->can('cat.edit') || $user->can('cat.curate');
    }

    public function updateTraits(User $user, ?Cat $cat = null): bool
    {
        return $user->can('cat.curate') || $user->can('cat.edit');
    }

    public function merge(User $user, ?Cat $cat = null): bool
    {
        return $user->can('cat.curate');
    }
}
