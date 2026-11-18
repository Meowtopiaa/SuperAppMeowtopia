<?php

namespace App\Modules\CatAdoption\Models;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

/**
 * Aplikasi kelayakan adopter (PRD 5.2). Terpisah dari transaksi adopsi (FIX-06):
 * cat_id boleh kosong dan APPROVED bukan adopsi aktif.
 */
class AdoptionApplication extends Model
{
    use HasFactory, HasUlids;

    public const STATUS_DRAFT = 'DRAFT';
    public const STATUS_SUBMITTED = 'SUBMITTED';
    public const STATUS_REVISION_REQUESTED = 'REVISION_REQUESTED';
    public const STATUS_APPROVED = 'APPROVED';
    public const STATUS_REJECTED = 'REJECTED';

    public const STATUSES = [
        self::STATUS_DRAFT,
        self::STATUS_SUBMITTED,
        self::STATUS_REVISION_REQUESTED,
        self::STATUS_APPROVED,
        self::STATUS_REJECTED,
    ];

    /** Status yang masih bisa diubah oleh pemohon. */
    public const EDITABLE_STATUSES = [
        self::STATUS_DRAFT,
        self::STATUS_REVISION_REQUESTED,
    ];

    /** Masa berlaku kelayakan APPROVED (PRD OQ-09). shortcut: konstanta, pindah ke pengaturan adopsi bila tabelnya ada. */
    public const ELIGIBILITY_VALID_DAYS = 30;

    /** Versi komitmen adopter yang berlaku (ADP-02). shortcut: konstanta, pindah ke pengaturan adopsi bila tabelnya ada. */
    public const COMMITMENT_VERSION = '1.0';

    protected $keyType = 'string';
    public $incrementing = false;

    protected $attributes = [
        'status' => self::STATUS_DRAFT,
    ];

    protected $fillable = [
        'applicant_id',
        'cat_id',
        'housing_type',
        'owner_permission',
        'can_afford',
        'long_term_plan',
        'answers',
        'commitment_version',
        'commitment_accepted_at',
        'precheck_passed',
        'status',
        'submitted_at',
        'reviewed_by',
        'reviewed_at',
        'review_note',
    ];

    protected $casts = [
        'owner_permission' => 'boolean',
        'can_afford' => 'boolean',
        'precheck_passed' => 'boolean',
        'answers' => 'array',
        'commitment_accepted_at' => 'datetime',
        'submitted_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    public function applicant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'applicant_id');
    }

    public function cat(): BelongsTo
    {
        return $this->belongsTo(Cat::class, 'cat_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    /** Foto tempat tinggal (privat: hanya pemilik dan adoption_admin). */
    public function media(): HasMany
    {
        return $this->hasMany(AdoptionApplicationMedia::class, 'application_id');
    }

    public function adoption(): HasOne
    {
        return $this->hasOne(Adoption::class, 'application_id');
    }

    /** Aplikasi yang masih berjalan atau kelayakan APPROVED yang belum kedaluwarsa. */
    public function scopeBlocking(Builder $query): Builder
    {
        return $query->where(function (Builder $q) {
            $q->whereIn('status', [self::STATUS_DRAFT, self::STATUS_SUBMITTED, self::STATUS_REVISION_REQUESTED])
                ->orWhere(fn (Builder $approved) => $approved
                    ->where('status', self::STATUS_APPROVED)
                    ->where('reviewed_at', '>', now()->subDays(self::ELIGIBILITY_VALID_DAYS)));
        });
    }

    public function isEditable(): bool
    {
        return in_array($this->status, self::EDITABLE_STATUSES, true);
    }
}
