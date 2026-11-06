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

    public function test_meow_12_review_queue_and_reviewer_decision_prevent_self_review_and_award_points(): void
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

        $adminOwnSubmission = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->spotAdmin->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'UNDER_REVIEW',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now()->subMinutes(10),
            'finalized_at' => now()->subMinutes(5),
        ]);

        $studentSubmission = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'UNDER_REVIEW',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now()->subMinutes(8),
            'finalized_at' => now()->subMinutes(3),
        ]);

        // 1. Mahasiswa biasa tanpa permission feeding.review ditolak (403)
        $forbiddenQueue = $this->actingAs($this->student, 'sanctum')
            ->getJson('/api/v1/admin/feeding/review-queue');
        $forbiddenQueue->assertStatus(403);

        // 2. Spot Admin bisa melihat antrean review (200)
        $queueResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->getJson('/api/v1/admin/feeding/review-queue');
        $queueResp->assertStatus(200)
            ->assertJsonCount(2, 'data');

        // 3. AFS-07: Reviewer tidak boleh me-review pengajuannya sendiri (403 SELF_REVIEW_FORBIDDEN)
        $selfReviewResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/activities/{$adminOwnSubmission->id}/review", [
                'decision' => 'VERIFIED',
                'notes' => 'Approve punya sendiri',
            ]);
        $selfReviewResp->assertStatus(403)
            ->assertJsonPath('code', 'SELF_REVIEW_FORBIDDEN');

        // 4. Validasi gagal ketika decision tidak valid (422)
        $invalidResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/activities/{$studentSubmission->id}/review", [
                'decision' => 'INVALID_DECISION',
            ]);
        $invalidResp->assertStatus(422);

        // 5. Sukses menyetujui pengajuan mahasiswa: status VERIFIED & poin CREDITED
        $approveResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/activities/{$studentSubmission->id}/review", [
                'decision' => 'VERIFIED',
                'notes' => 'Bukti foto mangkuk jelas dan sesuai spot',
            ]);
        $approveResp->assertStatus(200)
            ->assertJsonPath('data.status', 'VERIFIED')
            ->assertJsonPath('data.reward_status', 'CREDITED')
            ->assertJsonPath('data.points_awarded', 10);
    }

    public function test_meow_13_user_activity_history_and_public_heatmap_14_days(): void
    {
        // 1. Tanpa autentikasi ke /api/v1/feeding/activities/mine ditolak (401)
        $unauthResp = $this->getJson('/api/v1/feeding/activities/mine');
        $unauthResp->assertStatus(401);

        // Buat 1 aktivitas VERIFIED dan 1 aktivitas UNDER_REVIEW dalam 14 hari terakhir
        FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'VERIFIED',
            'reward_status' => 'CREDITED',
            'potential_points' => 10,
            'reward_snapshot' => ['points_awarded' => 10, 'reward_capped' => false],
            'scanned_at' => now()->subDays(2),
            'finalized_at' => now()->subDays(2),
        ]);

        FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'UNDER_REVIEW',
            'reward_status' => 'PENDING',
            'potential_points' => 10,
            'scanned_at' => now()->subHours(4),
            'finalized_at' => now()->subHours(4),
        ]);

        // 2. Mahasiswa melihat riwayat miliknya dengan pemisahan status & reward_status (AFS-08)
        $mineResp = $this->actingAs($this->student, 'sanctum')
            ->getJson('/api/v1/feeding/activities/mine');
        $mineResp->assertStatus(200)
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'feeding_record_ref', 'spot_id', 'status', 'reward_status', 'points_awarded'],
                ],
            ]);

        // 3. Publik melihat heatmap 14 hari terakhir dengan verified_count & pending_count terpisah (AFS-09)
        $heatmapResp = $this->getJson('/api/v1/feeding/heatmap');
        $heatmapResp->assertStatus(200)
            ->assertJsonPath('data.0.spot_id', $this->activeSpot->id)
            ->assertJsonPath('data.0.window_days', 14)
            ->assertJsonPath('data.0.verified_count', 1)
            ->assertJsonPath('data.0.pending_count', 1);
    }

    public function test_meow_14_dynamic_reward_formula_appendix_a1_and_point_reversal_without_negative_balance(): void
    {
        $rewardService = app(\App\Modules\FeedingSpot\Services\FeedingRewardService::class);

        // 1. Uji formula Lampiran A.1 untuk spot jarang diberi makan (Sp=1.0, St=1.0, Sq=1.0, D(1)=1.0)
        // P0=10 * (1 + 0.60*1 + 0.25*1 + 0.15*1) * 1.0 = 10 * 2.0 = 20 poin
        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'VERIFIED',
            'reward_status' => 'CREDITED',
            'potential_points' => 10,
            'reward_snapshot' => ['points_awarded' => 10],
            'flags' => [],
            'scanned_at' => now()->subMinutes(10),
            'finalized_at' => now(),
        ]);

        $m1 = $this->createMediaRecord($this->student, hash('sha256', 'm14-1'));
        $m2 = $this->createMediaRecord($this->student, hash('sha256', 'm14-2'));
        FeedingEvidence::create(['activity_id' => $activity->id, 'media_id' => $m1, 'captured_at' => now(), 'sort_order' => 0]);
        FeedingEvidence::create(['activity_id' => $activity->id, 'media_id' => $m2, 'captured_at' => now(), 'sort_order' => 1]);

        $snapshot = $rewardService->calculateRewardSnapshot($activity, now());
        $this->assertEquals(20, $snapshot['dynamic_points']);
        $this->assertFalse($snapshot['reward_capped']);
        $this->assertEquals(1.0, $snapshot['sp']);
        $this->assertEquals(1.0, $snapshot['st']);
        $this->assertEquals(1.0, $snapshot['sq']);
        $this->assertEquals(1.0, $snapshot['dn']);

        // 2. Uji reversal poin (AFS-12): saldo mahasiswa hanya 4 poin (lebih kecil dari 10 poin yang di-reverse),
        // saldo diklem ke 0 (tidak boleh negatif) dan reward_status menjadi REVERSED
        DB::table('point_balances')->insert([
            'user_id' => $this->student->id,
            'total_points' => 4,
            'updated_at' => now(),
        ]);

        $revResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/activities/{$activity->id}/review", [
                'decision' => 'REJECTED',
                'reason' => 'Foto terbukti hasil rekayasa saat audit',
            ]);

        $revResp->assertStatus(200)
            ->assertJsonPath('data.status', 'REJECTED')
            ->assertJsonPath('data.reward_status', 'REVERSED')
            ->assertJsonPath('data.new_balance', 0);

        $balanceAfter = (int) DB::table('point_balances')->where('user_id', $this->student->id)->value('total_points');
        $this->assertEquals(0, $balanceAfter);
    }

    public function test_meow_23_spot_cats_and_hub_action_provider(): void
    {
        $cat = \App\Modules\Cat\Models\Cat::create([
            'id' => (string) Str::ulid(),
            'unique_code' => 'CAT-M23',
            'name' => 'Oyen MEOW-23',
            'presence_status' => 'ON_CAMPUS',
            'health_status' => 'HEALTHY',
            'adoption_status' => 'UNREVIEWED',
            'verification_status' => 'VERIFIED',
        ]);

        $actionProvider = new \App\Modules\FeedingSpot\Services\FeedingActionProvider();

        // 1. Cat not yet linked to spot -> feeding.start is disabled
        $actionsBefore = $actionProvider->actionsFor($cat, $this->student);
        $this->assertCount(1, $actionsBefore);
        $this->assertFalse($actionsBefore[0]['enabled']);
        $this->assertStringContainsString('belum diasosiasikan', $actionsBefore[0]['reason']);

        // 2. Admin attaches cat to active spot
        $attachResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/spots/{$this->activeSpot->id}/cats", [
                'cat_ids' => [$cat->id],
            ]);
        $attachResp->assertStatus(200)
            ->assertJsonPath('data.attached_count', 1);

        // 3. Admin lists spot cats
        $listResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->getJson("/api/v1/admin/feeding/spots/{$this->activeSpot->id}/cats");
        $listResp->assertStatus(200)
            ->assertJsonCount(1, 'data.cats');

        // 4. Cat is now linked -> feeding.start is enabled
        $actionsAfter = $actionProvider->actionsFor($cat, $this->student);
        $this->assertTrue($actionsAfter[0]['enabled']);
        $this->assertNull($actionsAfter[0]['reason']);
        $this->assertCount(1, $actionsAfter[0]['spots']);

        // 5. Hub cat actions endpoint /api/v1/cats/{id}/actions includes enabled feeding.start
        $catActionsResp = $this->actingAs($this->student, 'sanctum')
            ->getJson("/api/v1/cats/{$cat->id}/actions");
        $catActionsResp->assertStatus(200);
        $feedingItem = collect($catActionsResp->json('data'))->firstWhere('id', 'feeding.start');
        $this->assertNotNull($feedingItem);
        $this->assertTrue($feedingItem['enabled']);

        // 6. Admin detaches cat
        $detachResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->deleteJson("/api/v1/admin/feeding/spots/{$this->activeSpot->id}/cats/{$cat->id}");
        $detachResp->assertStatus(200);

        // Verify detached
        $actionsDetached = $actionProvider->actionsFor($cat, $this->student);
        $this->assertFalse($actionsDetached[0]['enabled']);
    }

    public function test_meow_24_scheduled_jobs_expire_sessions_refresh_aggregates_and_retention(): void
    {
        // 1. Uji expire-sessions
        $draftNoIntentExpired = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-EXP-01',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(16),
            'reward_status' => 'PENDING',
        ]);

        $draftWithIntentExpired = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-EXP-02',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(70),
            'intent_at' => now()->subMinutes(65),
            'finalize_deadline_at' => now()->subMinutes(5),
            'reward_status' => 'PENDING',
        ]);

        $draftFresh = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-EXP-03',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(5),
            'reward_status' => 'PENDING',
        ]);

        $this->artisan('feeding:expire-sessions')->assertSuccessful();

        $this->assertEquals('EXPIRED', $draftNoIntentExpired->fresh()->status);
        $this->assertEquals('NOT_ELIGIBLE', $draftNoIntentExpired->fresh()->reward_status);
        $this->assertEquals('EXPIRED', $draftWithIntentExpired->fresh()->status);
        $this->assertEquals('NOT_ELIGIBLE', $draftWithIntentExpired->fresh()->reward_status);
        $this->assertEquals('DRAFT', $draftFresh->fresh()->status);

        // 2. Uji refresh-aggregates
        FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-AGG-01',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'VERIFIED',
            'scanned_at' => now()->subDays(2),
            'finalized_at' => now()->subDays(2),
            'reward_status' => 'CREDITED',
        ]);

        $this->artisan('feeding:refresh-aggregates', ['--spot' => $this->activeSpot->id])->assertSuccessful();

        $agg = \App\Modules\FeedingSpot\Models\FeedingAggregate::where('spot_id', $this->activeSpot->id)->first();
        $this->assertNotNull($agg);
        $this->assertEquals(1, $agg->verified_count);
        $this->assertNotNull($agg->computed_at);

        // Pastikan endpoint public spot merender is_stale: false dan computed_at
        $spotResp = $this->getJson("/api/v1/feeding/spots/{$this->activeSpot->id}");
        $spotResp->assertStatus(200)
            ->assertJsonPath('data.aggregate.is_stale', false);
        $this->assertNotNull($spotResp->json('data.aggregate.computed_at'));

        // 3. Uji cleanup-retention (180 hari VERIFIED, 30 hari REJECTED)
        $mOldVerified = $this->createMediaRecord($this->student, hash('sha256', 'old-ver'));
        $mOldRejected = $this->createMediaRecord($this->student, hash('sha256', 'old-rej'));
        $mRecent = $this->createMediaRecord($this->student, hash('sha256', 'recent'));

        $actOldVerified = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-RET-01',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'VERIFIED',
            'scanned_at' => now()->subDays(190),
            'finalized_at' => now()->subDays(185),
            'reward_status' => 'CREDITED',
        ]);
        FeedingEvidence::create(['activity_id' => $actOldVerified->id, 'media_id' => $mOldVerified, 'captured_at' => now()->subDays(185)]);

        $actOldRejected = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-RET-02',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'REJECTED',
            'scanned_at' => now()->subDays(40),
            'finalized_at' => now()->subDays(35),
            'reward_status' => 'NOT_ELIGIBLE',
        ]);
        DB::table('feeding_activities')->where('id', $actOldRejected->id)->update([
            'updated_at' => now()->subDays(35),
        ]);
        FeedingEvidence::create(['activity_id' => $actOldRejected->id, 'media_id' => $mOldRejected, 'captured_at' => now()->subDays(35)]);

        $actRecent = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-RET-03',
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'location_lat' => (float) $this->activeSpot->latitude,
            'location_lng' => (float) $this->activeSpot->longitude,
            'status' => 'VERIFIED',
            'scanned_at' => now()->subDays(5),
            'finalized_at' => now()->subDays(5),
            'reward_status' => 'CREDITED',
        ]);
        FeedingEvidence::create(['activity_id' => $actRecent->id, 'media_id' => $mRecent, 'captured_at' => now()->subDays(5)]);

        $this->artisan('feeding:cleanup-retention')->assertSuccessful();

        $this->assertDatabaseMissing('feeding_evidence', ['media_id' => $mOldVerified]);
        $this->assertDatabaseMissing('feeding_evidence', ['media_id' => $mOldRejected]);
        $this->assertDatabaseHas('feeding_evidence', ['media_id' => $mRecent]);
    }

    public function test_meow_25_pending_review_indicator(): void
    {
        $newSpot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'SPOT-M25',
            'name' => 'Spot MEOW-25',
            'description' => 'Spot untuk uji pending review',
            'latitude' => -6.9745,
            'longitude' => 107.6305,
            'qr_token' => 'TOKEN_SPOT_M25',
            'status' => 'ACTIVE',
        ]);

        // 1. Awalnya belum ada catatan dan has_pending_review false
        $initialResp = $this->getJson("/api/v1/feeding/spots/{$newSpot->id}");
        $initialResp->assertStatus(200)
            ->assertJsonPath('data.last_fed_at', null)
            ->assertJsonPath('data.has_pending_review', false);

        // 2. Ada pengajuan berstatus UNDER_REVIEW
        $pendingAct = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'feeding_record_ref' => 'REF-M25-01',
            'user_id' => $this->student->id,
            'spot_id' => $newSpot->id,
            'location_lat' => (float) $newSpot->latitude,
            'location_lng' => (float) $newSpot->longitude,
            'status' => 'UNDER_REVIEW',
            'scanned_at' => now(),
            'finalized_at' => now(),
            'reward_status' => 'PENDING',
        ]);

        $pendingDetailResp = $this->getJson("/api/v1/feeding/spots/{$newSpot->id}");
        $pendingDetailResp->assertStatus(200)
            ->assertJsonPath('data.has_pending_review', true);

        $pendingListResp = $this->getJson("/api/v1/feeding/spots");
        $pendingListResp->assertStatus(200);
        $spotItem = collect($pendingListResp->json('data'))->firstWhere('id', $newSpot->id);
        $this->assertNotNull($spotItem);
        $this->assertTrue($spotItem['has_pending_review']);

        // 3. Setelah disetujui (VERIFIED), has_pending_review kembali false dan last_fed_at terisi
        $pendingAct->update(['status' => 'VERIFIED']);

        $verifiedResp = $this->getJson("/api/v1/feeding/spots/{$newSpot->id}");
        $verifiedResp->assertStatus(200)
            ->assertJsonPath('data.has_pending_review', false);
        $this->assertNotNull($verifiedResp->json('data.last_fed_at'));
    }
}
