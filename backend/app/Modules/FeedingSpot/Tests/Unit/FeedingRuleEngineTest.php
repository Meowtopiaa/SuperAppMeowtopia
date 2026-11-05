<?php

namespace App\Modules\FeedingSpot\Tests\Unit;

use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingRewardService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class FeedingRuleEngineTest extends TestCase
{
    use RefreshDatabase;

    public function test_default_settings_are_seeded_correctly(): void
    {
        FeedingSetting::ensureDefaults();

        $this->assertEquals(5.0, FeedingSetting::getFloat('base_points'));
        $this->assertEquals(5.0, FeedingSetting::getFloat('min_points'));
        $this->assertEquals(20.0, FeedingSetting::getFloat('max_points'));
        $this->assertEquals(6.0, FeedingSetting::getFloat('cooldown_hours'));
    }

    public function test_dynamic_point_formula_matches_appendix_a1_bounds(): void
    {
        FeedingSetting::ensureDefaults();

        $spot = FeedingSpot::create([
            'id' => (string) Str::ulid(),
            'code' => 'SPOT-UNIT-01',
            'name' => 'Spot Unit Test',
            'latitude' => -6.9740000,
            'longitude' => 107.6300000,
            'qr_token' => Str::random(32),
            'status' => 'ACTIVE',
        ]);

        $service = app(FeedingRewardService::class);

        // Ketika spot belum pernah diberi makan (total_feedings = 0, last_fed_at = null)
        // Frequency bonus maksimal (8) + Recency bonus maksimal (7) + Base (5) = 20 poin
        $pointsColdSpot = $service->calculateDynamicPoints($spot->id);
        $this->assertEquals(20, $pointsColdSpot);

        // Ketika spot sudah sangat sering diberi makan (total_feedings >= 28) dan baru saja diberi makan (0 jam lalu)
        // Frequency bonus (0) + Recency bonus (0) + Base (5) = 5 poin
        FeedingAggregate::create([
            'id' => (string) Str::ulid(),
            'spot_id' => $spot->id,
            'window_start' => now()->subDays(14)->toDateString(),
            'window_end' => now()->toDateString(),
            'total_feedings' => 30,
            'unique_feeders' => 5,
            'last_fed_at' => now(),
            'need_score' => 0,
            'computed_at' => now(),
        ]);

        $pointsHotSpot = $service->calculateDynamicPoints($spot->id);
        $this->assertEquals(5, $pointsHotSpot);
    }
}

