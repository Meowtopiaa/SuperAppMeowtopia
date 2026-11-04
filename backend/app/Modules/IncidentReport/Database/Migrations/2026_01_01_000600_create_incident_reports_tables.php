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
        // 1. Caretaker Profiles (Volunteers available for emergency response)
        Schema::create('caretaker_profiles', function (Blueprint $table) {
            $table->char('user_id', 26)->primary();
            $table->boolean('is_available')->default(true);
            $table->string('phone')->nullable();
            $table->json('territory_ids')->nullable();
            $table->decimal('last_location_lat', 10, 7)->nullable();
            $table->decimal('last_location_lng', 10, 7)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 2. Vet Contacts (Partner clinics/doctors - data only, not login)
        Schema::create('vet_contacts', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('name');
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->string('whatsapp')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('open_hours')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 3. Incident Reports (Single truth for physical campus incidents)
        Schema::create('incident_reports', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('ticket_code')->unique();
            $table->char('reporter_id', 26);
            $table->char('cat_id', 26)->nullable();
            $table->string('category'); // SICK, INJURED, MISSING, FOUND, AGGRESSIVE, DECEASED, NEW_CAT, DAMAGED_QR, OTHER
            $table->string('urgency')->default('MEDIUM'); // LOW, MEDIUM, HIGH
            $table->text('description');
            $table->decimal('location_lat', 10, 7);
            $table->decimal('location_lng', 10, 7);
            $table->text('location_note')->nullable();
            $table->char('territory_id', 26)->nullable();
            $table->string('source')->default('DIRECT'); // DIRECT, GAME, PROFILE, ADOPTION
            $table->string('source_ref')->nullable();
            $table->string('status')->default('RECEIVED'); // RECEIVED, WAITING_ASSIGNMENT, ASSIGNED, IN_PROGRESS, RESOLVED, CLOSED, REJECTED, DUPLICATE
            $table->char('assigned_to', 26)->nullable();
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->text('resolution_note')->nullable();
            $table->string('notification_status')->default('PENDING'); // NOT_REQUESTED, PENDING, SENT, FAILED
            $table->timestamps();

            $table->foreign('reporter_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('cat_id')->references('id')->on('cats')->nullOnDelete();
            $table->foreign('territory_id')->references('id')->on('territories')->nullOnDelete();
            $table->foreign('assigned_to')->references('id')->on('users')->nullOnDelete();
            $table->index(['status', 'urgency']);
        });

        // 4. Incident Media
        Schema::create('incident_media', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('incident_id', 26);
            $table->char('media_id', 26);
            $table->timestamps();

            $table->foreign('incident_id')->references('id')->on('incident_reports')->cascadeOnDelete();
            $table->foreign('media_id')->references('id')->on('media_files')->cascadeOnDelete();
        });

        // 5. Incident Status Logs
        Schema::create('incident_status_logs', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('incident_id', 26);
            $table->string('from_status');
            $table->string('to_status');
            $table->char('actor_id', 26)->nullable();
            $table->text('note')->nullable();
            $table->timestamps();

            $table->foreign('incident_id')->references('id')->on('incident_reports')->cascadeOnDelete();
            $table->foreign('actor_id')->references('id')->on('users')->nullOnDelete();
        });

        // 6. Incident Assignments (Caretaker dispatch)
        Schema::create('incident_assignments', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('incident_id', 26);
            $table->char('caretaker_id', 26);
            $table->char('assigned_by', 26);
            $table->string('status')->default('OFFERED'); // OFFERED, ACCEPTED, DECLINED, DONE
            $table->timestamp('responded_at')->nullable();
            $table->timestamps();

            $table->foreign('incident_id')->references('id')->on('incident_reports')->cascadeOnDelete();
            $table->foreign('caretaker_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('assigned_by')->references('id')->on('users')->cascadeOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('incident_assignments');
        Schema::dropIfExists('incident_status_logs');
        Schema::dropIfExists('incident_media');
        Schema::dropIfExists('incident_reports');
        Schema::dropIfExists('vet_contacts');
        Schema::dropIfExists('caretaker_profiles');
    }
};

