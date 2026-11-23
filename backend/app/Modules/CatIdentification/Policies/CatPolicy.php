<?php

namespace App\Modules\CatIdentification\Policies;

use App\Models\User;
use App\Modules\Cat\Models\Cat;

/**
 * Permission-based Policy for Cat & CatIdentification domain (PRD 3.1, 3.2, FIX-03).
 * Checks Spatie permissions only, never role strings.
 * Protects Panel Kontrol Admin Satwa and community content moderation.
 */
class CatPolicy
{
    public function viewAdminPanel(User $user): bool
    {
        return $user->can('cat.edit')
            || $user->can('cat.curate')
            || $user->can('cat.qr.regenerate');
    }

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

    public function resolveClaim(User $user): bool
    {
        return $user->can('cat.curate');
    }

    public function moderateContent(User $user): bool
    {
        return $user->can('cat.curate');
    }

    public function deleteOwnOrModerate(User $user, string $ownerId): bool
    {
        return $user->id === $ownerId || $user->can('cat.curate');
    }
}
