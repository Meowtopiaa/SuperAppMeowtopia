<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Models\AdoptionPickupLock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-17 (ADP-06, ADP-07): POST /api/v1/adoption/pickups/start
 */
class PickupStartApiTest extends TestCase
{
    use RefreshDatabase;

    private function approvedUser(int $approvedDaysAgo = 1): User
    {
        $user = User::factory()->create();
        AdoptionApplication::create([
            'applicant_id' => $user->id,
            'status' => AdoptionApplication::STATUS_APPROVED,
            'reviewed_at' => now()->subDays($approvedDaysAgo),
        ]);

        return $user;
    }

    private function cat(array $attributes = []): Cat
    {
        $cat = Cat::create(['unique_code' => 'TST-' . Str::upper(Str::random(6)), 'name' => 'Oyen']);
        $cat->forceFill($attributes + ['adoption_status' => 'READY'])->save();

        return $cat->fresh();
    }

    private function start(string $code)
    {
        return $this->postJson('/api/v1/adoption/pickups/start', ['cat_code' => $code], ['Idempotency-Key' => (string) Str::uuid()]);
    }

    public function test_approved_student_holds_cat_by_collar_qr(): void
    {
        $user = $this->approvedUser();
        $cat = $this->cat();
        $token = Str::random(32);
        CatQrToken::create(['cat_id' => $cat->id, 'token' => $token]);
        Sanctum::actingAs($user);

        $response = $this->start("MTP1.C.{$token}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.cat_id', $cat->id);

        $lock = AdoptionPickupLock::sole();
        $this->assertSame($lock->id, $response->json('data.pickup_lock_id'));
        $this->assertSame($user->id, $lock->adopter_id);
        $this->assertEqualsWithDelta(now()->addHours(48)->timestamp, $lock->expires_at->timestamp, 5);
        $this->assertSame('READY', $cat->fresh()->adoption_status);

        // Kucing yang ditahan hilang dari katalog.
        $this->getJson('/api/v1/adoption/cats')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_rescanning_same_cat_returns_existing_lock(): void
    {
        Sanctum::actingAs($this->approvedUser());
        $cat = $this->cat();

        $first = $this->start($cat->unique_code)->assertOk()->json('data.pickup_lock_id');
        $this->start($cat->unique_code)->assertOk()->assertJsonPath('data.pickup_lock_id', $first);

        $this->assertSame(1, AdoptionPickupLock::count());
    }

    public function test_invalid_input_is_rejected(): void
    {
        Sanctum::actingAs($this->approvedUser());

        $this->postJson('/api/v1/adoption/pickups/start', [], ['Idempotency-Key' => 'x'])
            ->assertStatus(422)
            ->assertJsonPath('code', 'VALIDATION_ERROR');

        $this->start('BUKAN-KODE')->assertStatus(422)->assertJsonPath('code', 'QR_INVALID');

        $cat = $this->cat();
        CatQrToken::create(['cat_id' => $cat->id, 'token' => 'lama', 'status' => 'REVOKED']);
        $this->start('MTP1.C.lama')->assertStatus(422)->assertJsonPath('code', 'QR_REVOKED');
    }

    public function test_user_without_valid_approval_is_forbidden(): void
    {
        $cat = $this->cat();

        Sanctum::actingAs(User::factory()->create());
        $this->start($cat->unique_code)->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');

        Sanctum::actingAs($this->approvedUser(approvedDaysAgo: 31));
        $this->start($cat->unique_code)->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');

        $this->assertSame(0, AdoptionPickupLock::count());
    }

    public function test_cat_held_by_other_or_not_ready_is_unavailable(): void
    {
        $held = $this->cat();
        AdoptionPickupLock::create(['cat_id' => $held->id, 'adopter_id' => $this->approvedUser()->id, 'expires_at' => now()->addHour()]);
        Sanctum::actingAs($this->approvedUser());

        $this->start($held->unique_code)->assertStatus(409)->assertJsonPath('code', 'CAT_NOT_AVAILABLE');
        $this->start($this->cat(['adoption_status' => 'UNREVIEWED'])->unique_code)->assertStatus(409)->assertJsonPath('code', 'CAT_NOT_AVAILABLE');
        $this->start($this->cat(['presence_status' => 'MISSING'])->unique_code)->assertStatus(409)->assertJsonPath('code', 'CAT_NOT_AVAILABLE');
    }

    public function test_expired_lock_is_released_for_new_adopter(): void
    {
        $cat = $this->cat();
        $old = AdoptionPickupLock::create(['cat_id' => $cat->id, 'adopter_id' => $this->approvedUser()->id, 'expires_at' => now()->subMinute()]);
        Sanctum::actingAs($this->approvedUser());

        $this->start($cat->unique_code)->assertOk();

        $this->assertSame(AdoptionPickupLock::STATUS_RELEASED, $old->fresh()->status);
        $this->assertSame(1, AdoptionPickupLock::where('status', AdoptionPickupLock::STATUS_HELD)->count());
    }

    public function test_user_with_open_adoption_cannot_hold(): void
    {
        $user = $this->approvedUser();
        Adoption::create(['application_id' => AdoptionApplication::sole()->id, 'cat_id' => $this->cat(['adoption_status' => 'ADOPTED'])->id, 'adopter_id' => $user->id]);
        Sanctum::actingAs($user);

        $this->start($this->cat()->unique_code)->assertStatus(409)->assertJsonPath('code', 'ALREADY_ADOPTING');
    }

    public function test_user_cannot_hold_two_cats(): void
    {
        Sanctum::actingAs($this->approvedUser());
        $this->start($this->cat()->unique_code)->assertOk();

        $this->start($this->cat()->unique_code)->assertStatus(409)->assertJsonPath('code', 'CONFLICT');
        $this->assertSame(1, AdoptionPickupLock::count());
    }
}
