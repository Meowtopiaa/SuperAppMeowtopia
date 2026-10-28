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
        Schema::create('feeding_spots', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique();
            $table->string('qr_token')->unique();
            $table->string('location_name');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('status')->default('active'); // active, maintenance, inactive
            $table->string('bowl_condition')->default('empty'); // empty, partially_filled, full, needs_cleaning
            $table->timestamp('last_fed_at')->nullable();
            $table->timestamps();
        });

        Schema::create('feeding_activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('feeding_spot_id')->constrained('feeding_spots')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('photo_proof_url')->nullable();
            $table->string('food_type')->default('dry_food');
            $table->text('notes')->nullable();
            $table->string('status')->default('verified');
            $table->integer('points_awarded')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('feeding_activities');
        Schema::dropIfExists('feeding_spots');
    }
};
