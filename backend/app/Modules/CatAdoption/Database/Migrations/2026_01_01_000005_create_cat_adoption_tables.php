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
        Schema::create('adoption_applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('cat_id')->constrained('cats')->cascadeOnDelete();
            $table->string('status')->default('submitted'); // submitted, reviewing, approved, rejected, handed_over
            $table->string('housing_type');
            $table->boolean('financial_readiness')->default(false);
            $table->boolean('family_permission')->default(false);
            $table->json('commitment_answers')->nullable();
            $table->text('admin_notes')->nullable();
            $table->timestamp('handed_over_at')->nullable();
            $table->timestamps();
        });

        Schema::create('adoption_followups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('adoption_application_id')->constrained('adoption_applications')->cascadeOnDelete();
            $table->integer('period_number')->default(1);
            $table->string('photo_proof_url')->nullable();
            $table->text('condition_notes');
            $table->string('health_condition')->default('good');
            $table->string('status')->default('submitted');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('adoption_followups');
        Schema::dropIfExists('adoption_applications');
    }
};
