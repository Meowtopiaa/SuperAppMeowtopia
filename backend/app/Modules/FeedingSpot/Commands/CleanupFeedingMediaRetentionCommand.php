<?php

namespace App\Modules\FeedingSpot\Commands;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingEvidence;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CleanupFeedingMediaRetentionCommand extends Command
{
    protected $signature = 'feeding:cleanup-retention';
    protected $description = 'Hapus foto bukti pakan sesuai retensi (180 hari VERIFIED, 30 hari REJECTED) (PRD 4.7, MEOW-24).';

    public function handle(): int
    {
        $now = now();
        $verifiedRetentionDate = $now->copy()->subDays(180);
        $rejectedRetentionDate = $now->copy()->subDays(30);

        // 1. Ambil aktivitas yang sudah melewati retensi
        $expiredActivityIds = FeedingActivity::query()
            ->where(function ($q) use ($verifiedRetentionDate) {
                $q->where('status', 'VERIFIED')
                    ->where('finalized_at', '<', $verifiedRetentionDate);
            })
            ->orWhere(function ($q) use ($rejectedRetentionDate) {
                $q->where('status', 'REJECTED')
                    ->where('updated_at', '<', $rejectedRetentionDate);
            })
            ->pluck('id');

        if ($expiredActivityIds->isEmpty()) {
            $this->info('Tidak ada foto pakan yang melewati batas retensi.');
            return Command::SUCCESS;
        }

        $evidenceList = FeedingEvidence::query()
            ->whereIn('activity_id', $expiredActivityIds)
            ->get();

        $purgedCount = 0;

        foreach ($evidenceList as $evidence) {
            $media = DB::table('media_files')->where('id', $evidence->media_id)->first();
            if ($media) {
                try {
                    if (Storage::disk($media->disk ?? 'local')->exists($media->path)) {
                        Storage::disk($media->disk ?? 'local')->delete($media->path);
                    }
                } catch (\Throwable $e) {
                    // Log or continue gracefully if file already missing
                }

                // Delete or soft-delete media file record
                DB::table('media_files')->where('id', $media->id)->delete();
            }

            $evidence->delete();
            $purgedCount++;
        }

        $this->info("Berhasil membersihkan {$purgedCount} berkas bukti pakan yang melewati masa retensi.");

        return Command::SUCCESS;
    }
}
