<?php

namespace Tests\Feature\CatAdoption;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Models\AdoptionFollowup;
use App\Modules\CatAdoption\Models\AdoptionPickupLock;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * EN-9: skema dan model adoption_*.
 */
class AdoptionSchemaTest extends TestCase
{
    use RefreshDatabase;

    private function makeCat(): Cat
    {
        return Cat::create([
            'unique_code' => 'TST-' . Str::upper(Str::random(6)),
            'name' => 'Oyen',
        ]);
    }

    private function makeApplication(User $user, string $status = AdoptionApplication::STATUS_APPROVED): AdoptionApplication
    {
        return AdoptionApplication::create([
            'applicant_id' => $user->id,
            'housing_type' => 'KOS',
            'long_term_plan' => 'Rawat sampai lulus dan dibawa pulang.',
            'status' => $status,
        ]);
    }

    public function test_new_cat_defaults_to_unreviewed(): void
    {
        // FIX-05: kucing baru tidak otomatis siap diadopsi.
        $this->assertSame('UNREVIEWED', $this->makeCat()->fresh()->adoption_status);
    }

    public function test_application_can_be_draft_without_cat(): void
    {
        // FIX-06: aplikasi kelayakan tidak membutuhkan cat_id.
        $user = User::factory()->create();

        $app = AdoptionApplication::create([
            'applicant_id' => $user->id,
            'housing_type' => 'RUMAH',
            'long_term_plan' => 'Rencana jangka panjang.',
            'answers' => ['q1' => 'ya', 'q2' => ['a', 'b']],
        ])->fresh();

        $this->assertNull($app->cat_id);
        $this->assertSame(AdoptionApplication::STATUS_DRAFT, $app->status);
        $this->assertFalse($app->precheck_passed);
        $this->assertSame(['q1' => 'ya', 'q2' => ['a', 'b']], $app->answers);
        $this->assertTrue($app->isEditable());
        $this->assertTrue($app->applicant->is($user));
    }

    public function test_only_one_held_lock_per_cat(): void
    {
        $cat = $this->makeCat();
        [$a, $b] = User::factory()->count(2)->create();

        AdoptionPickupLock::create(['cat_id' => $cat->id, 'adopter_id' => $a->id, 'expires_at' => now()->addHours(48)]);

        $this->expectException(QueryException::class);
        AdoptionPickupLock::create(['cat_id' => $cat->id, 'adopter_id' => $b->id, 'expires_at' => now()->addHours(48)]);
    }

    public function test_only_one_held_lock_per_adopter(): void
    {
        $user = User::factory()->create();

        AdoptionPickupLock::create(['cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id, 'expires_at' => now()->addHours(48)]);

        $this->expectException(QueryException::class);
        AdoptionPickupLock::create(['cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id, 'expires_at' => now()->addHours(48)]);
    }

    public function test_released_lock_allows_new_hold(): void
    {
        $cat = $this->makeCat();
        [$a, $b] = User::factory()->count(2)->create();

        $first = AdoptionPickupLock::create(['cat_id' => $cat->id, 'adopter_id' => $a->id, 'expires_at' => now()->addHours(48)]);
        $first->update(['status' => AdoptionPickupLock::STATUS_RELEASED]);

        $second = AdoptionPickupLock::create(['cat_id' => $cat->id, 'adopter_id' => $b->id, 'expires_at' => now()->addHours(48)]);

        $this->assertSame(1, AdoptionPickupLock::active()->count());
        $this->assertTrue(AdoptionPickupLock::active()->first()->is($second));
    }

    public function test_only_one_open_adoption_per_cat(): void
    {
        $cat = $this->makeCat();
        [$a, $b] = User::factory()->count(2)->create();

        Adoption::create(['application_id' => $this->makeApplication($a)->id, 'cat_id' => $cat->id, 'adopter_id' => $a->id]);

        $this->expectException(QueryException::class);
        Adoption::create(['application_id' => $this->makeApplication($b)->id, 'cat_id' => $cat->id, 'adopter_id' => $b->id]);
    }

    public function test_only_one_open_adoption_per_adopter(): void
    {
        $user = User::factory()->create();
        $app = $this->makeApplication($user);

        Adoption::create(['application_id' => $app->id, 'cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id]);

        $this->expectException(QueryException::class);
        Adoption::create(['application_id' => $app->id, 'cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id]);
    }

    public function test_closed_adoption_frees_cat_and_adopter(): void
    {
        $cat = $this->makeCat();
        $user = User::factory()->create();
        $app = $this->makeApplication($user);

        $first = Adoption::create(['application_id' => $app->id, 'cat_id' => $cat->id, 'adopter_id' => $user->id]);
        $first->update(['status' => Adoption::STATUS_CLOSED_RETURNED, 'closed_at' => now()]);

        Adoption::create(['application_id' => $app->id, 'cat_id' => $cat->id, 'adopter_id' => $user->id]);

        $this->assertSame(1, Adoption::open()->count());
        $this->assertSame(2, Adoption::count());
    }

    public function test_adoption_in_return_process_still_binds_quota(): void
    {
        // ADP-12 / IT-12: selama pengembalian belum diverifikasi admin, kuota tetap terikat.
        $user = User::factory()->create();
        $app = $this->makeApplication($user);

        $first = Adoption::create(['application_id' => $app->id, 'cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id]);
        $first->update(['status' => Adoption::STATUS_RETURN_REQUESTED]);

        $this->expectException(QueryException::class);
        Adoption::create(['application_id' => $app->id, 'cat_id' => $this->makeCat()->id, 'adopter_id' => $user->id]);
    }

    public function test_followup_period_is_unique_per_adoption(): void
    {
        $user = User::factory()->create();
        $adoption = Adoption::create([
            'application_id' => $this->makeApplication($user)->id,
            'cat_id' => $this->makeCat()->id,
            'adopter_id' => $user->id,
        ]);

        AdoptionFollowup::create(['adoption_id' => $adoption->id, 'period_no' => 1, 'due_at' => now()->addDays(14)]);
        $this->assertSame(1, $adoption->followups()->count());

        $this->expectException(QueryException::class);
        AdoptionFollowup::create(['adoption_id' => $adoption->id, 'period_no' => 1, 'due_at' => now()->addDays(14)]);
    }

    public function test_answers_column_is_jsonb_on_postgres(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->markTestSkipped('Hanya berlaku di PostgreSQL.');
        }

        $type = DB::selectOne(
            "SELECT data_type FROM information_schema.columns WHERE table_name = 'adoption_applications' AND column_name = 'answers'"
        )->data_type;

        $this->assertSame('jsonb', $type);
    }
}
