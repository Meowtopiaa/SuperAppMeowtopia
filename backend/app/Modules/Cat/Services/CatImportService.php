<?php

namespace App\Modules\Cat\Services;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use InvalidArgumentException;

class CatImportService
{
    public function __construct(
        protected QrCodeService $qrCodeService
    ) {}

    /**
     * Import initial cat master data from a CSV file exported from Google Sheets (CAT-06).
     */
    public function importFromPath(string $filePath, ?User $actor = null): array
    {
        if (!is_readable($filePath)) {
            throw new InvalidArgumentException("File CSV tidak ditemukan atau tidak dapat dibaca: {$filePath}");
        }

        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            throw new InvalidArgumentException("Gagal membuka file CSV: {$filePath}");
        }

        $rawHeaders = fgetcsv($handle);
        if ($rawHeaders === false || empty($rawHeaders)) {
            fclose($handle);
            throw new InvalidArgumentException('File CSV kosong atau tidak memiliki header.');
        }

        $headers = array_map(function ($h) {
            $h = preg_replace('/^\xEF\xBB\xBF/', '', (string) $h);
            return strtolower(trim($h));
        }, $rawHeaders);

        if (!in_array('name', $headers, true)) {
            fclose($handle);
            throw new InvalidArgumentException('Header CSV wajib memiliki kolom "name".');
        }

        $territoriesByCode = DB::table('territories')
            ->pluck('id', 'code')
            ->mapWithKeys(fn ($id, $code) => [strtoupper((string) $code) => $id])
            ->all();

        $imported = 0;
        $skipped = 0;
        $errors = [];
        $rowNumber = 1;

        while (($row = fgetcsv($handle)) !== false) {
            $rowNumber++;

            if (count(array_filter($row, fn ($v) => trim((string) $v) !== '')) === 0) {
                continue;
            }

            $data = [];
            foreach ($headers as $idx => $key) {
                $data[$key] = isset($row[$idx]) ? trim((string) $row[$idx]) : null;
            }

            $uniqueCode = !empty($data['unique_code'])
                ? strtoupper($data['unique_code'])
                : $this->qrCodeService->generateUniqueCode();

            $gender = !empty($data['gender']) ? strtoupper($data['gender']) : 'UNKNOWN';
            $ageGroup = !empty($data['age_group']) ? strtoupper($data['age_group']) : 'UNKNOWN';
            $verificationStatus = !empty($data['verification_status'])
                ? strtoupper($data['verification_status'])
                : 'VERIFIED';

            $isSterilized = $this->parseNullableBool($data['is_sterilized'] ?? null);

            $territoryId = null;
            if (!empty($data['territory_code'])) {
                $tCode = strtoupper($data['territory_code']);
                $territoryId = $territoriesByCode[$tCode] ?? null;
                if ($territoryId === null) {
                    $skipped++;
                    $errors[] = [
                        'row' => $rowNumber,
                        'message' => "territory_code '{$data['territory_code']}' tidak ditemukan.",
                    ];
                    continue;
                }
            }

            $validator = Validator::make([
                'unique_code' => $uniqueCode,
                'name' => $data['name'] ?? null,
                'gender' => $gender,
                'color_pattern' => $data['color_pattern'] ?: null,
                'age_group' => $ageGroup,
                'is_sterilized' => $isSterilized,
                'description' => $data['description'] ?: null,
                'verification_status' => $verificationStatus,
            ], [
                'unique_code' => ['required', 'string', 'max:32', 'regex:/^[A-Z0-9\-_]+$/', 'unique:cats,unique_code'],
                'name' => ['required', 'string', 'max:100'],
                'gender' => ['required', 'in:MALE,FEMALE,UNKNOWN'],
                'color_pattern' => ['nullable', 'string', 'max:100'],
                'age_group' => ['required', 'in:KITTEN,ADULT,SENIOR,UNKNOWN'],
                'is_sterilized' => ['nullable', 'boolean'],
                'description' => ['nullable', 'string', 'max:2000'],
                'verification_status' => ['required', 'in:UNVERIFIED,VERIFIED'],
            ]);

            if ($validator->fails()) {
                $skipped++;
                $errors[] = [
                    'row' => $rowNumber,
                    'message' => implode('; ', $validator->errors()->all()),
                ];
                continue;
            }

            DB::transaction(function () use ($validator, $territoryId, $actor) {
                $valid = $validator->validated();

                $cat = Cat::create([
                    'unique_code' => $valid['unique_code'],
                    'name' => $valid['name'],
                    'gender' => $valid['gender'],
                    'color_pattern' => $valid['color_pattern'],
                    'age_group' => $valid['age_group'],
                    'is_sterilized' => $valid['is_sterilized'],
                    'description' => $valid['description'],
                    'territory_id' => $territoryId,
                    'presence_status' => 'ON_CAMPUS',
                    'health_status' => 'HEALTHY',
                    'adoption_status' => 'UNREVIEWED',
                    'verification_status' => $valid['verification_status'],
                ]);

                $this->qrCodeService->issueInitialToken($cat, $actor);
            });

            $imported++;
        }

        fclose($handle);

        return [
            'imported' => $imported,
            'skipped' => $skipped,
            'errors' => $errors,
        ];
    }

    protected function parseNullableBool(?string $value): ?bool
    {
        if ($value === null || $value === '') {
            return null;
        }

        $normalized = strtolower($value);
        if (in_array($normalized, ['1', 'true', 'yes', 'ya'], true)) {
            return true;
        }
        if (in_array($normalized, ['0', 'false', 'no', 'tidak'], true)) {
            return false;
        }

        return null;
    }
}
