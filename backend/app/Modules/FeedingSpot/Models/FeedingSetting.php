<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Model;

class FeedingSetting extends Model
{
    protected $table = 'feeding_settings';
    protected $primaryKey = 'key';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;

    protected $fillable = [
        'key',
        'value',
        'description',
        'updated_at',
    ];

    protected $casts = [
        'updated_at' => 'datetime',
    ];

    /**
     * Default parameters per PRD Lampiran A.1 & Bagian 8.4.
     */
    public const DEFAULTS = [
        'base_points' => ['value' => '5', 'description' => 'Poin dasar per aktivitas pemberian pakan terverifikasi'],
        'max_frequency_bonus' => ['value' => '8', 'description' => 'Bonus maksimum kelangkaan frekuensi 14 hari'],
        'target_14d_feedings' => ['value' => '28', 'description' => 'Target ideal pemberian makan per spot dalam 14 hari (2x/hari)'],
        'max_recency_bonus' => ['value' => '7', 'description' => 'Bonus maksimum selang waktu sejak pakan terakhir'],
        'recency_Reference_hours' => ['value' => '24', 'description' => 'Referensi jam untuk bonus recency maksimal'],
        'min_points' => ['value' => '5', 'description' => 'Batas minimum poin per aktivitas pemberian pakan'],
        'max_points' => ['value' => '20', 'description' => 'Batas maksimum poin per aktivitas pemberian pakan'],
        'cooldown_hours' => ['value' => '6', 'description' => 'Cooldown pemberian pakan pengguna yang sama di spot yang sama (jam)'],
        'intent_window_minutes' => ['value' => '15', 'description' => 'Batas waktu konfirmasi intent setelah scan QR (menit)'],
        'finalize_window_minutes' => ['value' => '60', 'description' => 'Batas waktu finalisasi bukti setelah scan QR (menit)'],
        'new_user_review_threshold' => ['value' => '2', 'description' => 'Jumlah aktivitas pertama pengguna baru yang wajib masuk antrean review'],
        'daily_reward_cap_count' => ['value' => '3', 'description' => 'Batas frekuensi pemberian pakan berpoin per pengguna per hari'],
    ];

    public static function ensureDefaults(): void
    {
        foreach (self::DEFAULTS as $key => $meta) {
            self::firstOrCreate(
                ['key' => $key],
                [
                    'value' => $meta['value'],
                    'description' => $meta['description'],
                    'updated_at' => now(),
                ]
            );
        }
    }

    public static function getValue(string $key, mixed $default = null): mixed
    {
        $row = self::find($key);
        if ($row) {
            return $row->value;
        }

        if (isset(self::DEFAULTS[$key])) {
            return self::DEFAULTS[$key]['value'];
        }

        return $default;
    }

    public static function getFloat(string $key, float $default = 0.0): float
    {
        return (float) self::getValue($key, $default);
    }
}
