<?php

namespace App\Modules\FeedingSpot\Filament\Resources;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use Illuminate\Database\Eloquent\Builder;

if (class_exists(\Filament\Resources\Resource::class)) {
    abstract class BaseFeedingReviewQueueResource extends \Filament\Resources\Resource {}
} else {
    abstract class BaseFeedingReviewQueueResource {}
}

/**
 * Filament Admin Resource untuk Antrean Review Pakan & Foto Bukti (MEOW-22).
 */
class FeedingReviewQueueResource extends BaseFeedingReviewQueueResource
{
    protected static ?string $model = FeedingActivity::class;

    protected static ?string $navigationIcon = 'heroicon-o-clipboard-document-check';
    protected static ?string $navigationGroup = 'Adopt Feeding Spot';
    protected static ?string $navigationLabel = 'Antrean Review Pakan';
    protected static ?string $pluralModelLabel = 'Antrean Review Pakan';
    protected static ?int $navigationSort = 2;

    public static function getEloquentQuery(): Builder
    {
        return FeedingActivity::query()
            ->where('status', 'UNDER_REVIEW')
            ->with(['user', 'spot', 'evidence', 'ruleResults']);
    }

    public static function getNavigationBadge(): ?string
    {
        $count = FeedingActivity::where('status', 'UNDER_REVIEW')->count();
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
                'confirmationMessage' => 'Setujui sesi pemberian pakan ini dan kreditkan poin ke mahasiswa?',
            ],
            'reject' => [
                'label' => 'Tolak (REJECTED)',
                'icon' => 'heroicon-o-x-circle',
                'color' => 'danger',
                'requiresConfirmation' => true,
                'modalHeading' => 'Tolak Bukti Pakan',
                'requiresReason' => true,
            ],
        ];
    }
}
