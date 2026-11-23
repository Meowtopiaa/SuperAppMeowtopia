<?php

namespace App\Console\Commands;

use App\Modules\CatIdentification\Services\CatImportService;
use Illuminate\Console\Command;
use InvalidArgumentException;

class ImportCatsCommand extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'cats:import {file : Path ke file CSV ekspor Google Sheets}';

    /**
     * The console command description.
     */
    protected $description = 'Impor data master kucing awal dari file CSV dengan validasi (CAT-06)';

    public function handle(CatImportService $importService): int
    {
        $file = (string) $this->argument('file');

        try {
            $summary = $importService->importFromPath($file);
        } catch (InvalidArgumentException $e) {
            $this->error($e->getMessage());
            return self::FAILURE;
        }

        $this->info("Impor selesai: {$summary['imported']} kucing diimpor, {$summary['skipped']} dilewati.");

        if (!empty($summary['errors'])) {
            $this->warn('Baris yang dilewati:');
            foreach ($summary['errors'] as $err) {
                $this->line("  - Baris {$err['row']}: {$err['message']}");
            }
        }

        return self::SUCCESS;
    }
}

