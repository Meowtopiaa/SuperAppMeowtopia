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
        // 1. Point Rules (Single ledger configuration owned by PM)
        Schema::create('point_rules', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('rule_key')->unique();
            $table->string('module'); // FeedingSpot, CatHunter, IncidentReport, Core
            $table->integer('points')->default(0);
            $table->integer('daily_cap_count')->default(5);
            $table->integer('daily_cap_points')->default(150);
            $table->boolean('is_active')->default(true);
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // 2. Point Transactions (Append-only Ledger)
        Schema::create('point_transactions', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->string('rule_key');
            $table->integer('points'); // positive for awards, negative for reversals
            $table->string('source_module');
            $table->string('source_type');
            $table->string('source_ref_id')->nullable();
            $table->string('idempotency_key')->unique();
            $table->string('status')->default('CREDITED'); // CREDITED, REVERSED
            $table->char('reversal_of', 26)->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->index(['user_id', 'created_at']);
        });

        // 3. Point Balances (Cache of Ledger)
        Schema::create('point_balances', function (Blueprint $table) {
            $table->char('user_id', 26)->primary();
            $table->integer('total_points')->default(0);
            $table->timestamp('updated_at')->useCurrent();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
        });

        // 4. Badges (P1)
        Schema::create('badges', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('module');
            $table->json('criteria')->nullable();
            $table->timestamps();
        });

        // 5. User Badges (P1)
        Schema::create('user_badges', function (Blueprint $table) {
            $table->char('id', 26)->primary();
            $table->char('user_id', 26);
            $table->char('badge_id', 26);
            $table->timestamp('awarded_at')->useCurrent();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('badge_id')->references('id')->on('badges')->cascadeOnDelete();
            $table->unique(['user_id', 'badge_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_badges');
        Schema::dropIfExists('badges');
        Schema::dropIfExists('point_balances');
        Schema::dropIfExists('point_transactions');
        Schema::dropIfExists('point_rules');
    }
};

