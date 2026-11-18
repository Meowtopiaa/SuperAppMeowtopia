<?php

namespace App\Modules\CatAdoption\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * ADP-01: endpoint mahasiswa adopsi hanya untuk user_type MAHASISWA dengan email terverifikasi.
 */
class EnsureVerifiedStudent
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // NOT_STUDENT didahulukan: verifikasi email tidak mengubah hasilnya bagi dosen/staf.
        if ($user->user_type !== 'MAHASISWA') {
            return ApiResponse::error('Hanya mahasiswa yang dapat menggunakan fitur adopsi.', 403, 'NOT_STUDENT');
        }

        if ($user->email_verified_at === null) {
            return ApiResponse::error('Verifikasi email kampus terlebih dahulu untuk menggunakan fitur adopsi.', 403, 'EMAIL_NOT_VERIFIED');
        }

        return $next($request);
    }
}
