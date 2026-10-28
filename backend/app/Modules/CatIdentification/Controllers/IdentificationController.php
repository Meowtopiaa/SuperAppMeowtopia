<?php

namespace App\Modules\CatIdentification\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatIdentification\Models\IdentificationAttempt;
use App\Modules\CatIdentification\Models\IdentificationQuestion;
use App\Modules\CatIdentification\Requests\IdentifyCatRequest;
use App\Modules\CatIdentification\Services\CatMatcherService;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class IdentificationController extends Controller
{
    public function __construct(
        protected CatMatcherService $matcherService
    ) {}

    /**
     * Get list of physical trait questionnaire questions
     */
    public function getQuestions()
    {
        $questions = IdentificationQuestion::where('is_active', true)
            ->orderBy('order', 'asc')
            ->get();

        return ApiResponse::success($questions, 'Questions retrieved successfully');
    }

    /**
     * Identify cat by QR, photo, or questionnaire answers
     */
    public function identify(IdentifyCatRequest $request)
    {
        $validated = $request->validated();
        $method = $validated['method'];

        $matchedCat = null;
        $confidence = 0.0;

        if ($method === 'qr' && !empty($validated['qr_token'])) {
            $matchedCat = Cat::where('qr_code_token', $validated['qr_token'])->first();
            $confidence = $matchedCat ? 100.0 : 0.0;
        } elseif ($method === 'questionnaire' && !empty($validated['answers'])) {
            $result = $this->matcherService->matchByTraits($validated['answers']);
            $matchedCat = $result['top_match'];
            $confidence = $result['confidence'];
        }

        $attempt = IdentificationAttempt::create([
            'user_id' => $request->user()?->id,
            'matched_cat_id' => $matchedCat?->id,
            'photo_path' => $validated['photo'] ?? null,
            'answers' => $validated['answers'] ?? null,
            'confidence_score' => $confidence,
            'method' => $method,
            'status' => $matchedCat ? 'confirmed' : 'inconclusive',
        ]);

        return ApiResponse::success([
            'attempt_id' => $attempt->id,
            'confidence' => $confidence,
            'matched_cat' => $matchedCat,
            'status' => $attempt->status,
        ], 'Identification process completed');
    }
}
