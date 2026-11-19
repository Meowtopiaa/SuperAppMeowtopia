<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatStatusLog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * EN-11 (ADP-05): POST /api/v1/admin/adoption/cats/{cat_id}/set-ready
 */
class AdminSetReadyApiTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->givePermissionTo(Permission::findOrCreate('adoption.set_ready', 'web'));

        return $admin;
    }

    private function cat(array $attributes = []): Cat
    {
        $cat = Cat::create(['unique_code' => 'TST-' . Str::upper(Str::random(6)), 'name' => 'Oyen']);
        $cat->forceFill($attributes)->save();

        return $cat->fresh();
    }

    private function setReady(string $catId, array $payload = ['reason' => 'Sudah steril dan jinak.'])
    {
        return $this->postJson("/api/v1/admin/adoption/cats/{$catId}/set-ready", $payload);
    }

    public function test_admin_sets_cat_ready_with_reason_and_history(): void
    {
        $admin = $this->admin();
        $cat = $this->cat();
        Sanctum::actingAs($admin);

        $this->setReady($cat->id)
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $cat->id)
            ->assertJsonPath('data.adoption_status', 'READY');

        $this->assertSame('READY', $cat->fresh()->adoption_status);
        $log = CatStatusLog::where('cat_id', $cat->id)->sole();
        $this->assertSame(['UNREVIEWED', 'READY', 'Sudah steril dan jinak.', $admin->id, 'CatAdoption'],
            [$log->from_value, $log->to_value, $log->reason, $log->actor_id, $log->source_module]);
    }

    public function test_returned_cat_can_be_set_ready(): void
    {
        Sanctum::actingAs($this->admin());
        $cat = $this->cat(['adoption_status' => 'RETURNED_REVIEW']);

        $this->setReady($cat->id)->assertOk()->assertJsonPath('data.adoption_status', 'READY');
    }

    public function test_reason_is_required(): void
    {
        Sanctum::actingAs($this->admin());
        $cat = $this->cat();

        $this->setReady($cat->id, [])
            ->assertStatus(422)
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonValidationErrors(['reason']);

        $this->assertSame('UNREVIEWED', $cat->fresh()->adoption_status);
    }

    public function test_user_without_permission_is_forbidden(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $cat = $this->cat();

        $this->setReady($cat->id)->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');
        $this->assertSame('UNREVIEWED', $cat->fresh()->adoption_status);
    }

    public function test_requires_login(): void
    {
        $this->setReady($this->cat()->id)->assertUnauthorized();
    }

    public function test_unknown_cat_returns_not_found(): void
    {
        Sanctum::actingAs($this->admin());

        $this->setReady((string) Str::ulid())->assertNotFound()->assertJsonPath('code', 'NOT_FOUND');
    }

    public function test_adopted_cat_cannot_be_set_ready(): void
    {
        Sanctum::actingAs($this->admin());
        $cat = $this->cat(['adoption_status' => 'ADOPTED']);

        $this->setReady($cat->id)->assertStatus(409)->assertJsonPath('code', 'CONFLICT');
        $this->assertSame(0, CatStatusLog::count());
    }

    public function test_cat_not_on_campus_cannot_be_set_ready(): void
    {
        Sanctum::actingAs($this->admin());
        $cat = $this->cat(['presence_status' => 'MISSING']);

        $this->setReady($cat->id)->assertStatus(409)->assertJsonPath('code', 'CAT_NOT_AVAILABLE');
        $this->assertSame('UNREVIEWED', $cat->fresh()->adoption_status);
    }
}
