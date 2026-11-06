<?php

namespace App\Modules\FeedingSpot\Commands;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use Illuminate\Console\Command;

class ExpireFeedingSessionsCommand extends Command
{
    protected $signature = 'feeding:expire-sessions';
    protected $description = 'Tandai sesi feeding spot yang melewati batas waktu (15 menit intent / 60 menit finalisasi) sebagai EXPIRED (MEOW-24).';

    public function handle(): int
    {
        $now = now();
        $expiredCount = 0;

        // 1. Sesi DRAFT tanpa intent yang lewat dari 15 menit sejak scanned_at
        $intentExpired = FeedingActivity::query()
            ->where('status', 'DRAFT')
            ->whereNull('intent_at')
            ->where('scanned_at', '<', $now->copy()->subMinutes(15))
            ->update([
                'status' => 'EXPIRED',
                'reward_status' => 'NOT_ELIGIBLE',
                'updated_at' => $now,
            ]);

        // 2. Sesi DRAFT dengan intent yang melewati finalize_deadline_at
        $finalizeExpired = FeedingActivity::query()
            ->where('status', 'DRAFT')
            ->whereNotNull('intent_at')
            ->where('finalize_deadline_at', '<', $now)
            ->update([
                'status' => 'EXPIRED',
                'reward_status' => 'NOT_ELIGIBLE',
                'updated_at' => $now,
            ]);

        $expiredCount = $intentExpired + $finalizeExpired;
        $this->info("Berhasil menandai {$expiredCount} sesi pakan yang kedaluwarsa sebagai EXPIRED.");

        return Command::SUCCESS;
    }
}

