<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('feeding_spots')) {
            Schema::table('feeding_spots', function (Blueprint $table) {
                if (!Schema::hasColumn('feeding_spots', 'photo_media_id')) {
                    $table->char('photo_media_id', 26)->nullable()->after('status_reason');
                    $table->foreign('photo_media_id')->references('id')->on('media_files')->nullOnDelete();
                }
                if (!Schema::hasColumn('feeding_spots', 'photo_path')) {
                    $table->string('photo_path', 500)->nullable()->after('photo_media_id');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('feeding_spots')) {
            Schema::table('feeding_spots', function (Blueprint $table) {
                if (Schema::hasColumn('feeding_spots', 'photo_media_id')) {
                    $table->dropForeign(['photo_media_id']);
                    $table->dropColumn('photo_media_id');
                }
                if (Schema::hasColumn('feeding_spots', 'photo_path')) {
                    $table->dropColumn('photo_path');
                }
            });
        }
    }
};
