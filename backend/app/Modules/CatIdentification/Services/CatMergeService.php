<?php

namespace App\Modules\CatIdentification\Services;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

class CatMergeService
{
    public function merge(Cat $primaryCat, Cat $duplicateCat, User $actor, string $reason): array
    {
        if ($primaryCat->id === $duplicateCat->id) {
            throw new ConflictHttpException('Tidak dapat menggabungkan profil kucing dengan dirinya sendiri.');
        }

        return DB::transaction(function () use ($primaryCat, $duplicateCat, $actor, $reason) {
            $photosMoved = DB::table('cat_photos')
                ->where('cat_id', $duplicateCat->id)
                ->update(['cat_id' => $primaryCat->id, 'updated_at' => now()]);

            $sightingsMoved = DB::table('cat_sightings')
                ->where('cat_id', $duplicateCat->id)
                ->update(['cat_id' => $primaryCat->id, 'updated_at' => now()]);

            $statusLogsMoved = DB::table('cat_status_logs')
                ->where('cat_id', $duplicateCat->id)
                ->update(['cat_id' => $primaryCat->id, 'updated_at' => now()]);

            DB::table('unidentified_sightings')
                ->where('matched_cat_id', $duplicateCat->id)
                ->update(['matched_cat_id' => $primaryCat->id, 'updated_at' => now()]);

            DB::table('identification_attempts')
                ->where('confirmed_cat_id', $duplicateCat->id)
                ->update(['confirmed_cat_id' => $primaryCat->id, 'updated_at' => now()]);

            $existingQuestionIds = DB::table('cat_trait_answers')
                ->where('cat_id', $primaryCat->id)
                ->pluck('question_id')
                ->all();

            $duplicateTraits = DB::table('cat_trait_answers')
                ->where('cat_id', $duplicateCat->id)
                ->get();

            foreach ($duplicateTraits as $trait) {
                if (!in_array($trait->question_id, $existingQuestionIds, true)) {
                    DB::table('cat_trait_answers')->insert([
                        'cat_id' => $primaryCat->id,
                        'question_id' => $trait->question_id,
                        'answer' => $trait->answer,
                        'created_at' => $trait->created_at,
                        'updated_at' => now(),
                    ]);
                }
            }

            DB::table('cat_trait_answers')
                ->where('cat_id', $duplicateCat->id)
                ->delete();

            CatQrToken::where('cat_id', $duplicateCat->id)
                ->where('status', 'ACTIVE')
                ->update([
                    'status' => 'REVOKED',
                    'revoked_at' => now(),
                    'revoked_reason' => "Merged into {$primaryCat->id}: {$reason}",
                    'updated_at' => now(),
                ]);

            $duplicateCat->delete();

            DB::table('audit_logs')->insert([
                'id' => (string) Str::ulid(),
                'actor_id' => $actor->id,
                'action' => 'cat.merged',
                'subject_type' => Cat::class,
                'subject_id' => $primaryCat->id,
                'result' => 'SUCCESS',
                'reason' => "Merged duplicate {$duplicateCat->id} ({$duplicateCat->unique_code}) into {$primaryCat->id} ({$primaryCat->unique_code}): {$reason}",
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            return [
                'primary_cat_id' => $primaryCat->id,
                'merged_duplicate_cat_id' => $duplicateCat->id,
                'reassigned' => [
                    'photos' => $photosMoved,
                    'sightings' => $sightingsMoved,
                    'status_logs' => $statusLogsMoved,
                ],
            ];
        });
    }
}
