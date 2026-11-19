<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionPickupLock;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class AdoptionController extends Controller
{
    /**
     * Kolom yang boleh tampil di katalog publik (CAT-09, NFR-04). Tidak ada koordinat,
     * unique_code, token QR, traits, territory, atau waktu perjumpaan.
     */
    public const CATALOG_COLUMNS = [
        'id', 'name', 'gender', 'color_pattern', 'age_group',
        'is_sterilized', 'description', 'primary_photo_media_id', 'adoption_status',
    ];

    /**
     * EN-12: katalog kucing READY di kampus, tanpa adopsi terbuka dan tanpa lock HELD (FIX-05).
     * unique_code tidak dikirim agar pengambilan tetap lewat pindai QR kalung (ADP-06).
     */
    public function cats(Request $request)
    {
        $validator = Validator::make($request->query(), ['per_page' => ['nullable', 'integer', 'min:1', 'max:50']]);
        if ($validator->fails()) {
            return ApiResponse::error('Parameter tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors());
        }

        $cats = Cat::query()
            ->where('adoption_status', 'READY')
            ->where('presence_status', 'ON_CAMPUS')
            ->whereNotIn('id', Adoption::open()->select('cat_id'))
            ->whereNotIn('id', AdoptionPickupLock::active()->select('cat_id'))
            ->orderBy('name')
            ->select(self::CATALOG_COLUMNS)
            ->paginate($request->integer('per_page', 20));

        return ApiResponse::paginated($cats, 'Kucing siap diadopsi.');
    }

    /**
     * Kucing Saya: hanya adopsi dari pengambilan yang berhasil, bukan aplikasi APPROVED (FIX-06).
     */
    public function mine(Request $request)
    {
        $adoptions = Adoption::open()
            ->where('adopter_id', $request->user()->id)
            ->with('cat:id,name,primary_photo_media_id')
            ->get()
            ->map(fn (Adoption $adoption) => [
                'id' => $adoption->id,
                'status' => $adoption->status,
                'picked_up_at' => $adoption->picked_up_at?->toIso8601String(),
                'trial_ends_at' => $adoption->trial_ends_at?->toIso8601String(),
                'cat' => $adoption->cat?->only(['id', 'name', 'primary_photo_media_id']),
            ]);

        return ApiResponse::success($adoptions, 'Kucing Saya.');
    }
}
