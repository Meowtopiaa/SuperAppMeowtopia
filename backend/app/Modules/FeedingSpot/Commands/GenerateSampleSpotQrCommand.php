<?php

namespace App\Modules\FeedingSpot\Commands;

use App\Modules\FeedingSpot\Models\FeedingSpot;
use App\Modules\FeedingSpot\Services\FeedingSpotQrCodeService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class GenerateSampleSpotQrCommand extends Command
{
    protected $signature = 'feeding:sample-qr {--spot= : Kode atau ID spot tertentu} {--format=both : svg, png, atau both}';
    protected $description = 'Generate berkas QR Code resmi (MTP1.S.<token>) untuk feeding spot kampus siap cetak/uji scan (MEOW-28)';

    public function handle(FeedingSpotQrCodeService $qrService): int
    {
        $query = FeedingSpot::query()->orderBy('code');

        if ($this->option('spot')) {
            $needle = trim((string) $this->option('spot'));
            $query->where(function ($q) use ($needle) {
                $q->where('id', $needle)->orWhere('code', $needle);
            });
        }

        $spots = $query->get();

        if ($spots->isEmpty()) {
            $this->warn('Belum ada data feeding spot di database. Jalankan php artisan feeding:setup-local terlebih dahulu.');
            return self::FAILURE;
        }

        $disk = Storage::disk(config('filesystems.default', 'local'));
        $format = strtolower((string) $this->option('format'));

        $rows = [];
        foreach ($spots as $spot) {
            $payload = $qrService->formatSpotPayload($spot->qr_token);
            $safeCode = preg_replace('/[^A-Za-z0-9\-_]/', '_', $spot->code);

            if ($format === 'svg' || $format === 'both') {
                $svgContent = $qrService->renderSvg($payload, 320, 4);
                $disk->put("qr-spots/{$safeCode}.svg", $svgContent);
            }

            if ($format === 'png' || $format === 'both') {
                $pngContent = $qrService->renderPng($payload, 10, 4);
                $disk->put("qr-spots/{$safeCode}.png", $pngContent);
            }

            $rows[] = [
                $spot->code,
                $spot->name,
                $spot->status,
                $payload,
                "storage/app/qr-spots/{$safeCode}.svg",
            ];
        }

        $this->table(
            ['Kode Manual', 'Nama Spot', 'Status', 'Payload QR (MTP1.S)', 'Berkas QR'],
            $rows
        );

        $this->info('Berkas QR Code feeding spot berhasil dibuat dan siap dipindai.');

        return self::SUCCESS;
    }
}
