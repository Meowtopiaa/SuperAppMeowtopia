<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed default Super Admin & Sample Student
        User::firstOrCreate(
            ['email' => 'admin@meowtopia.app'],
            [
                'name' => 'Meowtopia Admin',
                'password' => Hash::make('password123'),
                'role' => 'admin',
                'student_id' => 'ADMIN001',
                'points_balance' => 9999,
            ]
        );

        User::firstOrCreate(
            ['email' => 'student@telkomuniversity.ac.id'],
            [
                'name' => 'Mahasiswa Tel-U',
                'password' => Hash::make('password123'),
                'role' => 'student',
                'student_id' => '1301210001',
                'points_balance' => 150,
            ]
        );
    }
}
