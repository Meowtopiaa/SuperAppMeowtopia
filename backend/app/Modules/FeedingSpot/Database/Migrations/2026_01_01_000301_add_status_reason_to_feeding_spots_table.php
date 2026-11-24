<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('feeding_spots') && !Schema::hasColumn('feeding_spots', 'status_reason')) {
            Schema::table('feeding_spots', function (Blueprint $table) {
                $table->string('status_reason', 500)->nullable()->after('status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('feeding_spots') && Schema::hasColumn('feeding_spots', 'status_reason')) {
            Schema::table('feeding_spots', function (Blueprint $table) {
                $table->dropColumn('status_reason');
            });
        }
    }
};

