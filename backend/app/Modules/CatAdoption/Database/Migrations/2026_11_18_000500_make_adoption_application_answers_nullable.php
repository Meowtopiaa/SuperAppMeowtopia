<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * EN-14 (ADP-02): jawaban ya/tidak di draf boleh belum diisi, agar submit bisa membedakan "belum dijawab" dari "tidak".
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->boolean('owner_permission')->nullable()->default(null)->change();
            $table->boolean('can_afford')->nullable()->default(null)->change();
        });
    }

    public function down(): void
    {
        DB::table('adoption_applications')->whereNull('owner_permission')->update(['owner_permission' => false]);
        DB::table('adoption_applications')->whereNull('can_afford')->update(['can_afford' => false]);

        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->boolean('owner_permission')->nullable(false)->default(false)->change();
            $table->boolean('can_afford')->nullable(false)->default(false)->change();
        });
    }
};
