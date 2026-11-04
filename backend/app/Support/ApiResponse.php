<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;

class ApiResponse
{
    /**
     * Standard success JSON response.
     * Format: { success: true, message: string, data: mixed, meta?: mixed }
     */
    public static function success(mixed $data = null, string $message = 'Success', int $statusCode = 200, mixed $meta = null): JsonResponse
    {
        $payload = [
            'success' => true,
            'message' => $message,
            'data' => $data,
        ];

        if ($meta !== null) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $statusCode);
    }

    /**
     * Standard created JSON response.
     */
    public static function created(mixed $data = null, string $message = 'Resource successfully created'): JsonResponse
    {
        return self::success($data, $message, 201);
    }

    /**
     * Standard error JSON response.
     * Format: { success: false, code: string, message: string, errors?: mixed, request_id: string }
     */
    public static function error(
        string $message = 'An error occurred',
        int $statusCode = 400,
        string $code = 'ERROR',
        mixed $errors = null,
        ?string $requestId = null
    ): JsonResponse {
        $payload = [
            'success' => false,
            'code' => $code,
            'message' => $message,
            'request_id' => $requestId ?? (string) Str::uuid(),
        ];

        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $statusCode);
    }

    /**
     * Standard paginated JSON response.
     */
    public static function paginated(mixed $paginator, string $message = 'Data retrieved successfully'): JsonResponse
    {
        $meta = [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
            'has_more' => $paginator->hasMorePages(),
        ];

        return self::success($paginator->items(), $message, 200, $meta);
    }
}
