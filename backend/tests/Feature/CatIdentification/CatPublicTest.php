<?php

namespace Tests\Feature\CatIdentification;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatIdentification\Services\CatQrService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CatPublicTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);
    }

    protected function createUser(string $userType = 'MAHASISWA'): User
    {
        $user = new User([
            'name' => 'Test User',
            'email' => Str::random(8) . '@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->user_type = $userType;
        $user->email_verified_at = now();
        $user->save();

        return $user;
    }

    protected function createCat(array $overrides = []): Cat
    {
        $cat = Cat::create(array_merge([
            'unique_code' => 'CAT' . strtoupper(Str::random(4)),
            'name' => 'Oyen',
            'gender' => 'MALE',
            'color_pattern' => 'Orange Tabby',
            'age_group' => 'ADULT',
            'is_sterilized' => true,
            'description' => 'Kucing ramah di TULT',
            'presence_status' => 'ON_CAMPUS',
            'health_status' => 'HEALTHY',
            'adoption_status' => 'UNREVIEWED',
            'verification_status' => 'VERIFIED',
        ], $overrides));

        app(CatQrService::class)->issueInitialToken($cat);

        return $cat;
    }

    public function test_unauthenticated_user_cannot_access_cats(): void
    {
        $this->getJson('/api/v1/cats')->assertStatus(401);
    }

    public function test_public_cat_list_and_detail_exclude_private_and_coordinate_fields(): void
    {
        $user = $this->createUser();
        $cat = $this->createCat(['unique_code' => 'CAT101', 'name' => 'Miko']);

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/cats?search=Miko')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.id', $cat->id)
            ->assertJsonPath('data.0.unique_code', 'CAT101')
            ->assertJsonMissingPath('data.0.qr_code_token')
            ->assertJsonMissingPath('data.0.active_qr')
            ->assertJsonMissingPath('data.0.last_seen_lat')
            ->assertJsonMissingPath('data.0.last_seen_lng');

        $this->getJson("/api/v1/cats/{$cat->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $cat->id)
            ->assertJsonPath('data.presence_status', 'ON_CAMPUS')
            ->assertJsonMissingPath('data.qr_code_token')
            ->assertJsonMissingPath('data.active_qr')
            ->assertJsonMissingPath('data.last_seen_lat')
            ->assertJsonMissingPath('data.last_seen_lng');

        $this->getJson('/api/v1/cats/01NONEXISTENT0000000000000')
            ->assertStatus(404)
            ->assertJsonPath('code', 'NOT_FOUND');
    }

    public function test_find_by_manual_unique_code(): void
    {
        $user = $this->createUser();
        $cat = $this->createCat(['unique_code' => 'CAT777', 'name' => 'Luna']);

        Sanctum::actingAs($user);

        $this->getJson('/api/v1/cats/by-code/cat777')
            ->assertStatus(200)
            ->assertJsonPath('data.id', $cat->id)
            ->assertJsonPath('data.unique_code', 'CAT777');

        $this->getJson('/api/v1/cats/by-code/UNKNOWN999')
            ->assertStatus(404);
    }

    public function test_cat_actions_hub_respects_status_and_user_type(): void
    {
        $student = $this->createUser('MAHASISWA');
        $lecturer = $this->createUser('DOSEN');
        $cat = $this->createCat(['adoption_status' => 'READY', 'health_status' => 'HEALTHY']);

        Sanctum::actingAs($student);
        $this->getJson("/api/v1/cats/{$cat->id}/actions")
            ->assertStatus(200)
            ->assertJsonPath('data.0.id', 'game.encounter')
            ->assertJsonPath('data.0.enabled', true)
            ->assertJsonPath('data.1.id', 'adoption.apply')
            ->assertJsonPath('data.1.enabled', true);

        Sanctum::actingAs($lecturer);
        $this->getJson("/api/v1/cats/{$cat->id}/actions")
            ->assertStatus(200)
            ->assertJsonPath('data.1.id', 'adoption.apply')
            ->assertJsonPath('data.1.enabled', false);
    }

    public function test_record_sighting_requires_idempotency_and_deduplicates_per_source(): void
    {
        $user = $this->createUser();
        $cat = $this->createCat();

        Sanctum::actingAs($user);

        $this->postJson("/api/v1/cats/{$cat->id}/sightings", [])
            ->assertStatus(400);

        $this->withHeader('Idempotency-Key', 'key-invalid-1')
            ->postJson("/api/v1/cats/{$cat->id}/sightings", ['location_lat' => 999])
            ->assertStatus(422);

        $this->withHeader('Idempotency-Key', 'key-sight-1')
            ->postJson("/api/v1/cats/{$cat->id}/sightings", [
                'source' => 'manual_sighting',
                'location_lat' => -6.973,
                'location_lng' => 107.630,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.deduplicated', false);

        $this->assertDatabaseCount('cat_sightings', 1);
        $this->assertDatabaseCount('point_transactions', 0);
        $this->assertNotNull($cat->fresh()->last_seen_at);

        $this->withHeader('Idempotency-Key', 'key-sight-1')
            ->postJson("/api/v1/cats/{$cat->id}/sightings", [
                'source' => 'manual_sighting',
                'location_lat' => -6.973,
                'location_lng' => 107.630,
            ])
            ->assertStatus(201);
        $this->assertDatabaseCount('cat_sightings', 1);

        $this->withHeader('Idempotency-Key', 'key-sight-2')
            ->postJson("/api/v1/cats/{$cat->id}/sightings", [
                'source' => 'manual_sighting',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.deduplicated', true);
        $this->assertDatabaseCount('cat_sightings', 1);

        $this->withHeader('Idempotency-Key', 'key-sight-3')
            ->postJson("/api/v1/cats/{$cat->id}/sightings", [
                'source' => 'encounter',
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.deduplicated', false);
        $this->assertDatabaseCount('cat_sightings', 2);
    }
}
