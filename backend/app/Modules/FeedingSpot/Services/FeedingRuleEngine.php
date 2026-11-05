<?php

namespace App\Modules\FeedingSpot\Services;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingRuleResult;
use App\Modules\FeedingSpot\Models\FeedingSetting;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class FeedingRuleEngine
{
    /**
     * Rule R1 & R4: Validate scanned QR / spot code and 6-hour cooldown before creating a DRAFT session.
     * Note: Rules R3 & R9 (GPS verification) are strictly omitted per PRD OQ-01 & Appendix A.
     */
    public function validateSpotAndCooldownForNewSession(string $rawCode, string $userId): array
    {
        $code = trim($rawCode);
        if ($code === '') {
            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'VALIDATION_ERROR',
                'message' => 'Token QR spot wajib diisi.',
            ];
        }

        // Check if user accidentally scanned a Cat QR (MTP1.C.<token> or CATxxx) -> IT-03
        $parts = explode('.', $code);
        if (count($parts) === 3 && $parts[0] === 'MTP1') {
            if ($parts[1] === 'C') {
                return [
                    'ok' => false,
                    'http_status' => 422,
                    'code' => 'QR_WRONG_TYPE',
                    'message' => 'Kode QR yang dipindai adalah QR kalung kucing. Harap pindai QR resmi titik makan (spot).',
                ];
            }
            if ($parts[1] !== 'S') {
                return [
                    'ok' => false,
                    'http_status' => 422,
                    'code' => 'QR_INVALID',
                    'message' => 'Format kode QR Meowtopia tidak dikenali.',
                ];
            }
            $spotToken = $parts[2];
            $spot = FeedingSpot::where('qr_token', $spotToken)->first();
        } else {
            // Check if manual code belongs to a cat (IT-03)
            $isCatCode = DB::table('cats')->where('unique_code', $code)->exists()
                || DB::table('cat_qr_tokens')->where('token', $code)->exists();

            if ($isCatCode) {
                return [
                    'ok' => false,
                    'http_status' => 422,
                    'code' => 'QR_WRONG_TYPE',
                    'message' => 'Kode yang dimasukkan adalah kode kucing. Harap gunakan QR atau kode titik makan (spot).',
                ];
            }

            // Look up spot by qr_token or unique spot code
            $spot = FeedingSpot::where('qr_token', $code)
                ->orWhere('code', $code)
                ->first();
        }

        // Rule R1: Spot must exist and be ACTIVE
        if (!$spot) {
            return [
                'ok' => false,
                'http_status' => 404,
                'code' => 'QR_INVALID',
                'message' => 'Token QR titik makan tidak ditemukan atau sudah dicabut.',
            ];
        }

        if ($spot->status !== 'ACTIVE') {
            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'SPOT_UNAVAILABLE',
                'message' => $spot->status === 'TEMPORARILY_UNAVAILABLE'
                    ? 'Titik makan ini sedang tidak tersedia sementara.'
                    : 'Titik makan ini sudah tidak aktif.',
            ];
        }

        // Rule R4: Cooldown 6 hours per user & spot from last completed submission (including REJECTED)
        $cooldownHours = (int) FeedingSetting::getValue('cooldown_hours', 6);
        $cooldownCutoff = now()->subHours($cooldownHours);

        $recentCompleted = FeedingActivity::where('user_id', $userId)
            ->where('spot_id', $spot->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED'])
            ->where('finalized_at', '>=', $cooldownCutoff)
            ->latest('finalized_at')
            ->first();

        if ($recentCompleted) {
            $nextAvailableAt = $recentCompleted->finalized_at->copy()->addHours($cooldownHours);
            return [
                'ok' => false,
                'http_status' => 429,
                'code' => 'COOLDOWN_ACTIVE',
                'message' => "Anda sudah mengajukan aktivitas di spot ini. Silakan coba lagi setelah {$cooldownHours} jam sejak pengajuan terakhir.",
                'errors' => [
                    'last_submitted_at' => $recentCompleted->finalized_at->toIso8601String(),
                    'next_available_at' => $nextAvailableAt->toIso8601String(),
                ],
            ];
        }

        return [
            'ok' => true,
            'spot' => $spot,
        ];
    }

    /**
     * Rule R2: Validate intent confirmation within 15 minutes of session creation.
     */
    public function validateIntentWindow(FeedingActivity $activity): array
    {
        if ($activity->status === 'EXPIRED') {
            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'SESSION_EXPIRED',
                'message' => 'Sesi kedaluwarsa. Pindai ulang QR spot.',
            ];
        }

        if ($activity->status !== 'DRAFT') {
            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'INVALID_SESSION_STATE',
                'message' => 'Sesi sudah dikirim atau tidak lagi berstatus DRAFT.',
            ];
        }

        if ($activity->intent_deadline_at && now()->greaterThan($activity->intent_deadline_at)) {
            $activity->update(['status' => 'EXPIRED']);
            $this->recordRuleResult(
                $activity->id,
                'R2',
                'FAIL',
                'Melewati batas waktu 15 menit untuk konfirmasi niat memberi makan (intent).'
            );

            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'SESSION_EXPIRED',
                'message' => 'Sesi kedaluwarsa (lewat batas 15 menit intent). Pindai ulang QR spot.',
            ];
        }

        return ['ok' => true];
    }

    /**
     * Evaluate Rules R1, R2, R4, R5, R6, R8 and mandatory sampling during finalization (AFS-07 & Appendix A).
     */
    public function evaluateFinalization(FeedingActivity $activity, array $mediaIds): array
    {
        // 1. Check R2 (Session state & 60-minute finalize deadline)
        if ($activity->status === 'EXPIRED' || ($activity->finalize_deadline_at && now()->greaterThan($activity->finalize_deadline_at))) {
            if ($activity->status === 'DRAFT') {
                $activity->update(['status' => 'EXPIRED']);
            }
            $this->recordRuleResult(
                $activity->id,
                'R2',
                'FAIL',
                'Melewati batas waktu 60 menit sejak pemindaian QR spot.'
            );

            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'SESSION_EXPIRED',
                'message' => 'Sesi kedaluwarsa. Pindai ulang QR spot.',
            ];
        }

        if ($activity->status !== 'DRAFT') {
            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'SESSION_ALREADY_FINALIZED',
                'message' => 'Sesi ini sudah pernah difinalisasi sebelumnya.',
            ];
        }

        // Check that intent was recorded (or if intent is still within 15-min window, auto-record intent_at)
        if (!$activity->intent_at) {
            if ($activity->intent_deadline_at && now()->greaterThan($activity->intent_deadline_at)) {
                $activity->update(['status' => 'EXPIRED']);
                $this->recordRuleResult(
                    $activity->id,
                    'R2',
                    'FAIL',
                    'Intent belum tercatat dalam 15 menit pertama sesi.'
                );

                return [
                    'ok' => false,
                    'http_status' => 422,
                    'code' => 'SESSION_EXPIRED',
                    'message' => 'Sesi kedaluwarsa karena intent tidak dikonfirmasi dalam 15 menit.',
                ];
            }
            $activity->intent_at = now();
        }

        // 2. Check R5 (1 to 3 valid media files belonging to user, leaves status as DRAFT if invalid)
        $minPhotos = (int) FeedingSetting::getValue('min_photos', 1);
        $maxPhotos = (int) FeedingSetting::getValue('max_photos', 3);
        $uniqueMediaIds = array_values(array_unique(array_filter($mediaIds)));

        if (count($uniqueMediaIds) < $minPhotos || count($uniqueMediaIds) > $maxPhotos) {
            $this->recordRuleResult(
                $activity->id,
                'R5',
                'FAIL',
                "Jumlah foto bukti harus antara {$minPhotos} sampai {$maxPhotos}."
            );

            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'INVALID_EVIDENCE_COUNT',
                'message' => "Finalisasi membutuhkan {$minPhotos} sampai {$maxPhotos} foto bukti dari kamera.",
            ];
        }

        $mediaFiles = DB::table('media_files')
            ->whereIn('id', $uniqueMediaIds)
            ->where('owner_id', $activity->user_id)
            ->get()
            ->keyBy('id');

        if ($mediaFiles->count() !== count($uniqueMediaIds)) {
            $this->recordRuleResult(
                $activity->id,
                'R5',
                'FAIL',
                'Satu atau lebih media_id tidak ditemukan atau bukan milik pengguna.'
            );

            return [
                'ok' => false,
                'http_status' => 422,
                'code' => 'INVALID_MEDIA',
                'message' => 'Bukti foto tidak valid atau tidak ditemukan. Silakan unggah ulang foto bukti.',
            ];
        }

        foreach ($mediaFiles as $mf) {
            if ((int) $mf->size_bytes <= 0) {
                $this->recordRuleResult($activity->id, 'R5', 'FAIL', "Berkas media {$mf->id} kosong atau rusak.");
                return [
                    'ok' => false,
                    'http_status' => 422,
                    'code' => 'INVALID_MEDIA',
                    'message' => 'Berkas foto rusak atau berukuran 0 byte.',
                ];
            }
        }

        // Clear any prior rule results on this DRAFT before writing fresh evaluation
        FeedingRuleResult::where('activity_id', $activity->id)->delete();

        // Record R1, R2, R4, R5 PASS
        $this->recordRuleResult($activity->id, 'R1', 'PASS', 'Token QR spot dan status spot ACTIVE terverifikasi saat pembukaan sesi.');
        $this->recordRuleResult($activity->id, 'R2', 'PASS', 'Sesi milik pengguna, belum dipakai, dan difinalisasi sebelum batas waktu 60 menit.');

        // Re-verify R4 (Cooldown against other completed sessions in case of concurrent requests)
        $cooldownHours = (int) FeedingSetting::getValue('cooldown_hours', 6);
        $cooldownConflict = FeedingActivity::where('user_id', $activity->user_id)
            ->where('spot_id', $activity->spot_id)
            ->where('id', '!=', $activity->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED'])
            ->where('finalized_at', '>=', now()->subHours($cooldownHours))
            ->exists();

        if ($cooldownConflict) {
            $this->recordRuleResult($activity->id, 'R4', 'FAIL', "Konflik cooldown {$cooldownHours} jam dengan pengajuan lain di spot yang sama.");
            return [
                'ok' => false,
                'http_status' => 429,
                'code' => 'COOLDOWN_ACTIVE',
                'message' => "Cooldown {$cooldownHours} jam masih berlaku untuk titik makan ini.",
            ];
        }

        $this->recordRuleResult($activity->id, 'R4', 'PASS', "Tidak ada pengajuan lain dalam {$cooldownHours} jam terakhir di spot ini.");
        $this->recordRuleResult($activity->id, 'R5', 'PASS', count($uniqueMediaIds) . ' foto bukti kamera valid dan terverifikasi.');

        // 3. Evaluate Review Flags (R6, R8, First 2 Submissions, 10% Random Sample)
        $existingFlags = is_array($activity->flags) ? $activity->flags : [];
        $activeFlags = [];

        // Rule R6: SHA-256 duplicate photo detection across other activities
        $sha256List = $mediaFiles->pluck('sha256')->filter()->unique()->values()->all();
        $reusedPhotoExists = false;

        if (!empty($sha256List)) {
            $reusedPhotoExists = DB::table('feeding_evidence')
                ->join('media_files', 'feeding_evidence.media_id', '=', 'media_files.id')
                ->where('feeding_evidence.activity_id', '!=', $activity->id)
                ->whereIn('media_files.sha256', $sha256List)
                ->exists();
        }

        if ($reusedPhotoExists) {
            $activeFlags[] = 'PHOTO_REUSED';
            $this->recordRuleResult($activity->id, 'R6', 'REVIEW', 'Hash SHA-256 foto identik ditemukan pada pengajuan aktivitas lain (PHOTO_REUSED).');
        } else {
            $this->recordRuleResult($activity->id, 'R6', 'PASS', 'Hash SHA-256 foto unik (belum pernah dipakai pada pengajuan lain).');
        }

        // Rule R8: Capture timestamp vs server intent_at (> 15 minutes tolerance)
        $exifToleranceMin = (int) FeedingSetting::getValue('exif_tolerance_minutes', 15);
        $referenceIntentTime = $activity->intent_at ? Carbon::parse($activity->intent_at) : Carbon::parse($activity->scanned_at);
        $timeMismatch = false;

        foreach ($mediaFiles as $mf) {
            if (!empty($mf->captured_at)) {
                $capturedAt = Carbon::parse($mf->captured_at);
                if (abs($capturedAt->diffInMinutes($referenceIntentTime, false)) > $exifToleranceMin) {
                    $timeMismatch = true;
                    break;
                }
            }
        }

        if ($timeMismatch) {
            $activeFlags[] = 'TIME_MISMATCH';
            $this->recordRuleResult($activity->id, 'R8', 'REVIEW', "Selisih waktu pengambilan foto lebih dari {$exifToleranceMin} menit dari waktu intent server (TIME_MISMATCH).");
        } else {
            $this->recordRuleResult($activity->id, 'R8', 'PASS', 'Waktu pengambilan foto sesuai dengan rentang waktu intent server.');
        }

        // Mandatory Review 1: First two submissions of the user (AFS-07)
        $firstNCount = (int) FeedingSetting::getValue('first_submissions_review_count', 2);
        $priorSubmissionCount = FeedingActivity::where('user_id', $activity->user_id)
            ->where('id', '!=', $activity->id)
            ->whereIn('status', ['SUBMITTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED'])
            ->count();

        if ($priorSubmissionCount < $firstNCount) {
            $activeFlags[] = 'FIRST_TWO_SUBMISSIONS';
        }

        // Mandatory Review 2: 10% random sample, persisted so retries never re-roll (AFS-07)
        $samplePercent = (int) FeedingSetting::getValue('random_sample_percent', 10);
        if (array_key_exists('random_sample_selected', $existingFlags)) {
            $sampleSelected = (bool) $existingFlags['random_sample_selected'];
        } else {
            $sampleSelected = $samplePercent > 0 && random_int(1, 100) <= $samplePercent;
        }

        if ($sampleSelected) {
            $activeFlags[] = 'RANDOM_SAMPLE';
        }

        $finalFlags = [
            'reasons' => array_values(array_unique($activeFlags)),
            'random_sample_drawn' => true,
            'random_sample_selected' => $sampleSelected,
            'prior_submission_count' => $priorSubmissionCount,
        ];

        $needsReview = !empty($finalFlags['reasons']);
        $finalStatus = $needsReview ? 'UNDER_REVIEW' : 'VERIFIED';

        return [
            'ok' => true,
            'status' => $finalStatus,
            'needs_review' => $needsReview,
            'flags' => $finalFlags,
            'media_files' => $mediaFiles,
            'ordered_media_ids' => $uniqueMediaIds,
        ];
    }

    protected function recordRuleResult(string $activityId, string $rule, string $result, string $detail): FeedingRuleResult
    {
        return FeedingRuleResult::create([
            'activity_id' => $activityId,
            'rule' => $rule,
            'result' => $result,
            'detail' => $detail,
        ]);
    }
}

