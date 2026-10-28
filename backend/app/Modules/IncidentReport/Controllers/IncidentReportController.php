<?php

namespace App\Modules\IncidentReport\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\IncidentReport\Models\IncidentReport;
use App\Modules\IncidentReport\Requests\ReportIncidentRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class IncidentReportController extends Controller
{
    /**
     * List all emergency incidents
     */
    public function index(Request $request)
    {
        $query = IncidentReport::with(['reporter:id,name,phone', 'cat:id,name,primary_photo_url'])
            ->latest();

        if ($request->has('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->has('urgency_level')) {
            $query->where('urgency_level', $request->query('urgency_level'));
        }

        $reports = $query->paginate($request->query('per_page', 10));

        return ApiResponse::paginated($reports, 'Emergency incidents retrieved');
    }

    /**
     * Submit an emergency incident report
     */
    public function store(ReportIncidentRequest $request)
    {
        $data = $request->validated();
        $data['reporter_id'] = $request->user()->id;
        $data['status'] = 'reported';

        $report = IncidentReport::create($data);

        return ApiResponse::created($report, 'Laporan insiden darurat berhasil dikirim! Tim relawan telah diberitahu.');
    }

    /**
     * Get detail of a specific incident
     */
    public function show($id)
    {
        $report = IncidentReport::with(['reporter:id,name,phone', 'cat'])->findOrFail($id);

        return ApiResponse::success($report, 'Detail laporan insiden');
    }

    /**
     * Update triage status (Volunteer / Admin)
     */
    public function updateStatus(Request $request, $id)
    {
        $report = IncidentReport::findOrFail($id);

        $request->validate([
            'status' => ['required', 'in:reported,dispatched,handling,resolved,rejected'],
            'resolver_notes' => ['nullable', 'string'],
        ]);

        $report->update([
            'status' => $request->input('status'),
            'resolver_notes' => $request->input('resolver_notes'),
        ]);

        return ApiResponse::success($report, 'Status penanganan insiden berhasil diperbarui');
    }
}
