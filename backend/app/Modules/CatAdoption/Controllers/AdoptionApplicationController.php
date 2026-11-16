<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Requests\StoreApplicationDraftRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Aplikasi kelayakan adopter (PRD 5.2). Terpisah dari transaksi adopsi (FIX-06).
 */
class AdoptionApplicationController extends Controller
{
    public function store(StoreApplicationDraftRequest $request)
    {
        $user = $request->user();
        $data = array_filter($request->validated(), fn ($value) => $value !== null);

        $application = DB::transaction(function () use ($user, $data) {
            // Kunci baris user agar dua permintaan bersamaan tidak membuat dua aplikasi.
            User::whereKey($user->id)->lockForUpdate()->first();

            $hasOpen = AdoptionApplication::where('applicant_id', $user->id)->blocking()->exists();

            if ($hasOpen) {
                return null;
            }

            return AdoptionApplication::create($data + [
                'applicant_id' => $user->id,
                'status' => AdoptionApplication::STATUS_DRAFT,
            ]);
        });

        if ($application === null) {
            return ApiResponse::error('Kamu sudah memiliki pengajuan kelayakan yang sedang berjalan.', 409, 'CONFLICT');
        }

        return ApiResponse::created($this->present($application->fresh()), 'Draf kelayakan berhasil disimpan.');
    }

    public function mine(Request $request)
    {
        $applications = AdoptionApplication::where('applicant_id', $request->user()->id)
            ->latest()
            ->get()
            ->map(fn (AdoptionApplication $application) => $this->present($application));

        return ApiResponse::success($applications, 'Daftar pengajuan kelayakan.');
    }

    /** Data privat: hanya untuk pemilik aplikasi. */
    private function present(AdoptionApplication $application): array
    {
        return [
            'id' => $application->id,
            'status' => $application->status,
            'precheck_passed' => $application->precheck_passed,
            'admin_note' => $application->review_note,
            'housing_type' => $application->housing_type,
            'owner_permission' => $application->owner_permission,
            'can_afford' => $application->can_afford,
            'long_term_plan' => $application->long_term_plan,
            'answers' => $application->answers,
            'submitted_at' => $application->submitted_at?->toIso8601String(),
            'reviewed_at' => $application->reviewed_at?->toIso8601String(),
            'created_at' => $application->created_at?->toIso8601String(),
        ];
    }
}
