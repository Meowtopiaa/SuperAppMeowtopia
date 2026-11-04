<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Game Cat Profiles (Cat Hunter specific metadata)
        Schema::create('game_cat_profiles', function (Blueprint $table) {
            $table->char('cat_id', 26)->primary();
            $table->string('rarity')->default('COMMON'); // COMMON, RARE, EPIC
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
        });

        // 2. Encounters (Turn-based interactive collection game)
        Schema::create('cat_encounters', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->char('cat_id', 26);
            $table->string('mood')->default('CALM'); // CALM, PLAYFUL, SHY, AGGRESSIVE
            $table->integer('trust')->default(0);
            $table->integer('turn_count')->default(0);
            $table->string('status')->default('ACTIVE'); // ACTIVE, TAMED, FAILED, ESCAPED, EXPIRED
            $table->timestamp('started_at')->useCurrent();
            $table->timestamp('ended_at')->nullable();
            $table->decimal('location_lat', 10, 7)->nullable();
            $table->decimal('location_lng', 10, 7)->nullable();
            $table->integer('points_awarded')->default(0);
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
        });

        // 3. Encounter Turns
        Schema::create('cat_encounter_turns', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('encounter_id', 26);
            $table->integer('turn_no');
            $table->string('action'); // PET, LEAVE
            $table->integer('trust_after');
            $table->timestamps();

            $table->foreign('encounter_id')->references('id')->on('cat_encounters')->cascadeOnDelete();
        });

        // 4. User Cat Dex (Collection)
        Schema::create('user_cat_dex', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->char('cat_id', 26);
            $table->string('state')->default('SEEN'); // SEEN, TAMED
            $table->timestamp('tamed_at')->nullable();
            $table->integer('times_encountered')->default(1);
            $table->timestamp('last_greeted_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'cat_id']);
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
        });

        // 5. Game Settings
        Schema::create('game_settings', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->json('value');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('game_settings');
        Schema::dropIfExists('user_cat_dex');
        Schema::dropIfExists('cat_encounter_turns');
        Schema::dropIfExists('cat_encounters');
        Schema::dropIfExists('game_cat_profiles');
    }
};

