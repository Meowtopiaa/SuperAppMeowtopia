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
        Schema::create('cats', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('qr_code_token')->unique()->index();
            $table->enum('gender', ['male', 'female']);
            $table->string('breed')->default('Domestik');
            $table->string('primary_color')->nullable();
            $table->string('pattern')->nullable(); // calico, tuxedo, tabby, etc.
            $table->boolean('sterilization_status')->default(false);
            $table->string('health_status')->default('healthy'); // healthy, under_treatment, critical
            $table->string('adoption_status')->default('available'); // available, pending, adopted, not_for_adoption
            $table->text('description')->nullable();
            $table->string('primary_photo_url')->nullable();
            $table->json('gallery_photos')->nullable();
            $table->decimal('last_seen_lat', 10, 7)->nullable();
            $table->decimal('last_seen_lng', 10, 7)->nullable();
            $table->string('last_seen_location_name')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cats');
    }
};
