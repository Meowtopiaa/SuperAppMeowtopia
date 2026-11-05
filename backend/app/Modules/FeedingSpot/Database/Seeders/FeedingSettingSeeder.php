<?php

namespace App\Modules\FeedingSpot\Database\Seeders;

use App\Modules\FeedingSpot\Models\FeedingSetting;
use Illuminate\Database\Seeder;

class FeedingSettingSeeder extends Seeder
{
    /**
     * Seed default pengaturan verifikasi & poin Adopt Feeding Spot (MEOW-5).
     */
    public function run(): void
    {
        FeedingSetting::ensureDefaults();
    }
}
