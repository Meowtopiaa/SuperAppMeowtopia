<?php

namespace Tests\Feature\CatIdentification;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use App\Modules\CatIdentification\Events\CatQrRegenerated;
use App\Modules\CatIdentification\Models\IdentificationQuestion;
use App\Modules\CatIdentification\Services\CatQrService;
use App\Modules\Core\Services\ScanResolver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Tests\TestCase;

class CatAdminTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);
    }

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['cat.edit', 'cat.curate', 'cat.qr.regenerate'] as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'sanctum']);
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
        }

        $curatorRole = Role::firstOrCreate(['name' => 'data_curator', 'guard_name' => 'web']);
        $curatorRole->syncPermissions(
            Permission::whereIn('name', ['cat.edit', 'cat.curate', 'cat.qr.regenerate'])
                ->where('guard_name', 'web')
                ->get()
        );

        Role::firstOrCreate(['name' => 'user', 'guard_name' => 'web']);
    }

    protected function createUserWithRole(string $roleName): User
    {
        $user = new User([
            'name' => 'User ' . $roleName,
            'email' => Str::random(8) . '@telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->user_type = $roleName === 'user' ? 'MAHASISWA' : 'STAF';
        $user->email_verified_at = now();
        $user->save();

        $user->assignRole($roleName);

        return $user;
    }

    protected function createCatWithToken(string $uniqueCode = 'CAT001', string $name = 'Oyen'): Cat
    {
        $cat = Cat::create([
            'unique_code' => $uniqueCode,
            'name' => $name,
            'gender' => 'MALE',
            'color_pattern' => 'Orange Tabby',
            'age_group' => 'ADULT',
            'presence_status' => 'ON_CAMPUS',
            'health_status' => 'HEALTHY',
            'adoption_status' => 'UNREVIEWED',
            'verification_status' => 'VERIFIED',
        ]);

        app(CatQrService::class)->issueInitialToken($cat);

        return $cat;
    }

    public function test_regular_user_is_forbidden_from_all_admin_cat_endpoints(): void
    {
        $regularUser = $this->createUserWithRole('user');
        $cat = $this->createCatWithToken();
        $cat2 = $this->createCatWithToken('CAT002', 'Miko');
        $question = IdentificationQuestion::create([
            'code' => 'Q_ORANGE',
            'question_text' => 'Apakah bulunya dominan oranye?',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        Sanctum::actingAs($regularUser);

        $this->postJson('/api/v1/admin/cats', ['name' => 'Hacked'])->assertStatus(403);
        $this->patchJson("/api/v1/admin/cats/{$cat->id}", ['name' => 'Hacked'])->assertStatus(403);
        $this->postJson("/api/v1/admin/cats/{$cat->id}/qr/regenerate", ['reason' => 'Test'])->assertStatus(403);
        $this->getJson('/api/v1/admin/cats/qr-sheet')->assertStatus(403);
        $this->putJson("/api/v1/admin/cats/{$cat->id}/traits", [
            'traits' => [['question_id' => $question->id, 'answer' => 'YES']],
        ])->assertStatus(403);
        $this->postJson("/api/v1/admin/cats/{$cat->id}/merge", [
            'duplicate_cat_id' => $cat2->id,
            'reason' => 'Duplicate',
        ])->assertStatus(403);
    }

    public function test_curator_can_create_and_update_cat_without_direct_adoption_or_health_mutation(): void
    {
        $curator = $this->createUserWithRole('data_curator');
        Sanctum::actingAs($curator);

        $this->postJson('/api/v1/admin/cats', [])->assertStatus(422);

        $this->postJson('/api/v1/admin/cats', [
            'name' => 'Simba',
            'adoption_status' => 'READY',
        ])->assertStatus(422);

        $createRes = $this->postJson('/api/v1/admin/cats', [
            'unique_code' => 'CAT-NEW1',
            'name' => 'Simba',
            'gender' => 'MALE',
            'color_pattern' => 'Orange',
        ]);
        $createRes->assertStatus(201)
            ->assertJsonPath('data.unique_code', 'CAT-NEW1')
            ->assertJsonPath('data.presence_status', 'ON_CAMPUS')
            ->assertJsonPath('data.health_status', 'HEALTHY')
            ->assertJsonPath('data.adoption_status', 'UNREVIEWED');

        $catId = $createRes->json('data.id');
        $this->assertStringStartsWith('MTP1.C.', $createRes->json('data.active_qr.qr_payload'));

        $this->patchJson("/api/v1/admin/cats/{$catId}", [
            'adoption_status' => 'READY',
        ])->assertStatus(422);

        $this->patchJson('/api/v1/admin/cats/01NONEXISTENT0000000000000', [
            'name' => 'Ghost',
        ])->assertStatus(404);

        $this->patchJson("/api/v1/admin/cats/{$catId}", [
            'name' => 'Simba Updated',
            'presence_status' => 'MISSING',
            'status_reason' => 'Tidak terlihat selama 14 hari',
        ])->assertStatus(200)
            ->assertJsonPath('data.name', 'Simba Updated')
            ->assertJsonPath('data.presence_status', 'MISSING');

        $this->assertDatabaseHas('cat_status_logs', [
            'cat_id' => $catId,
            'dimension' => 'presence_status',
            'from_value' => 'ON_CAMPUS',
            'to_value' => 'MISSING',
            'source_module' => 'Cat',
        ]);
    }

    public function test_qr_regeneration_revokes_old_token_and_preserves_cat_id(): void
    {
        Event::fake([CatQrRegenerated::class]);

        $curator = $this->createUserWithRole('data_curator');
        $cat = $this->createCatWithToken('CAT500', 'Boni');
        $oldToken = $cat->activeQrToken()->firstOrFail();

        Sanctum::actingAs($curator);

        $this->postJson("/api/v1/admin/cats/{$cat->id}/qr/regenerate", [])
            ->assertStatus(422);

        $res = $this->postJson("/api/v1/admin/cats/{$cat->id}/qr/regenerate", [
            'reason' => 'Kalung hilang di dekat GKU',
        ]);

        $res->assertStatus(200)
            ->assertJsonPath('data.cat_id', $cat->id)
            ->assertJsonPath('data.status', 'ACTIVE');

        $newPayload = $res->json('data.qr_payload');
        $this->assertStringStartsWith('MTP1.C.', $newPayload);
        $this->assertNotEquals('MTP1.C.' . $oldToken->token, $newPayload);

        $this->assertEquals('REVOKED', $oldToken->fresh()->status);
        $this->assertEquals(1, CatQrToken::where('cat_id', $cat->id)->where('status', 'ACTIVE')->count());

        $resolver = app(ScanResolver::class);
        $resolved = $resolver->resolve($newPayload);
        $this->assertEquals('cat', $resolved['type']);
        $this->assertEquals($cat->id, $resolved['id']);

        Event::assertDispatched(CatQrRegenerated::class);

        $this->expectException(BadRequestHttpException::class);
        $resolver->resolve('MTP1.C.' . $oldToken->token);
    }

    public function test_qr_sheet_and_traits_and_merge_duplicate(): void
    {
        $curator = $this->createUserWithRole('data_curator');
        $primary = $this->createCatWithToken('CAT801', 'Putih');
        $duplicate = $this->createCatWithToken('CAT802', 'Putih Duplikat');

        DB::table('cat_sightings')->insert([
            'id' => (string) Str::ulid(),
            'cat_id' => $duplicate->id,
            'user_id' => $curator->id,
            'source' => 'manual_sighting',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $question = IdentificationQuestion::create([
            'code' => 'Q_WHITE',
            'question_text' => 'Apakah bulunya dominan putih?',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        Sanctum::actingAs($curator);

        $this->getJson('/api/v1/admin/cats/qr-sheet')
            ->assertStatus(200)
            ->assertJsonPath('data.total', 2);

        $this->putJson("/api/v1/admin/cats/{$primary->id}/traits", [
            'traits' => [
                ['question_id' => $question->id, 'answer' => 'YES'],
            ],
        ])->assertStatus(200);

        $this->assertDatabaseHas('cat_trait_answers', [
            'cat_id' => $primary->id,
            'question_id' => $question->id,
            'answer' => 'YES',
        ]);

        $this->postJson("/api/v1/admin/cats/{$primary->id}/merge", [
            'duplicate_cat_id' => $primary->id,
            'reason' => 'Self merge test',
        ])->assertStatus(409);

        $this->postJson("/api/v1/admin/cats/{$primary->id}/merge", [
            'duplicate_cat_id' => $duplicate->id,
            'reason' => 'Kucing yang sama terfoto dari sudut berbeda',
        ])->assertStatus(200)
            ->assertJsonPath('data.primary_cat_id', $primary->id)
            ->assertJsonPath('data.reassigned.sightings', 1);

        $this->assertSoftDeleted('cats', ['id' => $duplicate->id]);
        $this->assertDatabaseHas('cat_sightings', ['cat_id' => $primary->id]);
        $this->assertDatabaseHas('audit_logs', [
            'action' => 'cat.merged',
            'subject_id' => $primary->id,
        ]);
    }

    public function test_cats_import_artisan_command_validates_and_imports_csv(): void
    {
        $csvPath = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'meowtopia_cats_test_' . Str::random(6) . '.csv';
        $csvContent = implode("\n", [
            'unique_code,name,gender,color_pattern,age_group,is_sterilized,description',
            'CAT-IMP-1,Kuro,MALE,Black,ADULT,true,Kucing hitam di parkiran',
            'CAT-IMP-2,,FEMALE,Calico,KITTEN,false,Nama kosong harus gagal',
            'CAT-IMP-3,Cleo,FEMALE,Calico,KITTEN,false,Kucing calico jinak',
        ]);
        file_put_contents($csvPath, $csvContent);

        try {
            $this->artisan('cats:import', ['file' => $csvPath])
                ->assertSuccessful();

            $this->assertDatabaseHas('cats', [
                'unique_code' => 'CAT-IMP-1',
                'name' => 'Kuro',
                'presence_status' => 'ON_CAMPUS',
                'health_status' => 'HEALTHY',
                'adoption_status' => 'UNREVIEWED',
            ]);
            $this->assertDatabaseHas('cats', ['unique_code' => 'CAT-IMP-3', 'name' => 'Cleo']);
            $this->assertDatabaseMissing('cats', ['unique_code' => 'CAT-IMP-2']);
            $this->assertEquals(2, CatQrToken::where('status', 'ACTIVE')->count());
        } finally {
            @unlink($csvPath);
        }
    }

    public function test_docs_sample_and_invalid_csv_files_import_as_expected(): void
    {
        foreach (['TULT', 'GKU', 'FIT', 'ASRAMA_PA', 'ASRAMA_PI'] as $code) {
            DB::table('territories')->insert([
                'id' => (string) Str::ulid(),
                'code' => $code,
                'name' => 'Zona ' . $code,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        $sampleCsv = realpath(base_path('../docs/data/cats_import_sample.csv'));
        $invalidCsv = realpath(base_path('../docs/data/cats_import_invalid_sample.csv'));

        $this->assertNotFalse($sampleCsv);
        $this->assertNotFalse($invalidCsv);

        $this->artisan('cats:import', ['file' => $sampleCsv])
            ->expectsOutputToContain('12 kucing diimpor, 0 dilewati')
            ->assertSuccessful();

        $this->assertEquals(12, Cat::count());
        $this->assertEquals(12, CatQrToken::where('status', 'ACTIVE')->count());

        $this->artisan('cats:import', ['file' => $invalidCsv])
            ->expectsOutputToContain('1 kucing diimpor, 4 dilewati')
            ->assertSuccessful();

        $this->assertEquals(13, Cat::count());
    }
}
