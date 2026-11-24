<?php

namespace App\Modules\FeedingSpot\Tests\Unit;

use App\Models\User;
use App\Modules\FeedingSpot\Database\Seeders\FeedingSettingSeeder;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRuleEngine;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class FeedingRuleEngineTest extends TestCase
{
    use RefreshDatabase;

    private FeedingSpot $spot;
    private FeedingSpot $otherSpot;
    private User $trustedUser;
    private User $newUser;

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

        $this->seed(FeedingSettingSeeder::class);

        $this->spot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'FS-UNIT-01',
            'name' => 'Spot Unit Test TULT',
            'latitude' => -6.9732000,
            'longitude' => 107.6304000,
            'qr_token' => 'UNITSPOTTOKEN01',
            'status' => 'ACTIVE',
        ]);

        $this->otherSpot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'FS-UNIT-02',
            'name' => 'Spot Unit Test GKU',
            'latitude' => -6.9742000,
            'longitude' => 107.6314000,
            'qr_token' => 'UNITSPOTTOKEN02',
            'status' => 'ACTIVE',
        ]);

        $this->newUser = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Baru',
            'email' => 'new@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);

        $this->trustedUser = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Terpercaya',
            'email' => 'trusted@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);

        // Buat 2 riwayat VERIFIED agar trustedUser lolos aturan R6_NEW_USER_SAMPLE
        for ($i = 1; $i <= 2; $i++) {
            FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'user_id' => $this->trustedUser->id,
                'spot_id' => $this->spot->id,
                'status' => 'VERIFIED',
                'scanned_at' => now()->subDays($i + 2),
                'finalized_at' => now()->subDays($i + 2),
            ]);
        }
    }

    private function createMedia(User $user, string $hashSeed): string
    {
        $mediaId = (string) Str::ulid();
        DB::table('media_files')->insert([
            'id' => $mediaId,
            'owner_id' => $user->id,
            'purpose' => 'feeding_proof',
            'disk' => 'local',
            'path' => "media/feeding_proof/{$mediaId}.jpg",
            'mime' => 'image/jpeg',
            'size_bytes' => 100000,
            'sha256' => hash('sha256', $hashSeed),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $mediaId;
    }

    public function test_rule_engine_only_evaluates_non_gps_rules_and_verifies_trusted_user(): void
    {
        $engine = app(FeedingRuleEngine::class);

        $activity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->trustedUser->id,
            'spot_id' => $this->spot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(5),
        ]);

        $mediaId = $this->createMedia($this->trustedUser, 'unit-unique-photo-1');
        $result = $engine->evaluateAndRecord($activity, [$mediaId]);

        $this->assertEquals('VERIFIED', $result['status']);
        $this->assertEmpty($result['flags']);

        $ruleNames = FeedingRuleResult::where('activity_id', $activity->id)->pluck('rule')->all();
        $this->assertEquals([
            'R1_QR_VALID',
            'R2_SESSION_TIMELY',
            'R4_PHOTO_UNIQUE',
            'R5_COOLDOWN_PASSED',
            'R6_NEW_USER_SAMPLE',
            'R8_RATE_LIMIT_OK',
        ], $ruleNames);
    }

    public function test_rule_engine_flags_new_user_and_rate_limit_for_review(): void
    {
        $engine = app(FeedingRuleEngine::class);

        // 1. New user (< 2 verified) -> NEW_USER_SAMPLE (UNDER_REVIEW)
        $newActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->newUser->id,
            'spot_id' => $this->spot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(4),
        ]);
        $m1 = $this->createMedia($this->newUser, 'unit-new-user-photo');
        $res1 = $engine->evaluateAndRecord($newActivity, [$m1]);

        $this->assertEquals('UNDER_REVIEW', $res1['status']);
        $this->assertContains('NEW_USER_SAMPLE', $res1['flags']);

        // 2. Rate limit (>= 5 pengajuan hari ini di spot lain) -> HIGH_DAILY_FREQUENCY (UNDER_REVIEW)
        for ($i = 0; $i < 5; $i++) {
            FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'user_id' => $this->trustedUser->id,
                'spot_id' => $this->otherSpot->id,
                'status' => 'VERIFIED',
                'scanned_at' => now()->subMinutes(30),
                'finalized_at' => now(),
            ]);
        }

        $rateActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->trustedUser->id,
            'spot_id' => $this->spot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(2),
        ]);
        $m2 = $this->createMedia($this->trustedUser, 'unit-rate-limit-photo');
        $res2 = $engine->evaluateAndRecord($rateActivity, [$m2]);

        $this->assertEquals('UNDER_REVIEW', $res2['status']);
        $this->assertContains('HIGH_DAILY_FREQUENCY', $res2['flags']);
    }

    public function test_rule_engine_flags_photo_reused_for_review_and_rejects_expired_session(): void
    {
        $engine = app(FeedingRuleEngine::class);

        $existingActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->trustedUser->id,
            'spot_id' => $this->otherSpot->id,
            'status' => 'VERIFIED',
            'scanned_at' => now()->subDays(1),
            'finalized_at' => now()->subDays(1),
        ]);
        $usedMedia = $this->createMedia($this->trustedUser, 'unit-reused-hash');
        FeedingEvidence::create([
            'activity_id' => $existingActivity->id,
            'media_id' => $usedMedia,
            'captured_at' => now()->subDays(1),
            'sort_order' => 0,
        ]);

        // 1. Foto duplikat SHA-256 dalam waktu sesi normal -> UNDER_REVIEW dengan flag PHOTO_REUSED
        $reusedPhotoActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->trustedUser->id,
            'spot_id' => $this->spot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(10),
        ]);
        $reusedMediaCopy = $this->createMedia($this->trustedUser, 'unit-reused-hash');

        $resReused = $engine->evaluateAndRecord($reusedPhotoActivity, [$reusedMediaCopy]);
        $this->assertEquals('UNDER_REVIEW', $resReused['status']);
        $this->assertContains('PHOTO_REUSED', $resReused['flags']);

        // 2. Sesi lewat > 60 menit -> REJECTED dengan flag SESSION_EXPIRED
        $expiredActivity = FeedingActivity::create([
            'id' => (string) Str::ulid(),
            'user_id' => $this->trustedUser->id,
            'spot_id' => $this->spot->id,
            'status' => 'DRAFT',
            'scanned_at' => now()->subMinutes(75),
        ]);
        $freshMedia = $this->createMedia($this->trustedUser, 'unit-fresh-hash');

        $resExpired = $engine->evaluateAndRecord($expiredActivity, [$freshMedia]);
        $this->assertEquals('REJECTED', $resExpired['status']);
        $this->assertContains('SESSION_EXPIRED', $resExpired['flags']);
    }
}
