<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('feeding_spot_histories')) {
            Schema::create('feeding_spot_histories', function (Blueprint $table) {
                $table->char('id', 26)->primary();
                $table->char('spot_id', 26);
                $table->char('actor_id', 26)->nullable();
                $table->string('action', 64); // CREATED, UPDATED, DEACTIVATED, REACTIVATED, MARKED_UNAVAILABLE, QR_REGENERATED
                $table->json('changes')->nullable();
                $table->string('reason', 500)->nullable();
                $table->timestamps();

                $table->foreign('spot_id')->references('id')->on('feeding_spots')->cascadeOnDelete();
                $table->foreign('actor_id')->references('id')->on('users')->nullOnDelete();
                $table->index(['spot_id', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('feeding_spot_histories');
    }
};
