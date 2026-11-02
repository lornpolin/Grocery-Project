<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
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

    public function updateProfile(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($user->id),
            ],
            'phone' => ['nullable', 'string', 'max:50'],
            'avatar' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp,gif', 'max:5120'],
            'remove_avatar' => ['nullable', 'boolean'],
            'current_password' => ['nullable', 'required_with:new_password', 'string'],
            'new_password' => ['nullable', 'string', 'min:6'],
        ]);

        if ($request->hasFile('avatar')) {
            if ($user->avatar && ! str_starts_with($user->avatar, 'http')) {
                Storage::disk('public')->delete($user->avatar);
            }
            $user->avatar = $request->file('avatar')->store('avatars', 'public');
        } elseif ($request->boolean('remove_avatar')) {
            if ($user->avatar && ! str_starts_with($user->avatar, 'http')) {
                Storage::disk('public')->delete($user->avatar);
            }
            $user->avatar = null;
        }

        if (! empty($data['new_password'])) {
            if (! Hash::check($data['current_password'] ?? '', $user->password)) {
                throw ValidationException::withMessages([
                    'current_password' => ['Your current password is incorrect.'],
                ]);
            }
            $user->password = $data['new_password'];
        }

        $user->name = $data['name'];
        $user->email = $data['email'];
        if ($request->has('phone')) {
            $phone = trim((string) ($data['phone'] ?? ''));
            $user->phone = $phone !== '' ? $phone : null;
        }
        $user->save();

        return response()->json($this->userData($user));
    }

    /**
     * @return array{token: string, expiresAt: string, user: array{id: string, name: string, email: string, phone: ?string, avatarUrl: ?string}}
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
     * @return array{id: string, name: string, email: string, phone: ?string, avatarUrl: ?string}
     */
    private function userData(User $user): array
    {
        return [
            'id' => (string) $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatarUrl' => $user->avatarUrl(),
        ];
    }
}
