<?php

namespace App\Modules\FeedingSpot\Tests\Feature;

use App\Models\User;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
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
    private User $otherStudent;
    private User $spotAdmin;
    private FeedingSpot $activeSpot;
    private FeedingSpot $inactiveSpot;

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

        $this->student = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Uji',
            'email' => 'student@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);
        $this->student->assignRole($userRole);

        $this->otherStudent = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Lain',
            'email' => 'other@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);
        $this->otherStudent->assignRole($userRole);

        $this->spotAdmin = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Spot Admin Acumalaka',
            'email' => 'spotadmin@telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'STAF',
            'is_active' => true,
        ]);
        $this->spotAdmin->assignRole($adminRoleWeb);

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

        FeedingSetting::ensureDefaults();

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

    private function createMediaRecord(User $owner, string $sha256): string
    {
        $mediaId = (string) Str::ulid();
        DB::table('media_files')->insert([
            'id' => $mediaId,
            'uploader_id' => $owner->id,
            'purpose' => 'feeding_proof',
            'disk' => 'public',
            'path' => "media/feeding_proof/{$mediaId}.jpg",
            'mime_type' => 'image/jpeg',
            'size_bytes' => 120000,
            'sha256' => $sha256,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $mediaId;
    }

    public function test_public_spots_list_and_detail_only_expose_active_spots_with_last_fed_at(): void
    {
        $listResp = $this->getJson('/api/v1/feeding/spots');
        $listResp->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->activeSpot->id)
            ->assertJsonStructure([
                'data' => [
                    '*' => ['id', 'code', 'name', 'latitude', 'longitude', 'status', 'last_fed_at', 'aggregate'],
                ],
            ]);

        $detailResp = $this->getJson("/api/v1/feeding/spots/{$this->activeSpot->id}");
        $detailResp->assertStatus(200)
            ->assertJsonPath('data.id', $this->activeSpot->id)
            ->assertJsonStructure(['data' => ['id', 'code', 'name', 'last_fed_at', 'aggregate', 'recent_activities']]);

        // Spot INACTIVE tidak tampil di publik (AFS-01)
        $inactiveResp = $this->getJson("/api/v1/feeding/spots/{$this->inactiveSpot->id}");
        $inactiveResp->assertStatus(404);
    }

    public function test_admin_spot_crud_and_qr_regeneration_permissions_and_validation(): void
    {
        // Akses ditolak untuk mahasiswa biasa (403)
        $forbiddenResp = $this->actingAs($this->student, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => 'SPOT-GKU-02',
                'name' => 'Spot GKU Baru',
                'latitude' => -6.973,
                'longitude' => 107.631,
            ]);
        $forbiddenResp->assertStatus(403);

        // Validasi gagal ketika field wajib kosong (422)
        $invalidResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => '',
            ]);
        $invalidResp->assertStatus(422);

        // Sukses membuat spot baru (201)
        $createResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson('/api/v1/admin/feeding/spots', [
                'code' => 'SPOT-GKU-02',
                'name' => 'Spot GKU Baru',
                'latitude' => -6.973,
                'longitude' => 107.631,
            ]);
        $createResp->assertStatus(201)
            ->assertJsonPath('data.code', 'SPOT-GKU-02');

        $spotId = $createResp->json('data.id');
        $oldToken = $createResp->json('data.qr_token');

        // Sukses update status spot & regenerate QR
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

    public function test_start_session_validates_qr_type_and_cooldown(): void
    {
        // IT-03: Scan QR kucing di modul Feeding Spot wajib ditolak dengan QR_WRONG_TYPE
        $catQrResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-qr-cat-01')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => 'MTP1.C.RANDOM_CAT_TOKEN_123',
            ]);
        $catQrResp->assertStatus(422)
            ->assertJsonPath('code', 'QR_WRONG_TYPE');

        // Sukses membuka sesi DRAFT dengan QR Spot resmi
        $openResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-open-01')
            ->postJson('/api/v1/feeding/activities', [
                'qr_token' => "MTP1.S.{$this->activeSpot->qr_token}",
            ]);
        $openResp->assertStatus(201)
            ->assertJsonPath('data.status', 'DRAFT')
            ->assertJsonPath('data.spot.id', $this->activeSpot->id);
    }

    public function test_confirm_intent_checks_ownership_and_15_minute_window(): void
    {
        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'NONE',
            'points_awarded' => 0,
            'scanned_at' => now(),
        ]);

        // Pengguna lain ditolak (403)
        $forbiddenResp = $this->actingAs($this->otherStudent, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-intent-forbidden')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/intent");
        $forbiddenResp->assertStatus(403);

        // Pemilik sesi berhasil konfirmasi intent
        $okResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-intent-ok')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/intent");
        $okResp->assertStatus(200)
            ->assertJsonPath('data.activity_id', $activity->id);
    }

    public function test_finalize_routes_new_user_to_review_and_prevents_self_review(): void
    {
        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->spotAdmin->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'NONE',
            'points_awarded' => 0,
            'scanned_at' => now()->subMinutes(2),
            'intent_confirmed_at' => now()->subMinute(),
        ]);

        $mediaId = $this->createMediaRecord($this->spotAdmin, hash('sha256', 'unique-photo-1'));

        // Finalisasi pertama oleh user masuk ke UNDER_REVIEW (Aturan R6: < 2 verified)
        $finalizeResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-fin-01')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
                'food_type' => 'dry_food',
                'food_amount' => '1 mangkuk',
                'notes' => 'Mangkuk bersih dan terisi penuh',
            ]);

        $finalizeResp->assertStatus(200)
            ->assertJsonPath('data.status', 'UNDER_REVIEW')
            ->assertJsonPath('data.reward_status', 'PENDING');

        // AFS-07: Reviewer tidak boleh me-review pengajuannya sendiri (403 SELF_REVIEW_FORBIDDEN)
        $selfReviewResp = $this->actingAs($this->spotAdmin, 'sanctum')
            ->postJson("/api/v1/admin/feeding/activities/{$activity->id}/review", [
                'decision' => 'VERIFIED',
                'notes' => 'Approve punya sendiri',
            ]);
        $selfReviewResp->assertStatus(403)
            ->assertJsonPath('code', 'SELF_REVIEW_FORBIDDEN');
    }

    public function test_trusted_user_auto_verifies_updates_last_fed_at_and_awards_points_idempotently(): void
    {
        // Buat 2 riwayat VERIFIED terlebih dahulu agar pengguna lolos aturan R6 (NEW_USER_SAMPLE)
        for ($i = 1; $i <= 2; $i++) {
            FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'user_id' => $this->student->id,
                'spot_id' => $this->inactiveSpot->id,
                'status' => 'VERIFIED',
                'reward_status' => 'CREDITED',
                'points_awarded' => 10,
                'scanned_at' => now()->subDays($i + 1),
                'submitted_at' => now()->subDays($i + 1),
                'verified_at' => now()->subDays($i + 1),
            ]);
        }

        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->student->id,
            'spot_id' => $this->activeSpot->id,
            'status' => 'DRAFT',
            'reward_status' => 'NONE',
            'points_awarded' => 0,
            'scanned_at' => now()->subMinutes(3),
            'intent_confirmed_at' => now()->subMinutes(2),
        ]);

        $mediaId = $this->createMediaRecord($this->student, hash('sha256', 'trusted-photo-3'));

        $finalizeResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-trusted-fin-03')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
                'food_type' => 'wet_food',
                'food_amount' => '1 mangkuk',
            ]);

        $finalizeResp->assertStatus(200)
            ->assertJsonPath('data.status', 'VERIFIED')
            ->assertJsonPath('data.reward_status', 'CREDITED')
            ->assertJsonPath('data.points_awarded', 10);

        // IT-05: Replay dengan Idempotency-Key yang sama menghasilkan respons identik tanpa duplikasi poin
        $replayResp = $this->actingAs($this->student, 'sanctum')
            ->withHeader('Idempotency-Key', 'idem-trusted-fin-03')
            ->postJson("/api/v1/feeding/activities/{$activity->id}/finalize", [
                'media_ids' => [$mediaId],
                'food_type' => 'wet_food',
                'food_amount' => '1 mangkuk',
            ]);
        $replayResp->assertStatus(200)
            ->assertJsonPath('data.activity_id', $activity->id);

        $txCount = DB::table('point_transactions')
            ->where('user_id', $this->student->id)
            ->where('reference_id', $activity->id)
            ->count();
        $this->assertEquals(1, $txCount);

        // Pastikan spot detail menampilkan last_fed_at terbaru & heatmap terbarui
        $spotResp = $this->getJson("/api/v1/feeding/spots/{$this->activeSpot->id}");
        $spotResp->assertStatus(200);
        $this->assertNotNull($spotResp->json('data.last_fed_at'));
        $this->assertEquals(1, $spotResp->json('data.aggregate.total_feedings'));

        // Pastikan riwayat pengguna menampilkan status kegiatan & status reward terpisah (AFS-08)
        $mineResp = $this->actingAs($this->student, 'sanctum')
            ->getJson('/api/v1/feeding/activities/mine');
        $mineResp->assertStatus(200)
            ->assertJsonPath('data.0.status', 'VERIFIED')
            ->assertJsonPath('data.0.reward_status', 'CREDITED');
    }
}

