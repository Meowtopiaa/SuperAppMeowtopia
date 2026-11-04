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
        // 1. Cats Master Table (Single truth, ULID, 3 independent statuses, no precise coordinate columns)
        Schema::create('cats', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('unique_code')->unique(); // Printed collar code
            $table->string('name');
            $table->string('gender')->default('UNKNOWN'); // MALE, FEMALE, UNKNOWN
            $table->string('color_pattern')->nullable();
            $table->string('age_group')->default('UNKNOWN'); // KITTEN, ADULT, SENIOR, UNKNOWN
            $table->boolean('is_sterilized')->nullable();
            $table->text('description')->nullable();
            $table->json('traits')->nullable();
            $table->char('territory_id', 26)->nullable();
            $table->char('primary_photo_media_id', 26)->nullable();

            // 3 Independent Dimensions of Status
            $table->string('presence_status')->default('ON_CAMPUS'); // ON_CAMPUS, ADOPTED, MISSING, DECEASED
            $table->string('health_status')->default('HEALTHY'); // HEALTHY, SICK, INJURED, UNDER_CARE
            $table->string('adoption_status')->default('UNREVIEWED'); // UNREVIEWED, READY, ADOPTED, RETURN_PENDING, RETURNED_REVIEW

            $table->string('verification_status')->default('VERIFIED'); // UNVERIFIED, VERIFIED
            $table->timestamp('first_seen_at')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('territory_id')->references('id')->on('territories')->nullOnDelete();
            $table->foreign('primary_photo_media_id')->references('id')->on('media_files')->nullOnDelete();
        });

        // 2. Reference Photos
        Schema::create('cat_photos', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('cat_id', 26);
            $table->char('media_id', 26);
            $table->string('angle')->nullable(); // front, left, right, tail, face
            $table->integer('sort_order')->default(0);
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->cascadeOnDelete();
        });

        // 3. Cat QR Tokens (Separated from cats table, one active per cat)
        Schema::create('cat_qr_tokens', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('cat_id', 26);
            $table->string('token', 64)->unique();
            $table->string('status')->default('ACTIVE'); // ACTIVE, REVOKED
            $table->char('issued_by', 26)->nullable();
            $table->timestamp('issued_at')->useCurrent();
            $table->timestamp('revoked_at')->nullable();
            $table->text('revoked_reason')->nullable();
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('issued_by')->references('id')->on('users')->nullOnDelete();
        });

        // 4. Cat Sightings (Single log for encounters, feeding, adoption pickup/return)
        Schema::create('cat_sightings', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('cat_id', 26)->nullable();
            $table->char('user_id', 26);
            $table->string('source'); // encounter, feeding, adoption_pickup, adoption_return, manual_sighting
            $table->string('request_id')->nullable();
            $table->decimal('location_lat', 10, 7)->nullable();
            $table->decimal('location_lng', 10, 7)->nullable();
            $table->decimal('accuracy_m', 8, 2)->nullable();
            $table->char('token_id', 26)->nullable();
            $table->timestamp('occurred_at')->useCurrent();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->nullOnDelete();
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['cat_id', 'occurred_at']);
        });

        // 5. Unidentified Sightings (Curation queue for unknown cats)
        Schema::create('unidentified_sightings', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('reporter_id', 26);
            $table->char('media_id', 26)->nullable();
            $table->decimal('location_lat', 10, 7)->nullable();
            $table->decimal('location_lng', 10, 7)->nullable();
            $table->text('notes')->nullable();
            $table->string('source'); // IDENTIFY_FAILED, AKINATOR_FAILED, INCIDENT_NEW_CAT
            $table->char('incident_report_id', 26)->nullable();
            $table->string('status')->default('OPEN'); // OPEN, MATCHED, CAT_CREATED, REJECTED
            $table->char('matched_cat_id', 26)->nullable();
            $table->char('handled_by', 26)->nullable();
            $table->timestamp('handled_at')->nullable();
            $table->timestamps();

            $table->foreign('reporter_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->nullOnDelete();
            $table->foreign('matched_cat_id')->references('id')->on('cats')->nullOnDelete();
            $table->foreign('handled_by')->references('id')->on('users')->nullOnDelete();
        });

        // 6. Cat Status Logs (Audit trail for 3 status dimensions)
        Schema::create('cat_status_logs', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('cat_id', 26);
            $table->string('dimension'); // presence_status, health_status, adoption_status
            $table->string('from_value');
            $table->string('to_value');
            $table->text('reason')->nullable();
            $table->char('actor_id', 26)->nullable();
            $table->string('source_module');
            $table->string('ref_type')->nullable();
            $table->string('ref_id')->nullable();
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('actor_id')->references('id')->on('users')->nullOnDelete();
            $table->index(['cat_id', 'dimension', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cat_status_logs');
        Schema::dropIfExists('unidentified_sightings');
        Schema::dropIfExists('cat_sightings');
        Schema::dropIfExists('cat_qr_tokens');
        Schema::dropIfExists('cat_photos');
        Schema::dropIfExists('cats');
    }
};

