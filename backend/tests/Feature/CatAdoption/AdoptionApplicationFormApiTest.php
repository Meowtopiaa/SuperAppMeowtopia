<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-14 (ADP-02): PUT /adoption/applications/{id} dan POST /adoption/applications/{id}/submit
 */
class AdoptionApplicationFormApiTest extends TestCase
{
    use RefreshDatabase;

    private function media(User $owner, string $purpose = 'adoption_evidence'): string
    {
        $id = (string) Str::ulid();
        DB::table('media_files')->insert([
            'id' => $id,
            'owner_id' => $owner->id,
            'path' => "media/{$purpose}/{$id}.jpg",
            'mime' => 'image/jpeg',
            'size_bytes' => 1000,
            'sha256' => hash('sha256', $id),
            'purpose' => $purpose,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $id;
    }

    private function draft(User $user, array $attributes = []): AdoptionApplication
    {
        return AdoptionApplication::create($attributes + ['applicant_id' => $user->id]);
    }

    private function completePayload(User $user): array
    {
        return [
            'housing_type' => 'KOS',
            'owner_permission' => true,
            'can_afford' => true,
            'long_term_plan' => 'Dirawat sampai lulus lalu dibawa pulang.',
            'housing_media_id' => $this->media($user),
            'commitment_accepted' => true,
            'commitment_version' => AdoptionApplication::COMMITMENT_VERSION,
        ];
    }

    private function submit(string $id)
    {
        return $this->postJson("/api/v1/adoption/applications/{$id}/submit", [], ['Idempotency-Key' => (string) Str::uuid()]);
    }

    public function test_owner_can_save_draft_with_photo_and_commitment(): void
    {
        $user = User::factory()->create();
        $application = $this->draft($user);
        $payload = $this->completePayload($user);
        Sanctum::actingAs($user);

        $this->putJson("/api/v1/adoption/applications/{$application->id}", $payload)
            ->assertOk()
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_DRAFT)
            ->assertJsonPath('data.housing_media_id', $payload['housing_media_id'])
            ->assertJsonPath('data.commitment_version', AdoptionApplication::COMMITMENT_VERSION);

        $this->assertNotNull($application->fresh()->commitment_accepted_at);

        // Foto baru menggantikan yang lama; null mengosongkan field.
        $newPhoto = $this->media($user);
        $this->putJson("/api/v1/adoption/applications/{$application->id}", ['housing_media_id' => $newPhoto, 'long_term_plan' => null])
            ->assertOk()
            ->assertJsonPath('data.housing_media_id', $newPhoto)
            ->assertJsonPath('data.long_term_plan', null)
            ->assertJsonPath('data.housing_type', 'KOS');

        $this->assertSame(1, $application->media()->count());
    }

    public function test_draft_rejects_foreign_photo_and_outdated_commitment(): void
    {
        [$user, $other] = User::factory()->count(2)->create();
        $application = $this->draft($user);
        Sanctum::actingAs($user);

        $this->putJson("/api/v1/adoption/applications/{$application->id}", [
            'housing_media_id' => $this->media($other),
            'commitment_accepted' => true,
            'commitment_version' => '0.9',
        ])
            ->assertStatus(422)
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonValidationErrors(['housing_media_id', 'commitment_version']);

        $this->putJson("/api/v1/adoption/applications/{$application->id}", ['housing_media_id' => $this->media($user, 'avatar')])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['housing_media_id']);
    }

    public function test_other_user_cannot_edit_or_submit(): void
    {
        [$owner, $intruder] = User::factory()->count(2)->create();
        $application = $this->draft($owner, ['housing_type' => 'KOS']);
        Sanctum::actingAs($intruder);

        $this->putJson("/api/v1/adoption/applications/{$application->id}", ['housing_type' => 'RUMAH'])
            ->assertForbidden()
            ->assertJsonPath('code', 'FORBIDDEN');
        $this->submit($application->id)->assertForbidden();

        $this->assertSame('KOS', $application->fresh()->housing_type);
    }

    public function test_unknown_application_returns_not_found(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/v1/adoption/applications/' . Str::ulid(), [])
            ->assertNotFound()
            ->assertJsonPath('code', 'NOT_FOUND');
    }

    public function test_complete_draft_can_be_submitted(): void
    {
        $user = User::factory()->create();
        $application = $this->draft($user);
        Sanctum::actingAs($user);
        $this->putJson("/api/v1/adoption/applications/{$application->id}", $this->completePayload($user))->assertOk();

        $this->submit($application->id)
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_SUBMITTED);

        $this->assertNotNull($application->fresh()->submitted_at);
    }

    public function test_incomplete_draft_cannot_be_submitted(): void
    {
        $user = User::factory()->create();
        $application = $this->draft($user, ['housing_type' => 'KOS']);
        Sanctum::actingAs($user);

        $this->submit($application->id)
            ->assertStatus(422)
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonValidationErrors(['owner_permission', 'can_afford', 'long_term_plan', 'housing_media_id', 'commitment_accepted'])
            ->assertJsonMissingValidationErrors(['housing_type']);

        $this->assertSame(AdoptionApplication::STATUS_DRAFT, $application->fresh()->status);
    }

    public function test_submitted_application_is_locked(): void
    {
        $user = User::factory()->create();
        $application = $this->draft($user, ['status' => AdoptionApplication::STATUS_SUBMITTED]);
        Sanctum::actingAs($user);

        $this->putJson("/api/v1/adoption/applications/{$application->id}", ['housing_type' => 'RUMAH'])
            ->assertStatus(409)
            ->assertJsonPath('code', 'CONFLICT');
        $this->submit($application->id)->assertStatus(409);
    }

    public function test_revision_can_be_resubmitted(): void
    {
        $user = User::factory()->create();
        $application = $this->draft($user, ['status' => AdoptionApplication::STATUS_REVISION_REQUESTED]);
        Sanctum::actingAs($user);
        $this->putJson("/api/v1/adoption/applications/{$application->id}", $this->completePayload($user))->assertOk();

        $this->submit($application->id)->assertOk()->assertJsonPath('data.status', AdoptionApplication::STATUS_SUBMITTED);
    }
}
