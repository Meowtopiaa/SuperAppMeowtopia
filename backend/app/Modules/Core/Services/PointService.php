<?php

namespace App\Modules\Core\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class PointService
{
    /**
     * Award points to a user via the append-only ledger.
     * Enforces idempotency and daily caps.
     */
    public function award(
        User $user,
        string $ruleKey,
        string $sourceModule,
        string $sourceType,
        ?string $sourceRefId,
        string $idempotencyKey
    ): array {
        return DB::transaction(function () use ($user, $ruleKey, $sourceModule, $sourceType, $sourceRefId, $idempotencyKey) {
            // 1. Check idempotency: if key exists, return existing transaction
            $existing = DB::table('point_transactions')
                ->where('idempotency_key', $idempotencyKey)
                ->first();

            if ($existing) {
                return [
                    'transaction_id' => $existing->id,
                    'points' => (int) $existing->points,
                    'status' => $existing->status,
                    'is_replay' => true,
                    'reward_capped' => false,
                ];
            }

            // 2. Fetch point rule
            $rule = DB::table('point_rules')
                ->where('rule_key', $ruleKey)
                ->where('is_active', true)
                ->first();

            if (!$rule) {
                throw new InvalidArgumentException("Active point rule '{$ruleKey}' not found.");
            }

            // 3. Check Daily Caps (UTC date)
            $today = now()->utc()->startOfDay();

            // Total daily cap (default 150)
            $totalPointsToday = (int) DB::table('point_transactions')
                ->where('user_id', $user->id)
                ->where('created_at', '>=', $today)
                ->where('status', 'CREDITED')
                ->sum('points');

            // Rule daily count cap
            $ruleCountToday = DB::table('point_transactions')
                ->where('user_id', $user->id)
                ->where('rule_key', $ruleKey)
                ->where('created_at', '>=', $today)
                ->where('status', 'CREDITED')
                ->count();

            $rewardCapped = false;
            $pointsToAward = (int) $rule->points;

            if ($ruleCountToday >= $rule->daily_cap_count || $totalPointsToday >= 150) {
                $rewardCapped = true;
                $pointsToAward = 0;
            } elseif ($totalPointsToday + $pointsToAward > 150) {
                $pointsToAward = 150 - $totalPointsToday;
            }

            // 4. Record to ledger
            $transactionId = (string) Str::ulid();
            DB::table('point_transactions')->insert([
                'id' => $transactionId,
                'user_id' => $user->id,
                'rule_key' => $ruleKey,
                'points' => $pointsToAward,
                'source_module' => $sourceModule,
                'source_type' => $sourceType,
                'source_ref_id' => $sourceRefId,
                'idempotency_key' => $idempotencyKey,
                'status' => 'CREDITED',
                'reversal_of' => null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // 5. Update cached point_balances
            if ($pointsToAward > 0) {
                DB::table('point_balances')
                    ->where('user_id', $user->id)
                    ->increment('total_points', $pointsToAward, ['updated_at' => now()]);
            }

            return [
                'transaction_id' => $transactionId,
                'points' => $pointsToAward,
                'status' => 'CREDITED',
                'is_replay' => false,
                'reward_capped' => $rewardCapped,
            ];
        });
    }

    /**
     * Reverse a previously awarded point transaction.
     */
    public function reverse(string $transactionId, string $reason): array
    {
        return DB::transaction(function () use ($transactionId, $reason) {
            $orig = DB::table('point_transactions')->where('id', $transactionId)->first();
            if (!$orig) {
                throw new InvalidArgumentException("Transaction {$transactionId} not found.");
            }

            if ($orig->status === 'REVERSED') {
                throw new InvalidArgumentException("Transaction {$transactionId} is already reversed.");
            }

            $reversalId = (string) Str::ulid();
            $negativePoints = -$orig->points;

            DB::table('point_transactions')->insert([
                'id' => $reversalId,
                'user_id' => $orig->user_id,
                'rule_key' => $orig->rule_key,
                'points' => $negativePoints,
                'source_module' => $orig->source_module,
                'source_type' => 'REVERSAL',
                'source_ref_id' => $orig->id,
                'idempotency_key' => 'rev_' . $reversalId,
                'status' => 'REVERSED',
                'reversal_of' => $orig->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('point_transactions')
                ->where('id', $transactionId)
                ->update(['status' => 'REVERSED', 'updated_at' => now()]);

            DB::table('point_balances')
                ->where('user_id', $orig->user_id)
                ->decrement('total_points', $orig->points, ['updated_at' => now()]);

            return [
                'reversal_id' => $reversalId,
                'reversed_transaction_id' => $orig->id,
                'points_deducted' => $orig->points,
            ];
        });
    }
}

