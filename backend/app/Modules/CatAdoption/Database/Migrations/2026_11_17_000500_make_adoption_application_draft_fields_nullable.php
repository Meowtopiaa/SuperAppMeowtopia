<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * EN-10 (FIX-06, ADP-02): draf kelayakan boleh disimpan belum lengkap.
 * Kelengkapan diperiksa saat submit (precheck), bukan saat simpan draf.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->string('housing_type')->nullable()->change();
            $table->text('long_term_plan')->nullable()->change();
        });
    }

    public function down(): void
    {
        DB::table('adoption_applications')->whereNull('housing_type')->update(['housing_type' => '']);
        DB::table('adoption_applications')->whereNull('long_term_plan')->update(['long_term_plan' => '']);

        Schema::table('adoption_applications', function (Blueprint $table) {
            $table->string('housing_type')->nullable(false)->change();
            $table->text('long_term_plan')->nullable(false)->change();
        });
    }
};
