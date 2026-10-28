<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;

class ApiResponse
{
    /**
     * Standard success JSON response.
     */
    public static function success(mixed $data = null, string $message = 'Success', int $statusCode = 200): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'message' => $message,
            'data' => $data,
        ], $statusCode);
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
     */
    public static function error(string $message = 'An error occurred', int $statusCode = 400, mixed $errors = null): JsonResponse
    {
        $payload = [
            'status' => 'error',
            'message' => $message,
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
        return response()->json([
            'status' => 'success',
            'message' => $message,
            'data' => $paginator->items(),
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
                'has_more' => $paginator->hasMorePages(),
            ],
        ]);
    }
}
