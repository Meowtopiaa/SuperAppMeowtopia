<?php

namespace App\Modules\CatAdoption\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Cat\Models\Cat;
use App\Modules\CatAdoption\Models\Adoption;
use App\Modules\CatAdoption\Models\AdoptionApplication;
use App\Modules\CatAdoption\Models\AdoptionPickupLock;
use App\Modules\Core\Services\ScanResolver;
use App\Support\ApiResponse;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Pengambilan adopsi (ADP-06, ADP-07). Penahanan disimpan di adoption_pickup_locks;
 * adoption_status tetap READY sampai confirm (PRD 5.3).
 */
class PickupController extends Controller
{
    public function start(Request $request, ScanResolver $resolver)
    {
        $validator = validator($request->all(), ['cat_code' => ['required', 'string', 'max:255']]);
        if ($validator->fails()) {
            return ApiResponse::error('Data yang dikirim tidak valid.', 422, 'VALIDATION_ERROR', $validator->errors());
        }

        try {
            $scan = $resolver->resolve($request->input('cat_code'));
        } catch (HttpException $e) {
            // ScanResolver memakai pesan "KODE: penjelasan".
            [$code, $message] = array_pad(explode(': ', $e->getMessage(), 2), 2, null);

            return ApiResponse::error($message ?? $e->getMessage(), 422, $message ? $code : 'QR_INVALID');
        }

        if ($scan['type'] !== 'cat') {
            return ApiResponse::error('Kode ini bukan QR kalung kucing.', 422, 'QR_WRONG_TYPE');
        }

        $user = $request->user();

        try {
            $lock = DB::transaction(fn () => $this->hold($user, $scan['id']));
        } catch (UniqueConstraintViolationException) {
            // Cadangan bila dua permintaan bersamaan lolos pemeriksaan: indeks unik HELD menolak yang kedua.
            return ApiResponse::error('Kucing ini sedang ditahan pengguna lain.', 409, 'CAT_NOT_AVAILABLE');
        }

        return ApiResponse::success([
            'pickup_lock_id' => $lock->id,
            'cat_id' => $lock->cat_id,
            'expires_at' => $lock->expires_at->toIso8601String(),
        ], 'Kucing ditahan untukmu sampai batas waktu pengambilan.');
    }

    private function hold(User $user, string $catId): AdoptionPickupLock
    {
        User::whereKey($user->id)->lockForUpdate()->first();
        $cat = Cat::lockForUpdate()->findOrFail($catId);

        // Lock habis tetap HELD di tabel; lepaskan dulu agar indeks unik HELD tidak memblokir.
        AdoptionPickupLock::where('status', AdoptionPickupLock::STATUS_HELD)
            ->where('expires_at', '<=', now())
            ->where(fn ($q) => $q->where('cat_id', $cat->id)->orWhere('adopter_id', $user->id))
            ->update(['status' => AdoptionPickupLock::STATUS_RELEASED]);

        if (! AdoptionApplication::where('applicant_id', $user->id)->validApproval()->exists()) {
            $this->fail(403, 'FORBIDDEN', 'Kamu belum memiliki kelayakan adopsi yang disetujui dan masih berlaku.');
        }

        $adoptions = Adoption::where('adopter_id', $user->id);
        if ((clone $adoptions)->open()->exists()) {
            $this->fail(409, 'ALREADY_ADOPTING', 'Kamu masih memiliki adopsi yang berjalan.');
        }
        if ((clone $adoptions)->where('rehome_cooldown_until', '>', now())->exists()) {
            $this->fail(409, 'COOLDOWN_ACTIVE', 'Kamu masih dalam masa tunggu setelah pengembalian.');
        }

        $mine = AdoptionPickupLock::active()->where('adopter_id', $user->id)->first();
        if ($mine !== null) {
            if ($mine->cat_id === $cat->id) {
                return $mine;
            }
            $this->fail(409, 'CONFLICT', 'Kamu sedang menahan kucing lain. Selesaikan atau tunggu penahanan itu berakhir.');
        }

        $available = $cat->adoption_status === 'READY'
            && $cat->presence_status === 'ON_CAMPUS'
            && ! Adoption::open()->where('cat_id', $cat->id)->exists()
            && ! AdoptionPickupLock::active()->where('cat_id', $cat->id)->exists();
        if (! $available) {
            $this->fail(409, 'CAT_NOT_AVAILABLE', 'Kucing ini sedang tidak tersedia untuk diadopsi.');
        }

        return AdoptionPickupLock::create([
            'cat_id' => $cat->id,
            'adopter_id' => $user->id,
            'expires_at' => now()->addHours(AdoptionPickupLock::DEFAULT_HOLD_HOURS),
        ]);
    }

    private function fail(int $status, string $code, string $message): never
    {
        throw new HttpResponseException(ApiResponse::error($message, $status, $code));
    }
}
