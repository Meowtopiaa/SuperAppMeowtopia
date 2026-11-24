<?php

namespace App\Modules\FeedingSpot\Commands;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Models\FeedingAggregate;
use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Console\Command;

class RefreshFeedingAggregatesCommand extends Command
{
    protected $signature = 'feeding:refresh-aggregates {--spot= : ID atau kode spot tertentu}';
    protected $description = 'Segarkan statistik agregat 14 hari terakhir untuk feeding spot aktif (MEOW-24).';

    public function handle(): int
    {
        $spotQuery = FeedingSpot::query()->where('status', '!=', 'INACTIVE');

        if ($spotParam = $this->option('spot')) {
            $spotQuery->where(function ($q) use ($spotParam) {
                $q->where('id', $spotParam)->orWhere('code', $spotParam);
            });
        }

        $spots = $spotQuery->get();
        $windowStart = now()->subDays(14)->startOfDay();
        $windowEnd = now();
        $refreshedCount = 0;

        foreach ($spots as $spot) {
            $verifiedCount = FeedingActivity::query()
                ->where('spot_id', $spot->id)
                ->where('status', 'VERIFIED')
                ->where('finalized_at', '>=', $windowStart)
                ->count();

            $pendingCount = FeedingActivity::query()
                ->where('spot_id', $spot->id)
                ->where('status', 'UNDER_REVIEW')
                ->where('finalized_at', '>=', $windowStart)
                ->count();

            FeedingAggregate::updateOrCreate(
                ['spot_id' => $spot->id],
                [
                    'window_start' => $windowStart,
                    'window_end' => $windowEnd,
                    'verified_count' => $verifiedCount,
                    'pending_count' => $pendingCount,
                    'computed_at' => now(),
                ]
            );

            $refreshedCount++;
        }

        $this->info("Berhasil menyegarkan agregat untuk {$refreshedCount} spot pakan.");

        return Command::SUCCESS;
    }
}

