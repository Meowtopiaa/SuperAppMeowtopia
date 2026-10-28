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
        Schema::create('incident_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('cat_id')->nullable()->constrained('cats')->nullOnDelete();
            $table->string('title');
            $table->string('incident_type'); // injured, severely_ill, trapped, abuse, missing
            $table->string('urgency_level')->default('medium'); // low, medium, high, critical
            $table->text('description');
            $table->string('photo_url')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->string('location_note')->nullable();
            $table->string('status')->default('reported'); // reported, dispatched, handling, resolved, rejected
            $table->text('resolver_notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('incident_reports');
    }
};
