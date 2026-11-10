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
        // 1. Territories (Kampus Zones)
        Schema::create('territories', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('code')->unique();
            $table->string('name');
            $table->text('area')->nullable();
            $table->timestamps();
        });

        // 2. Users (Core Master User with ULID)
        Schema::create('users', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('name');
            $table->string('email')->unique();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password');
            $table->string('user_type')->default('MAHASISWA'); // MAHASISWA, DOSEN, STAF
            $table->string('identity_number')->nullable();
            $table->string('phone')->nullable();
            $table->char('avatar_media_id', 26)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_login_at')->nullable();
            $table->rememberToken();
            $table->timestamps();
            $table->softDeletes();
        });

        // 3. Sanctum Personal Access Tokens (compatible with ULID tokenable)
        Schema::create('personal_access_tokens', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('tokenable_type');
            $table->char('tokenable_id', 26);
            $table->string('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['tokenable_type', 'tokenable_id']);
        });

        // 4. Email OTPs (Verification)
        Schema::create('email_otps', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->string('code_hash');
            $table->timestamp('expires_at');
            $table->integer('attempts')->default(0);
            $table->timestamp('used_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 5. Device Tokens (FCM Push)
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->string('token')->unique();
            $table->string('platform')->default('android');
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 6. Notifications (In-app database channel with status delivery)
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type');
            $table->string('notifiable_type');
            $table->char('notifiable_id', 26);
            $table->text('data');
            $table->string('status')->default('QUEUED'); // QUEUED, SENT, FAILED, READ
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['notifiable_type', 'notifiable_id']);
        });

        // 7. Media Files (Private object storage tracking)
        Schema::create('media_files', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('owner_id', 26);
            $table->string('disk')->default('local');
            $table->string('path');
            $table->string('mime');
            $table->unsignedBigInteger('size_bytes');
            $table->string('sha256', 64)->index();
            $table->string('purpose'); // avatar, feeding_proof, adoption_evidence, incident_media, cat_photo
            $table->string('visibility')->default('private'); // private, public
            $table->string('related_type')->nullable();
            $table->char('related_id', 26)->nullable();
            $table->timestamp('captured_at')->nullable();
            $table->timestamp('retention_until')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->foreign('owner_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 8. Idempotency Keys
        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->string('key');
            $table->string('route');
            $table->string('request_hash');
            $table->integer('response_code');
            $table->json('response_body');
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->unique(['user_id', 'key', 'route']);
            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 9. Audit Logs
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('actor_id', 26)->nullable();
            $table->string('action');
            $table->string('subject_type')->nullable();
            $table->char('subject_id', 26)->nullable();
            $table->string('result')->default('SUCCESS');
            $table->text('reason')->nullable();
            $table->timestamps();

            $table->foreign('actor_id')->references('id')->on('users')->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('media_files');
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('device_tokens');
        Schema::dropIfExists('email_otps');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('users');
        Schema::dropIfExists('territories');
    }
};

