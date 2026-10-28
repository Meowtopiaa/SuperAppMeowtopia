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
        Schema::create('cat_encounters', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('cat_id')->constrained('cats')->cascadeOnDelete();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('reported_condition');
            $table->integer('turns_count')->default(1);
            $table->string('encounter_result')->default('captured'); // captured, fled, timed_out
            $table->integer('affinity_points')->default(0);
            $table->timestamps();
        });

        Schema::create('user_cat_dex', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('cat_id')->constrained('cats')->cascadeOnDelete();
            $table->integer('encounters_count')->default(1);
            $table->integer('friendship_level')->default(1);
            $table->timestamp('first_captured_at')->useCurrent();
            $table->timestamp('last_interacted_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'cat_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_cat_dex');
        Schema::dropIfExists('cat_encounters');
    }
};
