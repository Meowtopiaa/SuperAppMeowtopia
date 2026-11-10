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
            $table->char('id', 26)->primary();
            $table->string('code')->unique();
            $table->string('question_text');
            $table->integer('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('cat_trait_answers', function (Blueprint $table) {
            $table->char('cat_id', 26);
            $table->char('question_id', 26);
            $table->string('answer'); // YES, NO
            $table->timestamps();

            $table->primary(['cat_id', 'question_id']);
            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('question_id')->references('id')->on('identification_questions')->cascadeOnDelete();
        });

        Schema::create('identification_attempts', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26)->nullable();
            $table->string('method'); // PHOTO, AKINATOR
            $table->string('model_version')->nullable();
            $table->char('input_media_id', 26)->nullable();
            $table->json('answers')->nullable();
            $table->json('candidates')->nullable();
            $table->string('result')->default('INCONCLUSIVE'); // MATCHED, INCONCLUSIVE, NOT_CAT
            $table->char('confirmed_cat_id', 26)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->nullOnDelete();
            $table->foreign('confirmed_cat_id')->references('id')->on('cats')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('identification_attempts');
        Schema::dropIfExists('cat_trait_answers');
        Schema::dropIfExists('identification_questions');
    }
};

