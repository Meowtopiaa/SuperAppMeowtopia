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
        // 1. Adoption Applications (Eligibility application, can be draft without cat_id)
        Schema::create('adoption_applications', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('applicant_id', 26);
            $table->char('cat_id', 26)->nullable();
            $table->string('housing_type');
            $table->boolean('owner_permission')->default(false);
            $table->boolean('can_afford')->default(false);
            $table->text('long_term_plan');
            $table->json('answers')->nullable();
            $table->string('commitment_version')->default('1.0');
            $table->timestamp('commitment_accepted_at')->nullable();
            $table->boolean('precheck_passed')->default(false);
            $table->string('status')->default('DRAFT'); // DRAFT, SUBMITTED, REVISION_REQUESTED, APPROVED, REJECTED
            $table->timestamp('submitted_at')->nullable();
            $table->char('reviewed_by', 26)->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->text('review_note')->nullable();
            $table->timestamps();

            $table->foreign('applicant_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->nullOnDelete();
            $table->foreign('reviewed_by')->references('id')->on('users')->nullOnDelete();
        });

        // 2. Private Housing & Evidence Media
        Schema::create('adoption_application_media', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('application_id', 26);
            $table->char('media_id', 26);
            $table->timestamps();

            $table->foreign('application_id')->references('id')->on('adoption_applications')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->cascadeOnDelete();
        });

        // 3. Pickup Locks (48h temporary hold during handover)
        Schema::create('adoption_pickup_locks', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('cat_id', 26);
            $table->char('adopter_id', 26);
            $table->timestamp('expires_at');
            $table->string('status')->default('HELD'); // HELD, RELEASED, USED
            $table->timestamps();

            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('adopter_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 4. Adoptions (Active adopted records)
        Schema::create('adoptions', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('application_id', 26);
            $table->char('cat_id', 26);
            $table->char('adopter_id', 26);
            $table->string('status')->default('ACTIVE'); // ACTIVE, RETURN_REQUESTED, RETURN_APPROVED, RETURN_EVIDENCE_PENDING, CLOSED_RETURNED
            $table->timestamp('picked_up_at')->useCurrent();
            $table->char('pickup_media_id', 26)->nullable();
            $table->string('pickup_location')->nullable();
            $table->timestamp('trial_ends_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamp('rehome_cooldown_until')->nullable();
            $table->timestamps();

            $table->foreign('application_id')->references('id')->on('adoption_applications')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->cascadeOnDelete();
            $table->foreign('adopter_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('pickup_media_id')->references('id')->on('media_files')->nullOnDelete();
        });

        // 5. Adoption Followups (Bi-weekly monitoring)
        Schema::create('adoption_followups', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('adoption_id', 26);
            $table->integer('period_no');
            $table->timestamp('due_at');
            $table->timestamp('submitted_at')->nullable();
            $table->text('condition_note')->nullable();
            $table->text('issue_note')->nullable();
            $table->char('media_id', 26)->nullable();
            $table->string('status')->default('PENDING'); // PENDING, SUBMITTED, LATE, REVIEWED
            $table->timestamps();

            $table->unique(['adoption_id', 'period_no']);
            $table->foreign('adoption_id')->references('id')->on('adoptions')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->nullOnDelete();
        });

        // 6. Adoption Returns
        Schema::create('adoption_returns', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('adoption_id', 26);
            $table->string('type')->default('REGULAR'); // REGULAR, EMERGENCY
            $table->text('reason');
            $table->string('status')->default('PENDING'); // PENDING, APPROVED, REJECTED, VERIFIED
            $table->char('proof_media_id', 26)->nullable();
            $table->string('return_location')->nullable();
            $table->char('verified_by', 26)->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();

            $table->foreign('adoption_id')->references('id')->on('adoptions')->cascadeOnDelete();
            $table->foreign('proof_media_id')->references('id')->on('media_files')->nullOnDelete();
            $table->foreign('verified_by')->references('id')->on('users')->nullOnDelete();
        });

        // 7. Adoption Issues
        Schema::create('adoption_issues', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('adoption_id', 26);
            $table->string('type');
            $table->text('description');
            $table->char('media_id', 26)->nullable();
            $table->string('status')->default('OPEN');
            $table->char('handled_by', 26)->nullable();
            $table->char('incident_report_id', 26)->nullable();
            $table->timestamps();

            $table->foreign('adoption_id')->references('id')->on('adoptions')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->nullOnDelete();
            $table->foreign('handled_by')->references('id')->on('users')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('adoption_issues');
        Schema::dropIfExists('adoption_returns');
        Schema::dropIfExists('adoption_followups');
        Schema::dropIfExists('adoptions');
        Schema::dropIfExists('adoption_pickup_locks');
        Schema::dropIfExists('adoption_application_media');
        Schema::dropIfExists('adoption_applications');
    }
};

