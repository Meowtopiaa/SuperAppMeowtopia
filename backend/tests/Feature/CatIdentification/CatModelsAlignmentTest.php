<?php

namespace Tests\Feature\CatIdentification;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use App\Modules\Cat\Models\CatStatusLog;
use App\Modules\CatIdentification\Models\CatPhoto;
use App\Modules\Core\Services\CatStatusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class CatModelsAlignmentTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);
    }

    protected function createUser(): User
    {
        $user = new User([
            'name' => 'Curator Test',
            'email' => Str::random(8) . '@telkomuniversity.ac.id',
            'password' => Hash::make('password'),
            'is_active' => true,
        ]);
        $user->user_type = 'STAF';
        $user->email_verified_at = now();
        $user->save();

        return $user;
    }

    protected function createMediaFile(User $owner): string
    {
        $mediaId = (string) Str::ulid();
        DB::table('media_files')->insert([
            'id' => $mediaId,
            'owner_id' => $owner->id,
            'disk' => 'local',
            'path' => 'cats/sample.jpg',
            'mime' => 'image/jpeg',
            'size_bytes' => 1024,
            'sha256' => hash('sha256', $mediaId),
            'purpose' => 'cat_photo',
            'visibility' => 'public',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $mediaId;
    }

    public function test_cat_models_use_ulid_and_default_three_independent_statuses(): void
    {
        $user = $this->createUser();
        $mediaId = $this->createMediaFile($user);

        $cat = Cat::create([
            'unique_code' => 'CAT-ALN-01',
            'name' => 'Oyen Alignment',
        ]);

        $this->assertSame(26, strlen($cat->id));
        $this->assertSame(Cat::PRESENCE_ON_CAMPUS, $cat->presence_status);
        $this->assertSame(Cat::HEALTH_HEALTHY, $cat->health_status);
        $this->assertSame(Cat::ADOPTION_UNREVIEWED, $cat->adoption_status);

        $badges = $cat->statusBadges();
        $this->assertSame('Di Kampus', $badges['presence']['label']);
        $this->assertSame('Sehat', $badges['health']['label']);
        $this->assertSame('Belum Siap Adopsi', $badges['adoption']['label']);

        $photo = CatPhoto::create([
            'cat_id' => $cat->id,
            'media_id' => $mediaId,
            'angle' => 'front',
            'sort_order' => 1,
        ]);
        $this->assertSame(26, strlen($photo->id));
        $this->assertSame($cat->id, $photo->cat->id);
        $this->assertCount(1, $cat->photos);

        $token = CatQrToken::create([
            'cat_id' => $cat->id,
            'token' => Str::random(32),
            'issued_by' => $user->id,
            'issued_at' => now(),
        ]);
        $this->assertSame(26, strlen($token->id));
        $this->assertTrue($token->isActive());
        $this->assertSame($user->id, $token->issuer->id);
        $this->assertSame($token->id, $cat->activeQrToken->id);

        app(CatStatusService::class)->change(
            $cat,
            CatStatusLog::DIMENSION_HEALTH,
            Cat::HEALTH_UNDER_CARE,
            $user,
            'IncidentReport',
            'Pemeriksaan rutin'
        );

        $log = $cat->statusLogs()->first();
        $this->assertNotNull($log);
        $this->assertSame(26, strlen($log->id));
        $this->assertSame(CatStatusLog::DIMENSION_HEALTH, $log->dimension);
        $this->assertSame(Cat::HEALTH_HEALTHY, $log->from_value);
        $this->assertSame(Cat::HEALTH_UNDER_CARE, $log->to_value);
        $this->assertSame($user->id, $log->actor->id);

        // Other two dimensions remain independent
        $cat->refresh();
        $this->assertSame(Cat::PRESENCE_ON_CAMPUS, $cat->presence_status);
        $this->assertSame(Cat::HEALTH_UNDER_CARE, $cat->health_status);
        $this->assertSame(Cat::ADOPTION_UNREVIEWED, $cat->adoption_status);

        // Query scopes
        $this->assertSame(1, Cat::onCampus()->count());
        $this->assertSame(0, Cat::readyForAdoption()->count());
    }
}
