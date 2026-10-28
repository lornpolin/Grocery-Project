<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    private const TOKEN_EXPIRATION_DAYS = 30;

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $user = User::create($data);

        return response()->json($this->payload($user), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        return response()->json($this->payload($user));
    }

    /**
     * Reset/refresh a bearer token (even if expired) and issue a new 30-day token.
     */
    public function refresh(Request $request): JsonResponse
    {
        $bearerToken = $request->bearerToken();
        $accessToken = $bearerToken ? PersonalAccessToken::findToken($bearerToken) : null;
        $user = $accessToken?->tokenable;

        if (! $accessToken || ! ($user instanceof User)) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $accessToken->delete();

        return response()->json($this->payload($user));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($this->userData($request->user()));
    }

    /**
     * @return array{token: string, expiresAt: string, user: array{id: string, name: string, email: string}}
     */
    private function payload(User $user): array
    {
        $user->tokens()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<=', now())
            ->delete();

        $expiresAt = now()->addDays(self::TOKEN_EXPIRATION_DAYS);

        return [
            'token' => $user->createToken('mobile', ['*'], $expiresAt)->plainTextToken,
            'expiresAt' => $expiresAt->toIso8601String(),
            'user' => $this->userData($user),
        ];
    }

    /**
     * @return array{id: string, name: string, email: string}
     */
    private function userData(User $user): array
    {
        return ['id' => (string) $user->id, 'name' => $user->name, 'email' => $user->email];
    }
}
