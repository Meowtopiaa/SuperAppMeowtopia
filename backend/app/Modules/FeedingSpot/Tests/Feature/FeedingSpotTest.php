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
use Tests\TestCase;

class FeedingSpotTest extends TestCase
{
    use RefreshDatabase;

    private User $student;
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

        $this->seed(FeedingSettingSeeder::class);

        $this->student = User::create([
            'id' => (string) Str::ulid(),
            'name' => 'Mahasiswa Uji',
            'email' => 'student@student.telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'user_type' => 'MAHASISWA',
            'is_active' => true,
        ]);

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
}
