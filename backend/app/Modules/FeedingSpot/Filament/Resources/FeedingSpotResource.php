<?php

namespace App\Modules\FeedingSpot\Filament\Resources;

use App\Modules\FeedingSpot\Models\FeedingSpot;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

if (class_exists(\Filament\Resources\Resource::class)) {
    abstract class BaseFeedingSpotResource extends \Filament\Resources\Resource {}
} else {
    abstract class BaseFeedingSpotResource {}
}

/**
 * Filament Admin Resource untuk manajemen Titik Makan (Spots) & Cetak QR (MEOW-21).
 */
class FeedingSpotResource extends BaseFeedingSpotResource
{
    protected static ?string $model = FeedingSpot::class;

    protected static ?string $navigationIcon = 'heroicon-o-map-pin';
    protected static ?string $navigationGroup = 'Adopt Feeding Spot';
    protected static ?string $navigationLabel = 'Titik Makan (Spots)';
    protected static ?string $pluralModelLabel = 'Titik Makan Resmi';
    protected static ?int $navigationSort = 1;

    public static function getFormSchema(): array
    {
        return [
            'code' => [
                'type' => 'text',
                'label' => 'Kode Unik Spot',
                'required' => true,
                'unique' => 'feeding_spots,code',
                'placeholder' => 'SPOT-TULT-01',
            ],
            'name' => [
                'type' => 'text',
                'label' => 'Nama Spot',
                'required' => true,
                'placeholder' => 'Spot Pakan TULT Lobby Barat',
            ],
            'description' => [
                'type' => 'textarea',
                'label' => 'Deskripsi Lokasi & Petunjuk Akses',
                'nullable' => true,
            ],
            'latitude' => [
                'type' => 'numeric',
                'label' => 'Latitude (WGS84)',
                'required' => true,
            ],
            'longitude' => [
                'type' => 'numeric',
                'label' => 'Longitude (WGS84)',
                'required' => true,
            ],
            'status' => [
                'type' => 'select',
                'label' => 'Status Operasional',
                'options' => [
                    'ACTIVE' => 'Aktif (Menerima Pemberian Pakan)',
                    'MAINTENANCE' => 'Dalam Perawatan / Pembersihan',
                    'TEMPORARILY_UNAVAILABLE' => 'Sementara Tidak Tersedia',
                    'INACTIVE' => 'Nonaktif Permanen',
                ],
                'default' => 'ACTIVE',
            ],
            'status_reason' => [
                'type' => 'text',
                'label' => 'Alasan Status (Jika Tidak Tersedia)',
                'nullable' => true,
            ],
        ];
    }

    public static function getTableColumns(): array
    {
        return [
            'code' => [
                'label' => 'Kode Spot',
                'searchable' => true,
                'sortable' => true,
                'copyable' => true,
            ],
            'name' => [
                'label' => 'Nama Spot',
                'searchable' => true,
                'sortable' => true,
            ],
            'status' => [
                'label' => 'Status',
                'badge' => true,
                'colors' => [
                    'success' => 'ACTIVE',
                    'warning' => ['MAINTENANCE', 'TEMPORARILY_UNAVAILABLE'],
                    'danger' => 'INACTIVE',
                ],
            ],
            'last_fed_at' => [
                'label' => 'Terakhir Diberi Makan',
                'sortable' => true,
            ],
            'verified_count_14d' => [
                'label' => 'Pemberian (14 Hari)',
            ],
        ];
    }

    public static function getTableActions(): array
    {
        return [
            'print_qr' => [
                'label' => 'Cetak Lembar QR',
                'icon' => 'heroicon-o-printer',
                'color' => 'info',
                'route' => 'admin.feeding.spots.qr-sheet',
            ],
            'regenerate_qr' => [
                'label' => 'Regenerasi QR',
                'icon' => 'heroicon-o-arrow-path',
                'color' => 'warning',
                'requiresConfirmation' => true,
            ],
        ];
    }
}
