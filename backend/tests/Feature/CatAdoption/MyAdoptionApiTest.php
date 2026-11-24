<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-10 (FIX-06): GET /api/v1/adoption/mine
 */
class MyAdoptionApiTest extends TestCase
{
    use RefreshDatabase;

    private function makeCat(string $name): Cat
    {
        return Cat::create(['unique_code' => 'TST-' . Str::upper(Str::random(6)), 'name' => $name]);
    }

    public function test_approved_application_is_not_an_adoption(): void
    {
        $user = User::factory()->create();
        AdoptionApplication::create(['applicant_id' => $user->id, 'status' => AdoptionApplication::STATUS_APPROVED]);
        Sanctum::actingAs($user);

        $this->getJson('/api/v1/adoption/mine')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data');
    }

    public function test_mine_lists_own_open_adoption_only(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        $myApp = AdoptionApplication::create(['applicant_id' => $me->id, 'status' => AdoptionApplication::STATUS_APPROVED]);
        $otherApp = AdoptionApplication::create(['applicant_id' => $other->id, 'status' => AdoptionApplication::STATUS_APPROVED]);

        $closed = Adoption::create(['application_id' => $myApp->id, 'cat_id' => $this->makeCat('Lama')->id, 'adopter_id' => $me->id]);
        $closed->update(['status' => Adoption::STATUS_CLOSED_RETURNED, 'closed_at' => now()]);
        $open = Adoption::create(['application_id' => $myApp->id, 'cat_id' => $this->makeCat('Oyen')->id, 'adopter_id' => $me->id]);
        Adoption::create(['application_id' => $otherApp->id, 'cat_id' => $this->makeCat('Belang')->id, 'adopter_id' => $other->id]);

        Sanctum::actingAs($me);

        $this->getJson('/api/v1/adoption/mine')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $open->id)
            ->assertJsonPath('data.0.status', Adoption::STATUS_ACTIVE)
            ->assertJsonPath('data.0.cat.name', 'Oyen')
            ->assertJsonMissingPath('data.0.cat.unique_code');
    }

    public function test_mine_requires_login(): void
    {
        $this->getJson('/api/v1/adoption/mine')->assertUnauthorized();
    }
}
