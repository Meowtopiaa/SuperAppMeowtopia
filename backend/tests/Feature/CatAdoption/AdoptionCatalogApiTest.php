<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Models\AdoptionPickupLock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-10 (FIX-05): GET /api/v1/adoption/cats
 */
class AdoptionCatalogApiTest extends TestCase
{
    use RefreshDatabase;

    private function makeCat(array $attributes = []): Cat
    {
        return Cat::create($attributes + [
            'unique_code' => 'TST-' . Str::upper(Str::random(6)),
            'name' => 'Kucing ' . Str::random(4),
        ]);
    }

    public function test_catalog_lists_only_ready_cats_without_open_adoption_or_hold(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $ready = $this->makeCat(['adoption_status' => 'READY']);
        $this->makeCat(); // UNREVIEWED (default, FIX-05)
        $this->makeCat(['adoption_status' => 'READY', 'presence_status' => 'MISSING']);

        $held = $this->makeCat(['adoption_status' => 'READY']);
        AdoptionPickupLock::create(['cat_id' => $held->id, 'adopter_id' => $user->id, 'expires_at' => now()->addHours(48)]);

        $adopted = $this->makeCat(['adoption_status' => 'READY']);
        $other = User::factory()->create();
        $app = AdoptionApplication::create(['applicant_id' => $other->id, 'status' => AdoptionApplication::STATUS_APPROVED]);
        Adoption::create(['application_id' => $app->id, 'cat_id' => $adopted->id, 'adopter_id' => $other->id]);

        $response = $this->getJson('/api/v1/adoption/cats');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ready->id)
            ->assertJsonPath('meta.total', 1)
            ->assertJsonMissingPath('data.0.unique_code');
    }

    public function test_catalog_rejects_invalid_per_page(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/v1/adoption/cats?per_page=500')
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['errors' => ['per_page'], 'request_id']);
    }

    public function test_catalog_requires_login(): void
    {
        $this->getJson('/api/v1/adoption/cats')->assertUnauthorized();
    }

    /** EN-12, CAT-09, IT-17: respons katalog hanya berisi field publik. */
    public function test_catalog_returns_only_public_fields(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->makeCat([
            'adoption_status' => 'READY',
            'gender' => 'FEMALE',
            'age_group' => 'ADULT',
            'color_pattern' => 'Calico',
            'is_sterilized' => true,
            'description' => 'Tenang dan suka dielus.',
            'traits' => ['catatan_internal' => 'jangan tampil'],
            'last_seen_at' => now(),
        ]);

        $response = $this->getJson('/api/v1/adoption/cats')->assertOk();

        $cat = $response->json('data.0');
        $this->assertEqualsCanonicalizing(
            ['id', 'name', 'gender', 'color_pattern', 'age_group', 'is_sterilized', 'description', 'primary_photo_media_id', 'adoption_status'],
            array_keys($cat),
        );
        $this->assertStringNotContainsString('jangan tampil', $response->getContent());
    }
}
