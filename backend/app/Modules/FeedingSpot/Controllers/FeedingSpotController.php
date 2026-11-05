<?php

namespace App\Modules\FeedingSpot\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Requests\RecordFeedingRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class FeedingSpotController extends Controller
{
    /**
     * List all feeding spots with status and bowl condition
     */
    public function index()
    {
        $spots = FeedingSpot::withCount('activities')->get();

        return ApiResponse::success($spots, 'Feeding spots retrieved successfully');
    }

    /**
     * Get detail of a specific feeding spot
     */
    public function show($id)
    {
        $spot = FeedingSpot::with(['activities.user'])->findOrFail($id);

        return ApiResponse::success($spot, 'Feeding spot detail retrieved');
    }

    /**
     * Submit feeding activity with QR verification & photo proof
     */
    public function recordFeeding(RecordFeedingRequest $request)
    {
        $validated = $request->validated();
        $spot = FeedingSpot::findOrFail($validated['feeding_spot_id']);

        // Verify spot QR token
        if ($spot->qr_token !== $validated['qr_token']) {
            return ApiResponse::error('Invalid QR token for this feeding spot', 422);
        }

        $activity = FeedingActivity::create([
            'feeding_spot_id' => $spot->id,
            'user_id' => $request->user()->id,
            'photo_proof_url' => $validated['photo_proof_url'] ?? null,
            'food_type' => $validated['food_type'],
            'notes' => $validated['notes'] ?? null,
            'status' => 'verified',
            'points_awarded' => 15,
        ]);

        // Update spot status
        $spot->update([
            'last_fed_at' => now(),
            'bowl_condition' => 'full',
        ]);

        // Increment user points
        $user = $request->user();
        $user->increment('points_balance', 15);

        return ApiResponse::created([
            'activity' => $activity,
            'points_earned' => 15,
            'current_balance' => $user->points_balance,
        ], 'Feeding activity recorded successfully! Points awarded.');
    }
}
