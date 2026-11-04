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
        // 1. Feeding Spots
        Schema::create('feeding_spots', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('code')->unique();
            $table->string('name');
            $table->text('description')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->char('territory_id', 26)->nullable();
            $table->string('qr_token')->unique();
            $table->string('status')->default('ACTIVE'); // ACTIVE, TEMPORARILY_UNAVAILABLE, INACTIVE
            $table->timestamps();

            $table->foreign('territory_id')->references('id')->on('territories')->nullOnDelete();
        });

        // 2. Feeding Spot Cats Mapping
        Schema::create('feeding_spot_cats', function (Blueprint $table) {
            $table->char('spot_id', 26);
            $table->char('cat_id', 26);
            $table->timestamps();

            $table->primary(['spot_id', 'cat_id']);
            $table->foreign('spot_id')->references('id')->on('feeding_spots')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
        });

        // 3. Feeding Activities (Session-based, no GPS verification, location copied from spot)
        Schema::create('feeding_activities', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('feeding_record_ref')->unique();
            $table->char('user_id', 26);
            $table->char('spot_id', 26);
            $table->decimal('location_lat', 10, 7);
            $table->decimal('location_lng', 10, 7);
            $table->string('status')->default('DRAFT'); // DRAFT, SUBMITTED, UNDER_REVIEW, VERIFIED, REJECTED, EXPIRED
            $table->timestamp('scanned_at')->useCurrent();
            $table->timestamp('intent_at')->nullable();
            $table->timestamp('intent_deadline_at')->nullable();
            $table->timestamp('finalize_deadline_at')->nullable();
            $table->timestamp('finalized_at')->nullable();
            $table->string('food_type')->default('dry_food');
            $table->string('food_amount')->nullable();
            $table->char('cat_id', 26)->nullable();
            $table->string('reward_status')->default('PENDING'); // NOT_ELIGIBLE, PENDING, CREDITED, FAILED, REVERSED
            $table->integer('potential_points')->default(0);
            $table->json('reward_snapshot')->nullable();
            $table->json('flags')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('spot_id')->references('id')->on('feeding_spots')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->nullOnDelete();
        });

        // 4. Feeding Evidence Photos
        Schema::create('feeding_evidence', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('activity_id', 26);
            $table->char('media_id', 26);
            $table->timestamp('captured_at')->useCurrent();
            $table->integer('sort_order')->default(0);
            $table->timestamps();

            $table->foreign('activity_id')->references('id')->on('feeding_activities')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->cascadeOnDelete();
        });

        // 5. Feeding Rule Results
        Schema::create('feeding_rule_results', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('activity_id', 26);
            $table->string('rule');
            $table->string('result'); // PASS, REVIEW, FAIL
            $table->text('detail')->nullable();
            $table->timestamps();

            $table->foreign('activity_id')->references('id')->on('feeding_activities')->cascadeOnDelete();
        });

        // 6. Feeding Reviews
        Schema::create('feeding_reviews', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('activity_id', 26);
            $table->char('reviewer_id', 26);
            $table->string('decision'); // VERIFIED, REJECTED
            $table->text('reason')->nullable();
            $table->timestamps();

            $table->foreign('activity_id')->references('id')->on('feeding_activities')->cascadeOnDelete();
            $table->foreign('reviewer_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 7. Feeding Aggregates (14-day window coverage)
        Schema::create('feeding_aggregates', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('spot_id', 26);
            $table->timestamp('window_start');
            $table->timestamp('window_end');
            $table->integer('verified_count')->default(0);
            $table->integer('pending_count')->default(0);
            $table->timestamp('computed_at')->useCurrent();
            $table->timestamps();

            $table->foreign('spot_id')->references('id')->on('feeding_spots')->cascadeOnDelete();
        });

        // 8. Feeding Settings
        Schema::create('feeding_settings', function (Blueprint $table) {
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
        Schema::dropIfExists('feeding_settings');
        Schema::dropIfExists('feeding_aggregates');
        Schema::dropIfExists('feeding_reviews');
        Schema::dropIfExists('feeding_rule_results');
        Schema::dropIfExists('feeding_evidence');
        Schema::dropIfExists('feeding_activities');
        Schema::dropIfExists('feeding_spot_cats');
        Schema::dropIfExists('feeding_spots');
    }
};

