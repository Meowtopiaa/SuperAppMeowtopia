<?php

namespace App\Modules\FeedingSpot\Database\Seeders;

use App\Models\User;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FeedingSettingSeeder extends Seeder
{
    /**
     * Seed default pengaturan verifikasi & poin Adopt Feeding Spot (MEOW-5)
     * beserta data demo antrean review jika akun demo DatabaseSeeder tersedia.
     */
    public function run(): void
    {
        FeedingSetting::ensureDefaults();

        $student = User::where('email', 'mahasiswa@student.telkomuniversity.ac.id')->first();
        $spotTult = FeedingSpot::where('code', 'SPOT-TULT-01')->first();
        $spotGku = FeedingSpot::where('code', 'SPOT-GKU-01')->first();

        if ($student && $spotTult && FeedingActivity::count() === 0) {
            $m1 = (string) Str::ulid();
            DB::table('media_files')->insert([
                'id' => $m1,
                'owner_id' => $student->id,
                'purpose' => 'feeding_proof',
                'disk' => 'local',
                'path' => "media/feeding_proof/{$m1}.jpg",
                'mime' => 'image/jpeg',
                'size_bytes' => 145000,
                'sha256' => hash('sha256', 'demo-evidence-1'),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $act1 = FeedingActivity::create([
                'id' => (string) Str::ulid(),
                'feeding_record_ref' => 'REF-DEMO-TULT-001',
                'user_id' => $student->id,
                'spot_id' => $spotTult->id,
                'location_lat' => (float) $spotTult->latitude,
                'location_lng' => (float) $spotTult->longitude,
                'status' => 'UNDER_REVIEW',
                'reward_status' => 'PENDING',
                'potential_points' => 15,
                'food_type' => 'wet_food',
                'food_amount' => '1 sachet penuh',
                'flags' => ['FIRST_TWO_SUBMISSIONS', 'NEW_USER_SAMPLE'],
                'scanned_at' => now()->subMinutes(18),
                'intent_at' => now()->subMinutes(15),
                'finalized_at' => now()->subMinutes(10),
            ]);
            FeedingEvidence::create([
                'activity_id' => $act1->id,
                'media_id' => $m1,
                'captured_at' => now()->subMinutes(11),
                'sort_order' => 0,
            ]);
            FeedingRuleResult::create([
                'activity_id' => $act1->id,
                'rule' => 'R1_QR_VALID',
                'result' => 'PASS',
                'detail' => 'Spot aktif dan token QR valid.',
            ]);
            FeedingRuleResult::create([
                'activity_id' => $act1->id,
                'rule' => 'R4_PHOTO_UNIQUE',
                'result' => 'PASS',
                'detail' => 'Foto bukti unik tervalidasi SHA-256.',
            ]);
            FeedingRuleResult::create([
                'activity_id' => $act1->id,
                'rule' => 'R6_NEW_USER_SAMPLE',
                'result' => 'REVIEW',
                'detail' => 'Dua pengajuan pertama pengguna baru wajib direview admin.',
            ]);

            if ($spotGku) {
                $m2 = (string) Str::ulid();
                DB::table('media_files')->insert([
                    'id' => $m2,
                    'owner_id' => $student->id,
                    'purpose' => 'feeding_proof',
                    'disk' => 'local',
                    'path' => "media/feeding_proof/{$m2}.jpg",
                    'mime' => 'image/jpeg',
                    'size_bytes' => 162000,
                    'sha256' => hash('sha256', 'demo-evidence-1'),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $act2 = FeedingActivity::create([
                    'id' => (string) Str::ulid(),
                    'feeding_record_ref' => 'REF-DEMO-GKU-002',
                    'user_id' => $student->id,
                    'spot_id' => $spotGku->id,
                    'location_lat' => (float) $spotGku->latitude,
                    'location_lng' => (float) $spotGku->longitude,
                    'status' => 'UNDER_REVIEW',
                    'reward_status' => 'PENDING',
                    'potential_points' => 14,
                    'food_type' => 'dry_food',
                    'food_amount' => '2 mangkuk',
                    'flags' => ['PHOTO_REUSED', 'RANDOM_SAMPLE'],
                    'scanned_at' => now()->subMinutes(35),
                    'intent_at' => now()->subMinutes(30),
                    'finalized_at' => now()->subMinutes(25),
                ]);
                FeedingEvidence::create([
                    'activity_id' => $act2->id,
                    'media_id' => $m2,
                    'captured_at' => now()->subMinutes(26),
                    'sort_order' => 0,
                ]);
                FeedingRuleResult::create([
                    'activity_id' => $act2->id,
                    'rule' => 'R4_PHOTO_UNIQUE',
                    'result' => 'REVIEW',
                    'detail' => 'Terdeteksi hash SHA-256 foto pernah dipakai pada sesi sebelumnya.',
                ]);
            }
        }
    }
}
