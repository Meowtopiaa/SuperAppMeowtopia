<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Models\AdoptionFollowup;
use App\Modules\CatAdoption\Requests\SubmitAdoptionRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class AdoptionController extends Controller
{
    /**
     * Get cats that are ready for adoption
     */
    public function readyCats()
    {
        $cats = Cat::where('adoption_status', 'available')->get();

        return ApiResponse::success($cats, 'Kucing siap diadopsi');
    }

    /**
     * Submit an adoption application
     */
    public function apply(SubmitAdoptionRequest $request)
    {
        $validated = $request->validated();
        $user = $request->user();

        $cat = Cat::findOrFail($validated['cat_id']);
        if ($cat->adoption_status !== 'available') {
            return ApiResponse::error('Kucing ini sedang tidak tersedia untuk adopsi', 422);
        }

        $application = AdoptionApplication::create([
            'user_id' => $user->id,
            'cat_id' => $cat->id,
            'status' => 'submitted',
            'housing_type' => $validated['housing_type'],
            'financial_readiness' => $validated['financial_readiness'],
            'family_permission' => $validated['family_permission'],
            'commitment_answers' => $validated['commitment_answers'] ?? null,
        ]);

        return ApiResponse::created($application, 'Pengajuan adopsi berhasil dikirim! Menunggu tinjauan admin.');
    }

    /**
     * Get adopter's current adopted cats ("Kucing Saya")
     */
    public function myCats(Request $request)
    {
        $adoptions = AdoptionApplication::with(['cat', 'followups'])
            ->where('user_id', $request->user()->id)
            ->whereIn('status', ['approved', 'handed_over'])
            ->get();

        return ApiResponse::success($adoptions, 'Daftar Kucing Saya');
    }

    /**
     * Submit bi-weekly monitoring report
     */
    public function submitFollowup(Request $request, $id)
    {
        $application = AdoptionApplication::where('user_id', $request->user()->id)->findOrFail($id);

        $request->validate([
            'photo_proof_url' => ['nullable', 'string'],
            'condition_notes' => ['required', 'string'],
            'health_condition' => ['required', 'in:excellent,good,sick'],
        ]);

        $period = $application->followups()->count() + 1;

        $followup = AdoptionFollowup::create([
            'adoption_application_id' => $application->id,
            'period_number' => $period,
            'photo_proof_url' => $request->input('photo_proof_url'),
            'condition_notes' => $request->input('condition_notes'),
            'health_condition' => $request->input('health_condition'),
            'status' => 'submitted',
        ]);

        return ApiResponse::created($followup, 'Laporan kondisi berkala berhasil dikirim');
    }
}
