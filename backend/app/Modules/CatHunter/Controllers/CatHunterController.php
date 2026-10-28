<?php

namespace App\Modules\CatHunter\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatHunter\Models\CatEncounter;
use App\Modules\CatHunter\Models\UserCatDex;
use App\Modules\CatHunter\Requests\StartEncounterRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class CatHunterController extends Controller
{
    /**
     * Start a cat encounter after scanning collar QR
     */
    public function startEncounter(StartEncounterRequest $request)
    {
        $validated = $request->validated();
        $user = $request->user();

        $cat = Cat::where('qr_code_token', $validated['cat_qr_token'])->first();
        if (!$cat) {
            return ApiResponse::error('Kucing dengan QR ini tidak ditemukan', 404);
        }

        // Update cat last seen location
        $cat->update([
            'last_seen_lat' => $validated['latitude'],
            'last_seen_lng' => $validated['longitude'],
        ]);

        $encounter = CatEncounter::create([
            'user_id' => $user->id,
            'cat_id' => $cat->id,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'reported_condition' => $validated['condition'],
            'turns_count' => 1,
            'encounter_result' => 'captured',
            'affinity_points' => 20,
        ]);

        // Add to User's Cat Dex
        $dex = UserCatDex::firstOrCreate(
            ['user_id' => $user->id, 'cat_id' => $cat->id],
            ['first_captured_at' => now(), 'friendship_level' => 1, 'encounters_count' => 0]
        );

        $dex->increment('encounters_count');
        $dex->update(['last_interacted_at' => now()]);

        // Award points
        $user->increment('points_balance', 20);

        return ApiResponse::success([
            'encounter' => $encounter,
            'cat' => $cat,
            'dex' => $dex,
            'points_earned' => 20,
        ], 'Encounter berhasil! Kucing masuk ke Cat Dex kamu.');
    }

    /**
     * Get user's Cat Dex collection
     */
    public function myDex(Request $request)
    {
        $dex = UserCatDex::with('cat')
            ->where('user_id', $request->user()->id)
            ->get();

        return ApiResponse::success($dex, 'Cat Dex koleksi kamu');
    }

    /**
     * Get campus leaderboard
     */
    public function leaderboard()
    {
        $leaders = User::select('id', 'name', 'avatar_url', 'points_balance')
            ->orderBy('points_balance', 'desc')
            ->take(10)
            ->get();

        return ApiResponse::success($leaders, 'Papan peringkat pemburu kucing');
    }
}
