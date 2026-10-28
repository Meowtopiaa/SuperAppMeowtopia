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
        Schema::create('identification_questions', function (Blueprint $table) {
            $table->id();
            $table->string('question_text');
            $table->string('trait_category');
            $table->json('options');
            $table->integer('order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('identification_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('matched_cat_id')->nullable()->constrained('cats')->nullOnDelete();
            $table->string('photo_path')->nullable();
            $table->json('answers')->nullable();
            $table->decimal('confidence_score', 5, 2)->default(0);
            $table->string('method')->default('questionnaire'); // qr, photo_ai, questionnaire
            $table->string('status')->default('inconclusive'); // confirmed, rejected, inconclusive
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('identification_attempts');
        Schema::dropIfExists('identification_questions');
    }
};
