<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\Core\Services\CatStatusService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

/**
 * Aksi adoption_admin (PRD 8.6). Izin lewat permission Spatie.
 */
class AdminAdoptionController extends Controller
{
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
}
