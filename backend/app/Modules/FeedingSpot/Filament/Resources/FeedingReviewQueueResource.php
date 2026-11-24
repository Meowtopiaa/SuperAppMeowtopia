<?php

namespace App\Modules\FeedingSpot\Filament\Resources;

use App\Models\User;
use App\Modules\FeedingSpot\Models\FeedingActivity;
use App\Modules\FeedingSpot\Services\FeedingReviewService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

if (class_exists(\Filament\Resources\Resource::class)) {
    abstract class BaseFeedingReviewQueueResource extends \Filament\Resources\Resource {}
} else {
    abstract class BaseFeedingReviewQueueResource {}
}

/**
 * Filament Admin Resource untuk Antrean Review Pakan & Foto Bukti (MEOW-22).
 * Memakai FeedingReviewService yang sama dengan endpoint MEOW-12.
 */
class FeedingReviewQueueResource extends BaseFeedingReviewQueueResource
{
    protected static ?string $model = FeedingActivity::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';
    protected static ?string $navigationGroup = 'Adopt Feeding Spot';
    protected static ?string $navigationLabel = 'Antrean Review Pakan';
    protected static ?string $pluralModelLabel = 'Antrean Review Pakan';
    protected static ?int $navigationSort = 2;

    public const SUPPORTED_FLAGS = [
        'PHOTO_REUSED' => 'Foto Bukti Pernah Dipakai (SHA-256)',
        'TIME_MISMATCH' => 'Ketidaksesuaian Waktu Sesi',
        'FIRST_TWO_SUBMISSIONS' => '2 Pengajuan Pertama Pengguna Baru',
        'NEW_USER_SAMPLE' => 'Sampel Pengguna Baru (2 Pengajuan Pertama)',
        'RANDOM_SAMPLE' => 'Sampel Acak 10%',
        'HIGH_DAILY_FREQUENCY' => 'Frekuensi Pengajuan Harian Tinggi',
    ];

    /**
     * Hanya untuk pengguna dengan permission feeding.review (AFS-07, MEOW-22).
     */
    public static function canAccess(?User $user = null): bool
    {
        $actor = $user ?? auth()->user();

        return $actor instanceof User && $actor->can('feeding.review');
    }

    public static function canViewAny(?User $user = null): bool
    {
        return static::canAccess($user);
    }

    /**
     * Reviewer tidak boleh melihat/mereview pengajuan miliknya sendiri.
     */
    public static function canView(Model $record, ?User $user = null): bool
    {
        $actor = $user ?? auth()->user();
        if (!($actor instanceof User) || !$actor->can('feeding.review')) {
            return false;
        }

        if ($record instanceof FeedingActivity && $record->user_id === $actor->id) {
            return false;
        }

        return true;
    }

    /**
     * Query antrean UNDER_REVIEW dengan menyembunyikan pengajuan milik reviewer sendiri
     * dan tidak memuat data pribadi pengguna (tanpa phone/identity_number/email).
     */
    public static function getEloquentQuery(?User $reviewer = null): Builder
    {
        /** @var FeedingReviewService $service */
        $service = app(FeedingReviewService::class);
        $actor = $reviewer ?? (auth()->user() instanceof User ? auth()->user() : null);

        return $service->getReviewQueueQuery($actor, excludeSelf: true, status: 'UNDER_REVIEW');
    }

    public static function getNavigationBadge(?User $reviewer = null): ?string
    {
        $count = static::getEloquentQuery($reviewer)->count();

        return $count > 0 ? (string) $count : null;
    }

    public static function getNavigationBadgeColor(): ?string
    {
        return 'warning';
    }

    public static function getTableColumns(): array
    {
        return [
            'feeding_record_ref' => [
                'label' => 'Kode Referensi',
                'searchable' => true,
                'sortable' => true,
                'copyable' => true,
            ],
            'user.name' => [
                'label' => 'Nama Relawan / Feeder',
                'searchable' => true,
                'sortable' => true,
                'exposesPii' => false,
            ],
            'spot.name' => [
                'label' => 'Titik Pakan',
                'searchable' => true,
            ],
            'food_type' => [
                'label' => 'Jenis Pakan',
                'badge' => true,
            ],
            'food_amount' => [
                'label' => 'Porsi',
            ],
            'flags' => [
                'label' => 'Bendera Sistem',
                'badge' => true,
                'options' => self::SUPPORTED_FLAGS,
            ],
            'ruleResults' => [
                'label' => 'Hasil Mesin Aturan (feeding_rule_results)',
                'badge' => true,
            ],
            'evidence' => [
                'label' => 'Foto Bukti (Signed URL 10 Menit)',
                'signedUrlExpiresMinutes' => 10,
            ],
            'finalized_at' => [
                'label' => 'Waktu Pengajuan',
                'sortable' => true,
            ],
        ];
    }

    public static function getTableActions(): array
    {
        return [
            'inspect_evidence' => [
                'label' => 'Lihat Bukti Foto & Aturan',
                'icon' => 'heroicon-o-photo',
                'color' => 'info',
                'route' => 'admin.feeding.reviews.show',
            ],
            'approve' => [
                'label' => 'Setujui (VERIFIED)',
                'icon' => 'heroicon-o-check-circle',
                'color' => 'success',
                'requiresConfirmation' => true,
                'requiresReason' => true,
                'confirmationMessage' => 'Setujui sesi pemberian pakan ini dan kreditkan poin ke mahasiswa?',
            ],
            'reject' => [
                'label' => 'Tolak (REJECTED)',
                'icon' => 'heroicon-o-x-circle',
                'color' => 'danger',
                'requiresConfirmation' => true,
                'requiresReason' => true,
                'modalHeading' => 'Tolak Bukti Pakan',
            ],
        ];
    }

    /**
     * Eksekusi keputusan VERIFIED / REJECTED dari panel Filament melalui FeedingReviewService (sama dengan MEOW-12).
     */
    public static function submitDecision(
        FeedingActivity $activity,
        User $reviewer,
        string $decision,
        string $reason
    ): array {
        /** @var FeedingReviewService $service */
        $service = app(FeedingReviewService::class);

        return $service->reviewActivity($activity, $reviewer, $decision, $reason);
    }
}
