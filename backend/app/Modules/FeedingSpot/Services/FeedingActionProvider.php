<?php

namespace App\Modules\FeedingSpot\Services;

use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\Core\Contracts\CatActionProviderInterface;
use Illuminate\Support\Facades\DB;

class FeedingActionProvider implements CatActionProviderInterface
{
    /**
     * Provide available feeding action for a specific cat and authenticated user.
     * Sesuai PRD Bagian 4.3 (Kontrak Lintas-Modul: Hub Scan):
     * Aksi 'feeding.start' hanya tampil/aktif jika kucing terkait dengan spot pakan aktif.
     */
    public function actionsFor(Cat $cat, ?User $user): array
    {
        $spots = DB::table('feeding_spot_cats')
            ->join('feeding_spots', 'feeding_spot_cats.spot_id', '=', 'feeding_spots.id')
            ->where('feeding_spot_cats.cat_id', $cat->id)
            ->where('feeding_spots.status', 'ACTIVE')
            ->select('feeding_spots.id', 'feeding_spots.code', 'feeding_spots.name')
            ->get();

        $isLinked = $spots->isNotEmpty();
        $isOnCampus = $cat->presence_status === 'ON_CAMPUS';

        $enabled = $isLinked && $isOnCampus;
        $reason = null;

        if (!$isLinked) {
            $reason = 'Kucing ini belum diasosiasikan dengan spot pakan aktif.';
        } elseif (!$isOnCampus) {
            $reason = 'Kucing sedang tidak berada di kampus.';
        }

        return [
            [
                'id' => 'feeding.start',
                'module' => 'FeedingSpot',
                'label' => 'Beri Makan di Spot',
                'enabled' => $enabled,
                'reason' => $reason,
                'spots' => $spots->map(fn($s) => [
                    'id' => $s->id,
                    'code' => $s->code,
                    'name' => $s->name,
                ])->values()->all(),
            ],
        ];
    }
}

