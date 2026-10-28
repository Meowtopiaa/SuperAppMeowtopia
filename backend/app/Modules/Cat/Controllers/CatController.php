<?php

namespace App\Modules\Cat\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Requests\StoreCatRequest;
use App\Modules\Cat\Services\QrCodeService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class CatController extends Controller
{
    public function __construct(
        protected QrCodeService $qrCodeService
    ) {}

    /**
     * List all campus cats (with filter by adoption/health status)
     */
    public function index(Request $request)
    {
        $query = Cat::query();

        if ($request->has('adoption_status')) {
            $query->where('adoption_status', $request->query('adoption_status'));
        }

        if ($request->has('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('breed', 'like', "%{$search}%")
                  ->orWhere('pattern', 'like', "%{$search}%");
            });
        }

        $cats = $query->paginate($request->query('per_page', 15));

        return ApiResponse::paginated($cats, 'Cats retrieved successfully');
    }

    /**
     * Show single cat detail by ID
     */
    public function show($id)
    {
        $cat = Cat::findOrFail($id);

        return ApiResponse::success($cat, 'Cat detail retrieved successfully');
    }

    /**
     * Find cat by collar QR Code token
     */
    public function findByQr(string $token)
    {
        $cat = Cat::where('qr_code_token', $token)->first();

        if (!$cat) {
            return ApiResponse::error('No cat found with this QR token', 404);
        }

        return ApiResponse::success($cat, 'Cat found via collar QR');
    }

    /**
     * Store new cat master data (Admin / Volunteer)
     */
    public function store(StoreCatRequest $request)
    {
        $data = $request->validated();
        $data['qr_code_token'] = $this->qrCodeService->generateCatQrToken();

        $cat = Cat::create($data);

        return ApiResponse::created($cat, 'New cat registered successfully');
    }

    /**
     * Update cat details
     */
    public function update(StoreCatRequest $request, $id)
    {
        $cat = Cat::findOrFail($id);
        $cat->update($request->validated());

        return ApiResponse::success($cat, 'Cat information updated successfully');
    }
}
