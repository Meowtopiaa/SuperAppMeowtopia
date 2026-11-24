<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * EN-9: Melengkapi tabel adoption_* sesuai PRD bagian 7 tanpa mengedit
 * migration skeleton 2026_01_01_000500 yang sudah di-merge.
 *
 * - Unik parsial: satu lock HELD per kucing dan per adopter (ADP-07).
 * - Unik parsial: satu adopsi yang belum ditutup per kucing dan per adopter (ADP-07, ADP-12).
 * - answers memakai jsonb (PRD bagian 7).
 * - Index pendukung antrean admin dan pencarian lock kedaluwarsa.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Satu media hanya ditautkan sekali ke satu aplikasi.
        Schema::table('adoption_application_media', function (Blueprint $table) {
            $table->unique(['application_id', 'media_id'], 'adoption_app_media_unique');
        });

        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->index(['applicant_id', 'status'], 'adoption_app_applicant_status_idx');
            $table->index(['status', 'submitted_at'], 'adoption_app_status_submitted_idx');
        });

        Schema::table('adoption_pickup_locks', function (Blueprint $table) {
            $table->index(['status', 'expires_at'], 'adoption_lock_status_expires_idx');
        });

        Schema::table('adoption_followups', function (Blueprint $table) {
            $table->index(['status', 'due_at'], 'adoption_followup_status_due_idx');
        });

        // Unik parsial (didukung PostgreSQL dan SQLite).
        DB::statement("CREATE UNIQUE INDEX adoption_lock_one_held_per_cat ON adoption_pickup_locks (cat_id) WHERE status = 'HELD'");
        DB::statement("CREATE UNIQUE INDEX adoption_lock_one_held_per_adopter ON adoption_pickup_locks (adopter_id) WHERE status = 'HELD'");
        DB::statement("CREATE UNIQUE INDEX adoption_one_open_per_cat ON adoptions (cat_id) WHERE status <> 'CLOSED_RETURNED'");
        DB::statement("CREATE UNIQUE INDEX adoption_one_open_per_adopter ON adoptions (adopter_id) WHERE status <> 'CLOSED_RETURNED'");

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE adoption_applications ALTER COLUMN answers TYPE jsonb USING answers::jsonb');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE adoption_applications ALTER COLUMN answers TYPE json USING answers::json');
        }

        DB::statement('DROP INDEX IF EXISTS adoption_one_open_per_adopter');
        DB::statement('DROP INDEX IF EXISTS adoption_one_open_per_cat');
        DB::statement('DROP INDEX IF EXISTS adoption_lock_one_held_per_adopter');
        DB::statement('DROP INDEX IF EXISTS adoption_lock_one_held_per_cat');

        Schema::table('adoption_followups', function (Blueprint $table) {
            $table->dropIndex('adoption_followup_status_due_idx');
        });

        Schema::table('adoption_pickup_locks', function (Blueprint $table) {
            $table->dropIndex('adoption_lock_status_expires_idx');
        });

        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->dropIndex('adoption_app_status_submitted_idx');
            $table->dropIndex('adoption_app_applicant_status_idx');
        });

        Schema::table('adoption_application_media', function (Blueprint $table) {
            $table->dropUnique('adoption_app_media_unique');
        });
    }
};
