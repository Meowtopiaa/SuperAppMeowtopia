<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\Core\Services\CatStatusService;
use App\Support\ApiResponse;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

/**
 * Aksi adoption_admin (PRD 8.6). Izin lewat permission Spatie.
 */
class AdminAdoptionController extends Controller
{
    /** Status yang boleh dilihat admin. DRAFT tidak ditampilkan karena belum dikirim pemohon. */
    private const REVIEWABLE_STATUSES = [
        AdoptionApplication::STATUS_SUBMITTED,
        AdoptionApplication::STATUS_REVISION_REQUESTED,
        AdoptionApplication::STATUS_APPROVED,
        AdoptionApplication::STATUS_REJECTED,
    ];

    /** Keputusan admin -> status hasil (ADP-04). */
    private const DECISIONS = [
        'APPROVE' => AdoptionApplication::STATUS_APPROVED,
        'REQUEST_CHANGES' => AdoptionApplication::STATUS_REVISION_REQUESTED,
        'REJECT' => AdoptionApplication::STATUS_REJECTED,
    ];

    /** ADP-05: tetapkan READY dengan alasan; riwayat dicatat CatStatusService di cat_status_logs. */
    public function setReady(Request $request, string $catId, CatStatusService $statuses)
    {
        if (! $request->user()->can('adoption.set_ready')) {
            return ApiResponse::error('Kamu tidak memiliki izin menetapkan kesiapan adopsi.', 403, 'FORBIDDEN');
        }

        $validator = validator($request->all(), ['reason' => ['required', 'string', 'max:1000']]);
        if ($validator->fails()) {
            return ApiResponse::error('Data yang dikirim tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors());
        }

        $cat = Cat::find($catId);
        if ($cat === null) {
            return ApiResponse::error('Kucing tidak ditemukan.', 404, 'NOT_FOUND');
        }

        // Kucing hilang, mati, atau sedang diadopsi tidak boleh masuk katalog.
        if ($cat->presence_status !== 'ON_CAMPUS') {
            return ApiResponse::error('Kucing sedang tidak berada di kampus.', 409, 'CAT_NOT_AVAILABLE');
        }

        try {
            $statuses->change($cat, 'adoption_status', 'READY', $request->user(), 'CatAdoption', $validator->validated()['reason']);
        } catch (ConflictHttpException) {
            return ApiResponse::error("Kucing berstatus {$cat->adoption_status} tidak dapat ditetapkan READY.", 409, 'CONFLICT');
        }

        return ApiResponse::success([
            'id' => $cat->id,
            'name' => $cat->name,
            'adoption_status' => $cat->adoption_status,
        ], 'Kucing ditetapkan siap adopsi.');
    }

    /** ADP-15 (dasar): antrean pengajuan kelayakan untuk admin. Default SUBMITTED, terlama lebih dulu. */
    public function applications(Request $request)
    {
        $user = $request->user();
        if (! $user->can('adoption.review') && ! $user->can('adoption.approve')) {
            return ApiResponse::error('Kamu tidak memiliki izin melihat pengajuan kelayakan.', 403, 'FORBIDDEN');
        }

        $validator = validator($request->query(), [
            'status' => ['nullable', Rule::in(self::REVIEWABLE_STATUSES)],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);
        if ($validator->fails()) {
            return ApiResponse::error('Parameter tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors());
        }

        $applications = AdoptionApplication::query()
            ->where('status', $request->query('status', AdoptionApplication::STATUS_SUBMITTED))
            ->with(['applicant:id,name,email', 'media'])
            ->orderBy('submitted_at')
            ->paginate($request->integer('per_page', 20));

        $applications->getCollection()->transform(fn (AdoptionApplication $application) => $this->present($application));

        return ApiResponse::paginated($applications, 'Antrean pengajuan kelayakan.');
    }

    /**
     * ADP-04: admin meminta perbaikan, menyetujui, atau menolak dengan alasan; aktor dan waktu tercatat.
     * Persetujuan tidak membuat adopsi aktif (FIX-06). Notifikasi ke pemohon menunggu layanan notifikasi Core.
     */
    public function decide(Request $request, string $id)
    {
        $validator = validator($request->all(), [
            'decision' => ['required', Rule::in(array_keys(self::DECISIONS))],
            'reason' => ['required', 'string', 'max:1000'],
        ]);
        if ($validator->fails()) {
            return ApiResponse::error('Data yang dikirim tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors());
        }
        $data = $validator->validated();

        // Usulan pemetaan izin: APPROVE butuh adoption.approve; minta perbaikan dan tolak butuh adoption.review.
        $permission = $data['decision'] === 'APPROVE' ? 'adoption.approve' : 'adoption.review';
        if (! $request->user()->can($permission)) {
            return ApiResponse::error('Kamu tidak memiliki izin untuk keputusan ini.', 403, 'FORBIDDEN');
        }

        $application = DB::transaction(function () use ($request, $id, $data) {
            $application = AdoptionApplication::lockForUpdate()->find($id);

            if ($application === null) {
                throw new HttpResponseException(ApiResponse::error('Pengajuan kelayakan tidak ditemukan.', 404, 'NOT_FOUND'));
            }

            // Hanya pengajuan yang sudah dikirim dan belum diputuskan yang boleh diputuskan.
            if ($application->status !== AdoptionApplication::STATUS_SUBMITTED) {
                throw new HttpResponseException(ApiResponse::error(
                    "Pengajuan berstatus {$application->status} tidak dapat diputuskan.", 409, 'CONFLICT'
                ));
            }

            $application->update([
                'status' => self::DECISIONS[$data['decision']],
                'reviewed_by' => $request->user()->id,
                'reviewed_at' => now(),
                'review_note' => $data['reason'],
            ]);

            return $application;
        });

        return ApiResponse::success(
            $this->present($application->fresh(['applicant:id,name,email', 'media'])),
            'Keputusan kelayakan berhasil disimpan.'
        );
    }

    /** Data privat pemohon: hanya untuk adoption_admin (ADP-02). */
    private function present(AdoptionApplication $application): array
    {
        return [
            'id' => $application->id,
            'status' => $application->status,
            'precheck_passed' => $application->precheck_passed,
            'admin_note' => $application->review_note,
            'applicant' => $application->applicant?->only(['id', 'name', 'email']),
            'housing_type' => $application->housing_type,
            'owner_permission' => $application->owner_permission,
            'can_afford' => $application->can_afford,
            'long_term_plan' => $application->long_term_plan,
            'answers' => $application->answers,
            'housing_media_id' => $application->media->first()?->media_id,
            'submitted_at' => $application->submitted_at?->toIso8601String(),
            'reviewed_by' => $application->reviewed_by,
            'reviewed_at' => $application->reviewed_at?->toIso8601String(),
        ];
    }
}
