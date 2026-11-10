<?php

namespace App\Modules\FeedingSpot\Commands;

use App\Modules\FeedingSpot\Database\Seeders\FeedingSettingSeeder;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Console\Command;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SetupLocalFeedingEnvironmentCommand extends Command
{
    protected $signature = 'feeding:setup-local';
    protected $description = 'Siapkan skema database lokal (termasuk tabel sessions/cache) dan data demo awal';

    public function handle(): int
    {
        config([
            'permission.column_names.role_pivot_key' => 'role_id',
            'permission.column_names.permission_pivot_key' => 'permission_id',
        ]);

        Artisan::call('migrate', ['--force' => true]);

        if (!Schema::hasTable('sessions')) {
            Schema::create('sessions', function (Blueprint $table) {
                $table->string('id')->primary();
                $table->string('user_id', 26)->nullable()->index();
                $table->string('ip_address', 45)->nullable();
                $table->text('user_agent')->nullable();
                $table->longText('payload');
                $table->integer('last_activity')->index();
            });
        }

        if (!Schema::hasTable('cache')) {
            Schema::create('cache', function (Blueprint $table) {
                $table->string('key')->primary();
                $table->mediumText('value');
                $table->integer('expiration');
            });
            Schema::create('cache_locks', function (Blueprint $table) {
                $table->string('key')->primary();
                $table->string('owner');
                $table->integer('expiration');
            });
        }

        if (DB::table('users')->count() === 0) {
            Artisan::call('db:seed', ['--class' => DatabaseSeeder::class, '--force' => true]);
        }

        Artisan::call('db:seed', ['--class' => FeedingSettingSeeder::class, '--force' => true]);
        Artisan::call('feeding:refresh-aggregates');

        $this->info('Database lokal & data demo Adopt Feeding Spot siap digunakan.');

        return self::SUCCESS;
    }
}
