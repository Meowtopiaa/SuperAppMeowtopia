<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('feeding_spot_qr_tokens')) {
            Schema::create('feeding_spot_qr_tokens', function (Blueprint $table) {
                $table->char('id', 26)->primary();
                $table->char('spot_id', 26);
                $table->string('token')->unique();
                $table->string('status', 32)->default('ACTIVE'); // ACTIVE, REVOKED
                $table->char('issued_by', 26)->nullable();
                $table->timestamp('issued_at')->useCurrent();
                $table->timestamp('revoked_at')->nullable();
                $table->string('revoked_reason', 500)->nullable();
                $table->timestamps();

                $table->foreign('spot_id')->references('id')->on('feeding_spots')->cascadeOnDelete();
                $table->index(['spot_id', 'status']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('feeding_spot_qr_tokens');
    }
};
