<?php

namespace App\Modules\Core\Middleware;

use App\Support\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class RequireIdempotencyKey
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $idempotencyKey = $request->header('Idempotency-Key');

        if (!$idempotencyKey) {
            return ApiResponse::error(
                'Header Idempotency-Key wajib disertakan untuk operasi ini.',
                400,
                'VALIDATION_ERROR'
            );
        }

        $user = $request->user();
        if (!$user) {
            return ApiResponse::error('Autentikasi diperlukan.', 401, 'FORBIDDEN');
        }

        $route = $request->path();
        $requestHash = hash('sha256', $request->getContent() ?: json_encode($request->all()));

        // Check if key already exists for this user and route
        $cached = DB::table('idempotency_keys')
            ->where('user_id', $user->id)
            ->where('key', $idempotencyKey)
            ->where('route', $route)
            ->first();

        if ($cached) {
            // Check request payload consistency
            if ($cached->request_hash !== $requestHash) {
                return ApiResponse::error(
                    'Idempotency key telah digunakan dengan payload berbeda.',
                    409,
                    'CONFLICT'
                );
            }

            // Return cached response
            $body = json_decode($cached->response_body, true);
            return response()->json($body, $cached->response_code);
        }

        // Process request
        $response = $next($request);

        // Store successful mutations (200, 201, 202)
        if (in_array($response->getStatusCode(), [200, 201, 202], true)) {
            $body = $response->getContent();
            DB::table('idempotency_keys')->insert([
                'id' => (string) Str::ulid(),
                'user_id' => $user->id,
                'key' => $idempotencyKey,
                'route' => $route,
                'request_hash' => $requestHash,
                'response_code' => $response->getStatusCode(),
                'response_body' => $body,
                'expires_at' => now()->addHours(24),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return $response;
    }
}

