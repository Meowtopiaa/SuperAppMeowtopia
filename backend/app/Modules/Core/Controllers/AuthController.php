<?php

namespace App\Modules\Core\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Core\Requests\LoginRequest;
use App\Modules\Core\Requests\RegisterRequest;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * User registration (students / adopters / volunteers)
     */
    public function register(RegisterRequest $request)
    {
        $validated = $request->validated();

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'student_id' => $validated['student_id'] ?? null,
            'role' => $validated['role'] ?? 'student',
            'phone' => $validated['phone'] ?? null,
            'points_balance' => 0,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return ApiResponse::created([
            'user' => $user,
            'token' => $token,
        ], 'Registration successful');
    }

    /**
     * User login
     */
    public function login(LoginRequest $request)
    {
        $validated = $request->validated();

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return ApiResponse::error('Invalid email or password credentials', 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return ApiResponse::success([
            'user' => $user,
            'token' => $token,
        ], 'Login successful');
    }

    /**
     * Get authenticated user profile
     */
    public function profile(Request $request)
    {
        return ApiResponse::success($request->user(), 'User profile retrieved successfully');
    }

    /**
     * Logout and revoke tokens
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(null, 'Logged out successfully');
    }
}
