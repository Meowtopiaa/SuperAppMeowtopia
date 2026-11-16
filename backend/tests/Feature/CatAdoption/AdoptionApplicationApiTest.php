<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * EN-10 (FIX-06): POST /api/v1/adoption/applications dan GET /api/v1/adoption/applications/mine
 */
class AdoptionApplicationApiTest extends TestCase
{
    use RefreshDatabase;

    private function postDraft(array $payload = [], ?string $key = null)
    {
        return $this->postJson('/api/v1/adoption/applications', $payload, ['Idempotency-Key' => $key ?? (string) Str::uuid()]);
    }

    public function test_draft_can_be_created_without_cat(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postDraft(['housing_type' => 'KOS', 'answers' => ['q1' => 'ya']])
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_DRAFT)
            ->assertJsonPath('data.housing_type', 'KOS')
            ->assertJsonPath('data.long_term_plan', null)
            ->assertJsonPath('data.precheck_passed', false);

        $application = AdoptionApplication::sole();
        $this->assertTrue($application->applicant->is($user));
        $this->assertNull($application->cat_id);
    }

    public function test_empty_draft_is_allowed(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postDraft()->assertCreated()->assertJsonPath('data.housing_type', null);
    }

    public function test_same_idempotency_key_does_not_create_twice(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $first = $this->postDraft(['housing_type' => 'KOS'], 'key-1')->assertCreated();
        $second = $this->postDraft(['housing_type' => 'KOS'], 'key-1')->assertCreated();

        $this->assertSame($first->json('data.id'), $second->json('data.id'));
        $this->assertSame(1, AdoptionApplication::count());
    }

    public function test_second_open_application_is_rejected(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postDraft()->assertCreated();
        $this->postDraft()->assertStatus(409)->assertJsonPath('code', 'CONFLICT');

        $this->assertSame(1, AdoptionApplication::count());
    }

    public function test_new_draft_allowed_after_rejection(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        AdoptionApplication::create(['applicant_id' => $user->id, 'status' => AdoptionApplication::STATUS_REJECTED]);

        $this->postDraft()->assertCreated();
        $this->assertSame(2, AdoptionApplication::count());
    }

    public function test_draft_rejects_cat_id_and_invalid_fields(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $cat = Cat::create(['unique_code' => 'TST-ABC123', 'name' => 'Oyen']);

        $this->postDraft(['cat_id' => $cat->id, 'owner_permission' => 'mungkin', 'answers' => 'bukan-array'])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonStructure(['errors' => ['cat_id', 'owner_permission', 'answers'], 'request_id']);

        $this->assertSame(0, AdoptionApplication::count());
    }

    public function test_draft_requires_idempotency_key(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/v1/adoption/applications', [])->assertStatus(400);
        $this->assertSame(0, AdoptionApplication::count());
    }

    public function test_draft_requires_login(): void
    {
        $this->postJson('/api/v1/adoption/applications', [], ['Idempotency-Key' => 'k'])->assertUnauthorized();
        $this->assertSame(0, AdoptionApplication::count());
    }

    public function test_mine_lists_only_own_applications_with_admin_note(): void
    {
        [$me, $other] = User::factory()->count(2)->create();
        AdoptionApplication::create([
            'applicant_id' => $me->id,
            'status' => AdoptionApplication::STATUS_REVISION_REQUESTED,
            'review_note' => 'Lengkapi foto kamar.',
        ]);
        AdoptionApplication::create(['applicant_id' => $other->id, 'long_term_plan' => 'Rahasia orang lain']);
        Sanctum::actingAs($me);

        $this->getJson('/api/v1/adoption/applications/mine')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', AdoptionApplication::STATUS_REVISION_REQUESTED)
            ->assertJsonPath('data.0.admin_note', 'Lengkapi foto kamar.')
            ->assertDontSee('Rahasia orang lain');
    }

    public function test_mine_requires_login(): void
    {
        $this->getJson('/api/v1/adoption/applications/mine')->assertUnauthorized();
    }
}
