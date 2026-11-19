<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * EN-16 (ADP-04): GET /api/v1/admin/adoption/applications
 * dan POST /api/v1/admin/adoption/applications/{id}/decision
 */
class AdminApplicationDecisionApiTest extends TestCase
{
    use RefreshDatabase;

    private function admin(array $permissions = ['adoption.review', 'adoption.approve']): User
    {
        $admin = User::factory()->create();
        foreach ($permissions as $permission) {
            $admin->givePermissionTo(Permission::findOrCreate($permission, 'web'));
        }

        return $admin;
    }

    private function application(string $status = AdoptionApplication::STATUS_SUBMITTED): AdoptionApplication
    {
        return AdoptionApplication::create([
            'applicant_id' => User::factory()->create()->id,
            'housing_type' => 'KOS',
            'owner_permission' => true,
            'can_afford' => true,
            'long_term_plan' => 'Dirawat sampai lulus lalu dibawa pulang.',
            'status' => $status,
            'submitted_at' => $status === AdoptionApplication::STATUS_DRAFT ? null : now(),
            'precheck_passed' => true,
        ]);
    }

    private function decide(string $id, array $payload)
    {
        return $this->postJson("/api/v1/admin/adoption/applications/{$id}/decision", $payload);
    }

    public function test_admin_approves_submitted_application_with_actor_and_time(): void
    {
        $admin = $this->admin();
        $application = $this->application();
        Sanctum::actingAs($admin);

        $this->decide($application->id, ['decision' => 'APPROVE', 'reason' => 'Tempat tinggal layak.'])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_APPROVED)
            ->assertJsonPath('data.admin_note', 'Tempat tinggal layak.')
            ->assertJsonPath('data.reviewed_by', $admin->id);

        $application->refresh();
        $this->assertSame(AdoptionApplication::STATUS_APPROVED, $application->status);
        $this->assertSame($admin->id, $application->reviewed_by);
        $this->assertNotNull($application->reviewed_at);
        // Persetujuan tidak membuat adopsi aktif (FIX-06).
        $this->assertSame(0, Adoption::count());
    }

    public function test_request_changes_makes_application_editable_again(): void
    {
        $application = $this->application();
        Sanctum::actingAs($this->admin());

        $this->decide($application->id, ['decision' => 'REQUEST_CHANGES', 'reason' => 'Foto kamar kurang jelas.'])
            ->assertOk()
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_REVISION_REQUESTED);

        $this->assertTrue($application->fresh()->isEditable());
    }

    public function test_admin_rejects_with_reason(): void
    {
        $application = $this->application();
        Sanctum::actingAs($this->admin());

        $this->decide($application->id, ['decision' => 'REJECT', 'reason' => 'Tidak ada izin pemilik kos.'])
            ->assertOk()
            ->assertJsonPath('data.status', AdoptionApplication::STATUS_REJECTED);
    }

    public function test_decision_and_reason_are_validated(): void
    {
        $application = $this->application();
        Sanctum::actingAs($this->admin());

        $this->decide($application->id, ['decision' => 'APPROVE'])
            ->assertStatus(422)->assertJsonPath('code', 'VALIDATION_ERROR');
        $this->decide($application->id, ['decision' => 'MAYBE', 'reason' => 'x'])
            ->assertStatus(422)->assertJsonPath('code', 'VALIDATION_ERROR');

        $this->assertSame(AdoptionApplication::STATUS_SUBMITTED, $application->fresh()->status);
    }

    public function test_only_submitted_application_can_be_decided(): void
    {
        Sanctum::actingAs($this->admin());

        foreach ([AdoptionApplication::STATUS_DRAFT, AdoptionApplication::STATUS_APPROVED, AdoptionApplication::STATUS_REJECTED] as $status) {
            $application = $this->application($status);
            $this->decide($application->id, ['decision' => 'APPROVE', 'reason' => 'Ok.'])
                ->assertStatus(409)->assertJsonPath('code', 'CONFLICT');
            $this->assertSame($status, $application->fresh()->status);
        }
    }

    public function test_reviewer_without_approve_permission_cannot_approve(): void
    {
        $application = $this->application();
        Sanctum::actingAs($this->admin(['adoption.review']));

        $this->decide($application->id, ['decision' => 'APPROVE', 'reason' => 'Ok.'])
            ->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');
        $this->decide($application->id, ['decision' => 'REQUEST_CHANGES', 'reason' => 'Lengkapi rencana.'])
            ->assertOk();
    }

    public function test_user_without_permission_is_forbidden(): void
    {
        $application = $this->application();
        Sanctum::actingAs(User::factory()->create());

        $this->decide($application->id, ['decision' => 'REJECT', 'reason' => 'x'])
            ->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');
        $this->getJson('/api/v1/admin/adoption/applications')
            ->assertForbidden()->assertJsonPath('code', 'FORBIDDEN');
    }

    public function test_unknown_application_returns_not_found(): void
    {
        Sanctum::actingAs($this->admin());

        $this->decide((string) Str::ulid(), ['decision' => 'REJECT', 'reason' => 'x'])
            ->assertNotFound()->assertJsonPath('code', 'NOT_FOUND');
    }

    public function test_queue_lists_submitted_applications_by_default_without_drafts(): void
    {
        $submitted = $this->application();
        $this->application(AdoptionApplication::STATUS_DRAFT);
        $approved = $this->application(AdoptionApplication::STATUS_APPROVED);
        Sanctum::actingAs($this->admin(['adoption.review']));

        $this->getJson('/api/v1/admin/adoption/applications')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $submitted->id)
            ->assertJsonPath('data.0.applicant.id', $submitted->applicant_id)
            ->assertJsonPath('meta.total', 1);

        $this->getJson('/api/v1/admin/adoption/applications?status=APPROVED')
            ->assertOk()
            ->assertJsonPath('data.0.id', $approved->id);

        $this->getJson('/api/v1/admin/adoption/applications?status=DRAFT')
            ->assertStatus(422)->assertJsonPath('code', 'VALIDATION_ERROR');
    }

    public function test_requires_login(): void
    {
        $application = $this->application();

        $this->getJson('/api/v1/admin/adoption/applications')->assertUnauthorized();
        $this->decide($application->id, ['decision' => 'REJECT', 'reason' => 'x'])->assertUnauthorized();
    }
}
