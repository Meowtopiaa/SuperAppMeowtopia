<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Seed Permissions
        $permissions = [
            'cat.edit',
            'cat.curate',
            'cat.qr.regenerate',
            'spot.manage',
            'feeding.review',
            'game.config',
            'adoption.review',
            'adoption.approve',
            'adoption.set_ready',
            'adoption.verify_return',
            'incident.view',
            'incident.dispatch',
            'incident.close',
            'points.config',
            'user.manage',
        ];

        foreach ($permissions as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'sanctum']);
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
        }

        // 2. Seed Roles and assign permissions
        $roles = [
            'super_admin' => $permissions,
            'user' => [],
            'caretaker' => ['incident.view'],
            'data_curator' => ['cat.edit', 'cat.curate', 'cat.qr.regenerate'],
            'adoption_admin' => ['adoption.review', 'adoption.approve', 'adoption.set_ready', 'adoption.verify_return'],
            'game_admin' => ['game.config'],
            'spot_admin' => ['spot.manage', 'feeding.review'],
            'incident_admin' => ['incident.view', 'incident.dispatch', 'incident.close'],
        ];

        foreach ($roles as $roleName => $perms) {
            $roleSanctum = Role::firstOrCreate(['name' => $roleName, 'guard_name' => 'sanctum']);
            $roleWeb = Role::firstOrCreate(['name' => $roleName, 'guard_name' => 'web']);
            if (!empty($perms)) {
                $roleSanctum->syncPermissions($perms);
                $roleWeb->syncPermissions($perms);
            }
        }

        // 3. Seed Default Test Accounts per Role
        $usersData = [
            [
                'email' => 'superadmin@meowtopia.app',
                'name' => 'Super Admin (PM)',
                'role' => 'super_admin',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'mahasiswa@student.telkomuniversity.ac.id',
                'name' => 'Budi Mahasiswa',
                'role' => 'user',
                'user_type' => 'MAHASISWA',
            ],
            [
                'email' => 'curator@telkomuniversity.ac.id',
                'name' => 'Admin Curator (Rekans Caps)',
                'role' => 'data_curator',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'spotadmin@telkomuniversity.ac.id',
                'name' => 'Admin Feeding Spot (Acumalaka)',
                'role' => 'spot_admin',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'gameadmin@telkomuniversity.ac.id',
                'name' => 'Admin Game (SUPER-SUB)',
                'role' => 'game_admin',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'adoptionadmin@telkomuniversity.ac.id',
                'name' => 'Admin Adopsi (E-Nigma)',
                'role' => 'adoption_admin',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'incidentadmin@telkomuniversity.ac.id',
                'name' => 'Admin Insiden (Optimind)',
                'role' => 'incident_admin',
                'user_type' => 'STAF',
            ],
            [
                'email' => 'caretaker@telkomuniversity.ac.id',
                'name' => 'Relawan Caretaker Kampus',
                'role' => 'caretaker',
                'user_type' => 'MAHASISWA',
            ],
        ];

        foreach ($usersData as $u) {
            $user = User::firstOrCreate(
                ['email' => $u['email']],
                [
                    'id' => (string) Str::ulid(),
                    'name' => $u['name'],
                    'password' => Hash::make('password'),
                    'user_type' => $u['user_type'],
                    'email_verified_at' => now(),
                    'is_active' => true,
                ]
            );

            // Assign Spatie Role
            $user->assignRole($u['role']);

            // Initialize Point Balance Cache
            DB::table('point_balances')->updateOrInsert(
                ['user_id' => $user->id],
                ['total_points' => 0, 'updated_at' => now()]
            );
        }

        // 4. Seed Initial Point Rules (Section 9.4)
        $pointRules = [
            [
                'rule_key' => 'feeding.verified',
                'module' => 'FeedingSpot',
                'points' => 10,
                'daily_cap_count' => 3,
                'daily_cap_points' => 60,
                'description' => 'Aktivitas pemberian pakan yang diverifikasi (5-20 poin)',
            ],
            [
                'rule_key' => 'game.tame.common',
                'module' => 'CatHunter',
                'points' => 10,
                'daily_cap_count' => 10,
                'daily_cap_points' => 100,
                'description' => 'Penjinakan kucing Common',
            ],
            [
                'rule_key' => 'game.tame.rare',
                'module' => 'CatHunter',
                'points' => 20,
                'daily_cap_count' => 10,
                'daily_cap_points' => 100,
                'description' => 'Penjinakan kucing Rare',
            ],
            [
                'rule_key' => 'game.tame.epic',
                'module' => 'CatHunter',
                'points' => 40,
                'daily_cap_count' => 10,
                'daily_cap_points' => 100,
                'description' => 'Penjinakan kucing Epic',
            ],
            [
                'rule_key' => 'game.fail',
                'module' => 'CatHunter',
                'points' => 2,
                'daily_cap_count' => 5,
                'daily_cap_points' => 10,
                'description' => 'Eksplorasi encounter kucing yang belum jinak',
            ],
            [
                'rule_key' => 'game.greet',
                'module' => 'CatHunter',
                'points' => 3,
                'daily_cap_count' => 3,
                'daily_cap_points' => 9,
                'description' => 'Menyapa kucing yang sudah masuk CatDex',
            ],
            [
                'rule_key' => 'incident.report',
                'module' => 'IncidentReport',
                'points' => 20,
                'daily_cap_count' => 3,
                'daily_cap_points' => 60,
                'description' => 'Laporan insiden yang telah diverifikasi admin',
            ],
        ];

        foreach ($pointRules as $pr) {
            DB::table('point_rules')->updateOrInsert(
                ['rule_key' => $pr['rule_key']],
                array_merge($pr, ['id' => (string) Str::ulid(), 'is_active' => true, 'created_at' => now(), 'updated_at' => now()])
            );
        }

        // 5. Seed Campus Territories
        $territories = [
            ['code' => 'TULT', 'name' => 'Telkom University Landmark Tower'],
            ['code' => 'GKU', 'name' => 'Gedung Kuliah Umum'],
            ['code' => 'FIT', 'name' => 'Fakultas Ilmu Terapan'],
            ['code' => 'ASRAMA_PA', 'name' => 'Asrama Putra'],
            ['code' => 'ASRAMA_PI', 'name' => 'Asrama Putri'],
        ];

        $territoryIds = [];
        foreach ($territories as $t) {
            $id = (string) Str::ulid();
            DB::table('territories')->updateOrInsert(
                ['code' => $t['code']],
                ['id' => $id, 'name' => $t['name'], 'created_at' => now(), 'updated_at' => now()]
            );
            $territoryIds[$t['code']] = $id;
        }

        // 6. Seed 20 Sample Cats with Collar QR Tokens
        $catNames = [
            'Oyen', 'Miko', 'Luna', 'Kuro', 'Simba',
            'Milo', 'Bella', 'Chiko', 'Cleo', 'Tiger',
            'Oreo', 'Mocha', 'Pusi', 'Boni', 'Kiki',
            'Ciko', 'Abu', 'Belang', 'Comel', 'Putih',
        ];

        foreach ($catNames as $index => $name) {
            $catId = (string) Str::ulid();
            $uniqueCode = 'CAT' . str_pad((string)($index + 1), 3, '0', STR_PAD_LEFT);
            $tCode = array_keys($territoryIds)[$index % count($territoryIds)];

            DB::table('cats')->updateOrInsert(
                ['unique_code' => $uniqueCode],
                [
                    'id' => $catId,
                    'name' => $name,
                    'gender' => $index % 2 === 0 ? 'MALE' : 'FEMALE',
                    'color_pattern' => $index % 3 === 0 ? 'Orange Tabby' : ($index % 3 === 1 ? 'Calico' : 'Tuxedo'),
                    'age_group' => $index % 4 === 0 ? 'KITTEN' : 'ADULT',
                    'is_sterilized' => $index % 2 === 0,
                    'description' => "Kucing kampus ramah yang sering bermain di area {$tCode}.",
                    'presence_status' => 'ON_CAMPUS',
                    'health_status' => 'HEALTHY',
                    'adoption_status' => $index === 0 ? 'READY' : 'UNREVIEWED',
                    'verification_status' => 'VERIFIED',
                    'territory_id' => $territoryIds[$tCode],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );

            // Active QR Token for collar
            $rawToken = Str::random(32);
            DB::table('cat_qr_tokens')->insert([
                'id' => (string) Str::ulid(),
                'cat_id' => $catId,
                'token' => $rawToken,
                'status' => 'ACTIVE',
                'issued_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 7. Seed 3 Sample Feeding Spots
        $spots = [
            [
                'code' => 'SPOT-TULT-01',
                'name' => 'Spot Pakan TULT Lobby',
                'description' => 'Titik makan resmi dekat lobby barat TULT',
                'latitude' => -6.9740000,
                'longitude' => 107.6300000,
                't_code' => 'TULT',
            ],
            [
                'code' => 'SPOT-GKU-01',
                'name' => 'Spot Pakan GKU Gazebo',
                'description' => 'Titik makan di sebelah gazebo barat GKU',
                'latitude' => -6.9730000,
                'longitude' => 107.6310000,
                't_code' => 'GKU',
            ],
            [
                'code' => 'SPOT-ASRP-01',
                'name' => 'Spot Pakan Asrama Putri',
                'description' => 'Titik makan samping pos satpam asrama putri',
                'latitude' => -6.9750000,
                'longitude' => 107.6290000,
                't_code' => 'ASRAMA_PI',
            ],
        ];

        foreach ($spots as $s) {
            $spotId = (string) Str::ulid();
            $qrToken = Str::random(32);

            DB::table('feeding_spots')->updateOrInsert(
                ['code' => $s['code']],
                [
                    'id' => $spotId,
                    'name' => $s['name'],
                    'description' => $s['description'],
                    'latitude' => $s['latitude'],
                    'longitude' => $s['longitude'],
                    'territory_id' => $territoryIds[$s['t_code']],
                    'qr_token' => $qrToken,
                    'status' => 'ACTIVE',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }
}
