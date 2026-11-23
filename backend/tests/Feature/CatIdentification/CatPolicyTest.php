<?php

namespace Tests\Feature\CatIdentification;

use App\Models\User;
use App\Modules\CatIdentification\Policies\CatPolicy;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

class CatPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);
    }

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['cat.edit', 'cat.curate', 'cat.qr.regenerate'] as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
        }
    }

    protected function createUserWithPermissions(array $permissions = []): User
    {
        $user = new User([
            'name' => 'User ' . Str::random(4),
            'email' => Str::random(8) . '@telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->user_type = 'MAHASISWA';
        $user->email_verified_at = now();
        $user->save();

        if (!empty($permissions)) {
            $user->givePermissionTo($permissions);
        }

        return $user;
    }

    public function test_cat_policy_enforces_granular_spatie_permissions(): void
    {
        $policy = new CatPolicy();

        $regular = $this->createUserWithPermissions([]);
        $editor = $this->createUserWithPermissions(['cat.edit']);
        $curator = $this->createUserWithPermissions(['cat.curate']);
        $qrManager = $this->createUserWithPermissions(['cat.qr.regenerate']);

        // Regular user denied everywhere on admin/moderation (FIX-03)
        $this->assertFalse($policy->viewAdminPanel($regular));
        $this->assertFalse($policy->create($regular));
        $this->assertFalse($policy->update($regular));
        $this->assertFalse($policy->curate($regular));
        $this->assertFalse($policy->regenerateQr($regular));
        $this->assertFalse($policy->viewQrSheet($regular));
        $this->assertFalse($policy->merge($regular));
        $this->assertFalse($policy->resolveClaim($regular));
        $this->assertFalse($policy->moderateContent($regular));

        // cat.edit only
        $this->assertTrue($policy->viewAdminPanel($editor));
        $this->assertTrue($policy->create($editor));
        $this->assertTrue($policy->update($editor));
        $this->assertTrue($policy->import($editor));
        $this->assertFalse($policy->curate($editor));
        $this->assertFalse($policy->merge($editor));
        $this->assertFalse($policy->regenerateQr($editor));
        $this->assertFalse($policy->moderateContent($editor));

        // cat.curate only
        $this->assertTrue($policy->viewAdminPanel($curator));
        $this->assertTrue($policy->curate($curator));
        $this->assertTrue($policy->merge($curator));
        $this->assertTrue($policy->resolveClaim($curator));
        $this->assertTrue($policy->moderateContent($curator));
        $this->assertTrue($policy->viewQrSheet($curator));
        $this->assertFalse($policy->create($curator));
        $this->assertFalse($policy->regenerateQr($curator));

        // cat.qr.regenerate only
        $this->assertTrue($policy->viewAdminPanel($qrManager));
        $this->assertTrue($policy->regenerateQr($qrManager));
        $this->assertTrue($policy->viewQrSheet($qrManager));
        $this->assertFalse($policy->create($qrManager));
        $this->assertFalse($policy->moderateContent($qrManager));

        // Own content deletion vs moderation
        $this->assertTrue($policy->deleteOwnOrModerate($regular, $regular->id));
        $this->assertFalse($policy->deleteOwnOrModerate($regular, $editor->id));
        $this->assertTrue($policy->deleteOwnOrModerate($curator, $regular->id));
    }
}
