<?php

namespace App\Modules\FeedingSpot\Tests\Feature;

use App\Models\User;
use App\Modules\FeedingSpot\Database\Seeders\FeedingSettingSeeder;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class FeedingSpotTest extends TestCase
{
    use RefreshDatabase;

    private User $student;
    private User $spotAdmin;
    private FeedingSpot $activeSpot;
    private FeedingSpot $inactiveSpot;

    protected function setUpTraits(): array
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);

        return parent::setUpTraits();
    }

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['spot.manage', 'feeding.review'] as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'sanctum']);
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
        }

        $userRole = Role::firstOrCreate(['name' => 'user', 'guard_name' => 'web']);
        Role::firstOrCreate(['name' => 'user', 'guard_name' => 'sanctum']);

        $adminRoleWeb = Role::firstOrCreate(['name' => 'spot_admin', 'guard_name' => 'web']);
        $adminRoleSanctum = Role::firstOrCreate(['name' => 'spot_admin', 'guard_name' => 'sanctum']);
        $adminRoleWeb->syncPermissions(['spot.manage', 'feeding.review']);
        $adminRoleSanctum->syncPermissions(['spot.manage', 'feeding.review']);

        $this->seed(FeedingSettingSeeder::class);

        $this->student = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Uji',
            'email' => 'student@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);
        $this->student->assignRole($userRole);

        $this->spotAdmin = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Spot Admin Acumalaka',
            'email' => 'spotadmin@telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'STAF',
            'is_active' => true,
        ]);
        $this->spotAdmin->assignRole($adminRoleWeb);

        $this->activeSpot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'SPOT-TULT-01',
            'name' => 'Spot Pakan TULT Lobby',
            'description' => 'Titik makan resmi dekat lobby barat TULT',
            'latitude' => -6.9740000,
            'longitude' => 107.6300000,
            'qr_token' => 'TOKEN_SPOT_TULT_01_ACTIVE_123456',
            'status' => 'ACTIVE',
        ]);

        $this->inactiveSpot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'SPOT-OLD-99',
            'name' => 'Spot Lama Nonaktif',
            'description' => 'Titik makan nonaktif',
            'latitude' => -6.9750000,
            'longitude' => 107.6290000,
            'qr_token' => 'TOKEN_SPOT_OLD_99_INACTIVE_12345',
            'status' => 'INACTIVE',
        ]);
    }

    public function test_meow_5_default_settings_are_seeded_and_models_work(): void
    {
        $this->assertEquals(5.0, FeedingSetting::getFloat('base_points'));
        $this->assertEquals(5.0, FeedingSetting::getFloat('min_points'));
        $this->assertEquals(20.0, FeedingSetting::getFloat('max_points'));
        $this->assertEquals(6.0, FeedingSetting::getFloat('cooldown_hours'));
        $this->assertCount(1, FeedingSpot::active()->get());
    }

    public function test_meow_6_public_spots_list_and_detail_expose_active_spots_with_last_fed_at(): void
    {
        $finalizedAt = now()->subHour();

        FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'VERIFIED',
            'reward_status' => 'CREDITED',
            'potential_points' => 10,
            'food_type' => 'dry_food',
            'food_amount' => '1 mangkuk',
            'scanned_at' => $finalizedAt->copy()->subMinutes(5),
            'finalized_at' => $finalizedAt,
        ]);

        $listResp = $this->getJson('/api/v1/feeding/spots');
        $listResp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->activeSpot->id)
            ->assertJsonMissingPath('data.0.qr_token')
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'code', 'name', 'latitude', 'longitude', 'status', 'last_fed_at', 'aggregate'],
                ],
            ]);

        $this->assertNotNull($listResp->json('data.0.last_fed_at'));

        $detailResp = $this->getJson("/api/v1/feeding/spots/{$this->activeSpot->id}");
        $detailResp->assertStatus(200)
            ->assertJsonPath('data.id', $this->activeSpot->id)
            ->assertJsonCount(1, 'data.recent_activities')
            ->assertJsonStructure(['data' => ['id', 'code', 'name', 'last_fed_at', 'aggregate', 'recent_activities']]);

        // Spot INACTIVE tidak tampil di publik (AFS-01)
        $inactiveResp = $this->getJson("/api/v1/feeding/spots/{$this->inactiveSpot->id}");
        $inactiveResp->assertStatus(404)
            ->assertJsonPath('code', 'SPOT_NOT_FOUND');
    }

    public function test_meow_7_admin_spot_crud_and_qr_regeneration_permissions_and_validation(): void
    {
        // 1. Akses ditolak untuk mahasiswa biasa tanpa permission spot.manage (403)
        $forbiddenResp = $this->actingAs($this->student, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => 'SPOT-GKU-02',
                'name' => 'Spot GKU Baru',
                'latitude' => -6.973,
                'longitude' => 107.631,
            ]);
        $forbiddenResp->assertStatus(403);

        // 2. Validasi gagal ketika field wajib kosong (422)
        $invalidResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => '',
            ]);
        $invalidResp->assertStatus(422);

        // 3. Sukses membuat spot baru (201)
        $createResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => 'spot-gku-02',
                'name' => 'Spot GKU Baru',
                'latitude' => -6.973,
                'longitude' => 107.631,
            ]);
        $createResp->assertStatus(201)
            ->assertJsonPath('data.code', 'SPOT-GKU-02');

        $spotId = $createResp->json('data.id');
        $oldToken = $createResp->json('data.qr_token');

        // 4. Sukses update status spot & regenerate QR
        $patchResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->patchJson("/api/v1/admin/feeding/spots/{$spotId}", [
                'status' => 'MAINTENANCE',
            ]);
        $patchResp->assertStatus(200)
            ->assertJsonPath('data.status', 'MAINTENANCE');

        $qrResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/spots/{$spotId}/qr");
        $qrResp->assertStatus(200);
        $this->assertNotEquals($oldToken, $qrResp->json('data.qr_token'));
    }

    public function test_meow_8_start_session_validates_idempotency_qr_type_and_cooldown(): void
    {
        // 1. Akses tanpa autentikasi ditolak (401)
        $unauthResp = $this->postJson('/api/v1/feeding/activities', [
            'qr_token' => "MTP1.S.{$this->activeSpot->qr_token}",
        ]);
        $unauthResp->assertStatus(401);

        // 2. Tanpa Idempotency-Key ditolak (400 VALIDATION_ERROR)
        $noIdemResp = $this->actingAs($this->student, 'sanctum')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => "MTP1.S.{$this->activeSpot->qr_token}",
            ]);
        $noIdemResp->assertStatus(400);

        // 3. IT-03: Scan QR kalung kucing di modul Feeding Spot ditolak dengan 422 QR_WRONG_TYPE
        $catQrResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-qr-cat-01')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => 'MTP1.C.RANDOM_CAT_TOKEN_123',
            ]);
        $catQrResp->assertStatus(422)
            ->assertJsonPath('code', 'QR_WRONG_TYPE');

        // 4. Sukses membuka sesi DRAFT dengan QR Spot resmi (201)
        $openResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-open-01')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => "MTP1.S.{$this->activeSpot->qr_token}",
            ]);
        $openResp->assertStatus(201)
            ->assertJsonPath('data.status', 'DRAFT')
            ->assertJsonPath('data.spot.id', $this->activeSpot->id)
            ->assertJsonStructure([
                'data' => ['activity_id', 'feeding_record_ref', 'status', 'spot', 'scanned_at', 'intent_deadline_at', 'finalize_deadline_at'],
            ]);

        // 5. Cooldown 6 jam: jika sudah ada sesi SUBMITTED/UNDER_REVIEW/VERIFIED dalam < 6 jam, tolak dengan 422 COOLDOWN_ACTIVE
        FeedingActivity::where('id', $openResp->json('data.activity_id'))
            ->update(['status' => 'VERIFIED', 'finalized_at' => now()]);

        $cooldownResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-open-cooldown-02')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => "MTP1.S.{$this->activeSpot->qr_token}",
            ]);
        $cooldownResp->assertStatus(422)
            ->assertJsonPath('code', 'COOLDOWN_ACTIVE');
    }
}
