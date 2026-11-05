<?php

namespace App\Modules\FeedingSpot\Models;

use Illuminate\Database\Eloquent\Model;

class FeedingSetting extends Model
{
    protected $table = 'feeding_settings';
    protected $primaryKey = 'key';
    protected $keyType = 'string';
    public $incrementing = false;

    protected $fillable = [
        'key',
        'value',
    ];

    protected $casts = [
        'value' => 'array',
    ];

    /**
     * Default settings per PRD Section 6.3 and Appendix A.
     */
    public static function defaults(): array
    {
        return [
            'intent_deadline_minutes' => 15,
            'finalize_deadline_minutes' => 60,
            'cooldown_hours' => 6,
            'min_photos' => 1,
            'max_photos' => 3,
            'first_submissions_review_count' => 2,
            'random_sample_percent' => 10,
            'exif_tolerance_minutes' => 15,
            'window_days' => 14,
            'target_activities_per_window' => 14,
            'base_points' => 10,
            'min_spot_age_days_for_formula' => 7,
            'min_campus_activities_for_formula' => 30,
            'aggregate_stale_minutes' => 60,
            'config_version' => '1.1.0',
        ];
    }

    /**
     * Retrieve a setting value with fallback to default.
     */
    public static function getValue(string $key, mixed $default = null): mixed
    {
        $defaults = self::defaults();
        $fallback = $default ?? ($defaults[$key] ?? null);

        $record = self::find($key);
        if (!$record || $record->value === null) {
            return $fallback;
        }

        return is_array($record->value) && array_key_exists('val', $record->value)
            ? $record->value['val']
            : $record->value;
    }

    /**
     * Store or update a setting value.
     */
    public static function setValue(string $key, mixed $val): self
    {
        return self::updateOrCreate(
            ['key' => $key],
            ['value' => ['val' => $val]]
        );
    }

    /**
     * Get all effective settings merged with defaults.
     */
    public static function allEffective(): array
    {
        $result = self::defaults();
        foreach (self::all() as $row) {
            $val = is_array($row->value) && array_key_exists('val', $row->value)
                ? $row->value['val']
                : $row->value;
            $result[$row->key] = $val;
        }
        return $result;
    }
}

