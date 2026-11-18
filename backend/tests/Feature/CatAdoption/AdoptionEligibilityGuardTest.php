<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-13 (ADP-01, IT-23): endpoint mahasiswa adopsi.
 */
class AdoptionEligibilityGuardTest extends TestCase
{
    use RefreshDatabase;

    private function userOfType(string $type, bool $verified = true): User
    {
        $user = User::factory()->create(['email_verified_at' => $verified ? now() : null]);
        $user->user_type = $type; // tidak fillable
        $user->save();

        return $user;
    }

    public function test_lecturer_cannot_apply_for_adoption(): void
    {
        Sanctum::actingAs($this->userOfType('DOSEN'));

        $this->postJson('/api/v1/adoption/applications', [], ['Idempotency-Key' => 'dosen-1'])
            ->assertForbidden()
            ->assertJsonPath('success', false)
            ->assertJsonPath('code', 'NOT_STUDENT');

        $this->assertSame(0, AdoptionApplication::count());
    }

    public function test_staff_cannot_open_adoption_catalog(): void
    {
        Sanctum::actingAs($this->userOfType('STAF'));

        $this->getJson('/api/v1/adoption/cats')
            ->assertForbidden()
            ->assertJsonPath('code', 'NOT_STUDENT');
    }

    public function test_unverified_lecturer_gets_not_student(): void
    {
        Sanctum::actingAs($this->userOfType('DOSEN', verified: false));

        $this->getJson('/api/v1/adoption/mine')->assertForbidden()->assertJsonPath('code', 'NOT_STUDENT');
    }

    public function test_unverified_student_cannot_apply(): void
    {
        Sanctum::actingAs($this->userOfType('MAHASISWA', verified: false));

        $this->postJson('/api/v1/adoption/applications', [], ['Idempotency-Key' => 'unverified-1'])
            ->assertForbidden()
            ->assertJsonPath('code', 'EMAIL_NOT_VERIFIED');

        $this->getJson('/api/v1/adoption/applications/mine')
            ->assertForbidden()
            ->assertJsonPath('code', 'EMAIL_NOT_VERIFIED');
    }

    public function test_verified_student_passes_guard(): void
    {
        Sanctum::actingAs($this->userOfType('MAHASISWA'));

        $this->getJson('/api/v1/adoption/applications/mine')->assertOk()->assertJsonPath('success', true);
    }
}
