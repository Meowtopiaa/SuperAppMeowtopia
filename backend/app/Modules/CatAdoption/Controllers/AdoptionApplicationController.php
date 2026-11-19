<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Requests\StoreApplicationDraftRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
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

            $application = AdoptionApplication::create($this->draftAttributes($data) + [
                'applicant_id' => $user->id,
                'status' => AdoptionApplication::STATUS_DRAFT,
            ]);
            $this->syncHousingMedia($application, $data);

            return $application;
        });

        if ($application === null) {
            return ApiResponse::error('Kamu sudah memiliki pengajuan kelayakan yang sedang berjalan.', 409, 'CONFLICT');
        }

        return ApiResponse::created($this->present($application->fresh()), 'Draf kelayakan berhasil disimpan.');
    }

    /** ADP-02: simpan draf. Field yang dikirim null dikosongkan. */
    public function update(StoreApplicationDraftRequest $request, string $id)
    {
        $data = $request->validated();

        $application = DB::transaction(function () use ($request, $id, $data) {
            $application = $this->editableApplication($request, $id);
            $application->update($this->draftAttributes($data));
            $this->syncHousingMedia($application, $data);

            return $application;
        });

        return ApiResponse::success($this->present($application->fresh()), 'Draf kelayakan berhasil disimpan.');
    }

    /** ADP-02 dan ADP-03: kirim draf lengkap lalu jalankan precheck. Gagal precheck tetap SUBMITTED; admin yang memutuskan. */
    public function submit(Request $request, string $id)
    {
        $failures = [];

        $application = DB::transaction(function () use ($request, $id, &$failures) {
            $application = $this->editableApplication($request, $id);

            $errors = $this->missingForSubmit($application);
            if ($errors !== []) {
                throw new HttpResponseException(
                    ApiResponse::error('Lengkapi form kelayakan sebelum mengirim.', 422, 'VALIDATION_ERROR', $errors)
                );
            }

            $failures = $this->precheckFailures($application);

            $application->update([
                'status' => AdoptionApplication::STATUS_SUBMITTED,
                'submitted_at' => now(),
                'precheck_passed' => $failures === [],
            ]);

            return $application;
        });

        return ApiResponse::success(
            $this->present($application->fresh()),
            'Pengajuan kelayakan berhasil dikirim.',
            200,
            ['precheck_failures' => $failures]
        );
    }

    public function mine(Request $request)
    {
        $applications = AdoptionApplication::where('applicant_id', $request->user()->id)
            ->with('media')
            ->latest()
            ->get()
            ->map(fn (AdoptionApplication $application) => $this->present($application));

        return ApiResponse::success($applications, 'Daftar pengajuan kelayakan.');
    }

    /** Ambil aplikasi milik user dengan kunci baris; hanya DRAFT atau REVISION_REQUESTED yang boleh diubah. */
    private function editableApplication(Request $request, string $id): AdoptionApplication
    {
        $application = AdoptionApplication::lockForUpdate()->find($id);

        if ($application === null) {
            throw new HttpResponseException(ApiResponse::error('Pengajuan kelayakan tidak ditemukan.', 404, 'NOT_FOUND'));
        }

        if ($application->applicant_id !== $request->user()->id) {
            throw new HttpResponseException(ApiResponse::error('Kamu tidak memiliki akses ke pengajuan ini.', 403, 'FORBIDDEN'));
        }

        if (! $application->isEditable()) {
            throw new HttpResponseException(ApiResponse::error('Pengajuan ini sudah dikirim dan tidak dapat diubah.', 409, 'CONFLICT'));
        }

        return $application;
    }

    private function draftAttributes(array $data): array
    {
        $attributes = Arr::only($data, ['housing_type', 'owner_permission', 'can_afford', 'long_term_plan', 'answers']);

        if (array_key_exists('commitment_accepted', $data)) {
            $attributes['commitment_version'] = AdoptionApplication::COMMITMENT_VERSION;
            $attributes['commitment_accepted_at'] = $data['commitment_accepted'] ? now() : null;
        }

        return $attributes;
    }

    /** Satu foto tempat tinggal per aplikasi; foto baru menggantikan yang lama. */
    private function syncHousingMedia(AdoptionApplication $application, array $data): void
    {
        if (! array_key_exists('housing_media_id', $data)) {
            return;
        }

        $application->media()->delete();

        if ($data['housing_media_id'] !== null) {
            $application->media()->create(['media_id' => $data['housing_media_id']]);
        }
    }

    private function missingForSubmit(AdoptionApplication $application): array
    {
        $required = 'Wajib diisi sebelum mengirim.';
        $errors = [];

        foreach (['housing_type', 'owner_permission', 'can_afford', 'long_term_plan'] as $field) {
            if ($application->{$field} === null || $application->{$field} === '') {
                $errors[$field] = [$required];
            }
        }

        $hasPhoto = $application->media()
            ->join('media_files', 'media_files.id', '=', 'adoption_application_media.media_id')
            ->whereNull('media_files.deleted_at')
            ->exists();
        if (! $hasPhoto) {
            $errors['housing_media_id'] = ['Foto tempat tinggal dari kamera aplikasi wajib diunggah.'];
        }

        if ($application->commitment_accepted_at === null || $application->commitment_version !== AdoptionApplication::COMMITMENT_VERSION) {
            $errors['commitment_accepted'] = ['Setujui komitmen adopter versi ' . AdoptionApplication::COMMITMENT_VERSION . '.'];
        }

        return $errors;
    }

    /** ADP-03. Kelengkapan sudah dijamin missingForSubmit(); hasilnya kode alasan yang gagal. */
    private function precheckFailures(AdoptionApplication $application): array
    {
        $adoptions = Adoption::where('adopter_id', $application->applicant_id);
        $failures = [];

        if ($application->owner_permission !== true) {
            $failures[] = 'NO_OWNER_PERMISSION';
        }

        if ((clone $adoptions)->open()->exists()) {
            $failures[] = 'ALREADY_ADOPTING';
        }

        if ((clone $adoptions)->where('rehome_cooldown_until', '>', now())->exists()) {
            $failures[] = 'COOLDOWN_ACTIVE';
        }

        return $failures;
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
            'housing_media_id' => $application->media->first()?->media_id,
            'commitment_version' => $application->commitment_accepted_at ? $application->commitment_version : null,
            'commitment_accepted_at' => $application->commitment_accepted_at?->toIso8601String(),
            'submitted_at' => $application->submitted_at?->toIso8601String(),
            'reviewed_at' => $application->reviewed_at?->toIso8601String(),
            'created_at' => $application->created_at?->toIso8601String(),
        ];
    }
}
