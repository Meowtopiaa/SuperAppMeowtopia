<?php

namespace App\Modules\FeedingSpot\Tests\Feature;

use App\Models\User;
use App\Modules\FeedingSpot\Database\Seeders\FeedingSettingSeeder;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRuleEngine;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
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

    public function test_meow_9_confirm_intent_checks_ownership_and_15_minute_window(): void
    {
        $otherStudent = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Lain',
            'email' => 'other@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);

        // 1. Sesi yang sudah lewat > 15 menit sejak scan ditolak dengan 422 SESSION_EXPIRED
        $expiredActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now()->subMinutes(16),
            'intent_deadline_at' => now()->subMinute(),
            'finalize_deadline_at' => now()->addMinutes(44),
        ]);

        $expiredResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-intent-expired-01')
            ->postJson("/api/v1/feeding/activities/{$expiredActivity->id}/intent");
        $expiredResp->assertStatus(422)
            ->assertJsonPath('code', 'SESSION_EXPIRED');

        $this->assertEquals('EXPIRED', $expiredActivity->fresh()->status);

        // 2. Sesi aktif: pengguna lain ditolak (403 FORBIDDEN), pemilik sesi berhasil (200 OK)
        $activeSession = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now(),
            'intent_deadline_at' => now()->addMinutes(15),
            'finalize_deadline_at' => now()->addMinutes(60),
        ]);

        $forbiddenResp = $this->actingAs($otherStudent, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-intent-forbidden-01')
            ->postJson("/api/v1/feeding/activities/{$activeSession->id}/intent");
        $forbiddenResp->assertStatus(403)
            ->assertJsonPath('code', 'FORBIDDEN');

        $okResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-intent-ok-01')
            ->postJson("/api/v1/feeding/activities/{$activeSession->id}/intent");
        $okResp->assertStatus(200)
            ->assertJsonPath('data.activity_id', $activeSession->id)
            ->assertJsonStructure(['data' => ['activity_id', 'status', 'intent_confirmed_at', 'finalize_deadline_at']]);

        $this->assertNotNull($activeSession->fresh()->intent_at);
    }

    private function createMediaRecord(User $owner, string $sha256): string
    {
        $mediaId = (string) Str::ulid();
        DB::table('media_files')->insert([
            'id' => $mediaId,
            'owner_id' => $owner->id,
            'purpose' => 'feeding_proof',
            'disk' => 'local',
            'path' => "media/feeding_proof/{$mediaId}.jpg",
            'mime' => 'image/jpeg',
            'size_bytes' => 120000,
            'sha256' => $sha256,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $mediaId;
    }

    public function test_meow_10_feeding_rule_engine_evaluates_r1_r2_r4_r5_r6_r8_without_gps(): void
    {
        $engine = app(FeedingRuleEngine::class);

        // 1. Pengguna baru (< 2 riwayat VERIFIED) terkena flag NEW_USER_SAMPLE (R6) -> UNDER_REVIEW
        $newUserActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(5),
        ]);
        $media1 = $this->createMediaRecord($this->student, hash('sha256', 'photo-unique-1'));

        $eval1 = $engine->evaluateAndRecord($newUserActivity, [$media1]);
        $this->assertEquals('UNDER_REVIEW', $eval1['status']);
        $this->assertContains('NEW_USER_SAMPLE', $eval1['flags']);

        // Pastikan hanya 6 aturan non-GPS (R1, R2, R4, R5, R6, R8) yang dievaluasi (tanpa R3/R9)
        $rulesRecorded = FeedingRuleResult::where('activity_id', $newUserActivity->id)->pluck('rule')->toArray();
        $this->assertEquals([
            'R1_QR_VALID',
            'R2_SESSION_TIMELY',
            'R4_PHOTO_UNIQUE',
            'R5_COOLDOWN_PASSED',
            'R6_NEW_USER_SAMPLE',
            'R8_RATE_LIMIT_OK',
        ], $rulesRecorded);

        // 2. Pengguna terpercaya (>= 2 riwayat VERIFIED) dengan foto unik langsung VERIFIED
        for ($i = 1; $i <= 2; $i++) {
            FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'user_id' => $this->student->id,
                'spot_id' => $this->inactiveSpot->id,
                'status' => 'VERIFIED',
                'scanned_at' => now()->subDays($i + 1),
                'finalized_at' => now()->subDays($i + 1),
            ]);
        }

        $trustedActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(3),
        ]);
        $media2 = $this->createMediaRecord($this->student, hash('sha256', 'photo-unique-2'));
        FeedingEvidence::create([
            'activity_id' => $trustedActivity->id,
            'media_id' => $media2,
            'captured_at' => now(),
            'sort_order' => 0,
        ]);

        $eval2 = $engine->evaluateAndRecord($trustedActivity, [$media2]);
        $this->assertEquals('VERIFIED', $eval2['status']);
        $this->assertEmpty($eval2['flags']);

        // 3. Foto duplikat (SHA-256 sama dengan foto yang sudah dipakai) terkena flag PHOTO_REUSED (R4) -> UNDER_REVIEW
        $duplicatePhotoActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(2),
        ]);
        $reusedMedia = $this->createMediaRecord($this->student, hash('sha256', 'photo-unique-2'));

        $eval3 = $engine->evaluateAndRecord($duplicatePhotoActivity, [$reusedMedia]);
        $this->assertEquals('UNDER_REVIEW', $eval3['status']);
        $this->assertContains('PHOTO_REUSED', $eval3['flags']);
    }

    public function test_meow_11_finalize_session_point_service_integration_and_optional_sighting(): void
    {
        DB::table('point_rules')->insert([
            'id' => (string) Str::ulid(),
            'rule_key' => 'feeding.verified',
            'module' => 'FeedingSpot',
            'points' => 10,
            'daily_cap_count' => 3,
            'daily_cap_points' => 60,
            'description' => 'Aktivitas pemberian pakan terverifikasi',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('point_balances')->insert([
            'user_id' => $this->student->id,
            'total_points' => 0,
            'updated_at' => now(),
        ]);

        $catId = (string) Str::ulid();
        DB::table('cats')->insert([
            'id' => $catId,
            'unique_code' => 'CAT001',
            'name' => 'Oyen TULT',
            'gender' => 'MALE',
            'presence_status' => 'ON_CAMPUS',
            'health_status' => 'HEALTHY',
            'adoption_status' => 'UNREVIEWED',
            'verification_status' => 'VERIFIED',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $otherStudent = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Lain',
            'email' => 'other11@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);

        // Buat 2 riwayat VERIFIED agar mahasiswa lolos aturan R6 (NEW_USER_SAMPLE)
        for ($i = 1; $i <= 2; $i++) {
            FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'user_id' => $this->student->id,
                'spot_id' => $this->inactiveSpot->id,
                'status' => 'VERIFIED',
                'reward_status' => 'CREDITED',
                'potential_points' => 10,
                'scanned_at' => now()->subDays($i + 1),
                'finalized_at' => now()->subDays($i + 1),
            ]);
        }

        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now()->subMinutes(4),
            'intent_at' => now()->subMinutes(3),
            'intent_deadline_at' => now()->addMinutes(11),
            'finalize_deadline_at' => now()->addMinutes(56),
        ]);

        $mediaId = $this->createMediaRecord($this->student, hash('sha256', 'finalize-photo-11'));

        // 1. Akses ditolak untuk pengguna lain (403 FORBIDDEN)
        $forbiddenResp = $this->actingAs($otherStudent, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-fin-forbidden-11')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
            ]);
        $forbiddenResp->assertStatus(403);

        // 2. Validasi gagal ketika media_ids kosong (422)
        $invalidResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-fin-invalid-11')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [],
            ]);
        $invalidResp->assertStatus(422);

        // 3. Sukses finalisasi: otomatis VERIFIED, poin CREDITED via PointService, dan cat_sightings tercatat (AFS-13)
        $okResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-fin-ok-11')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
                'food_type' => 'wet_food',
                'food_amount' => '1 mangkuk',
                'cat_code' => 'CAT001',
                'notes' => 'Oyen makan dengan lahap',
            ]);

        $okResp->assertStatus(200)
            ->assertJsonPath('data.status', 'VERIFIED')
            ->assertJsonPath('data.reward_status', 'CREDITED')
            ->assertJsonPath('data.points_awarded', 10);

        // 4. IT-05: Idempotent replay dengan Idempotency-Key yang sama tidak menduplikasi poin
        $replayResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-fin-ok-11')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
                'food_type' => 'wet_food',
                'food_amount' => '1 mangkuk',
                'cat_code' => 'CAT001',
                'notes' => 'Oyen makan dengan lahap',
            ]);
        $replayResp->assertStatus(200)
            ->assertJsonPath('data.activity_id', $activity->id);

        $txCount = DB::table('point_transactions')
            ->where('user_id', $this->student->id)
            ->where('source_ref_id', $activity->id)
            ->count();
        $this->assertEquals(1, $txCount);

        $sightingCount = DB::table('cat_sightings')
            ->where('cat_id', $catId)
            ->where('user_id', $this->student->id)
            ->where('source', 'feeding')
            ->count();
        $this->assertEquals(1, $sightingCount);
    }
}
