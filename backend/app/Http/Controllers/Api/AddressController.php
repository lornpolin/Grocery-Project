<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AddressController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json($this->addresses($request));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'label' => ['sometimes', 'string', 'max:100'],
            'recipient_name' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['required', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'is_default' => ['sometimes', 'boolean'],
        ]);

        $user = $request->user();
        $hasExisting = Address::where('user_id', $user->id)->exists();
        $isDefault = (bool) ($data['is_default'] ?? ! $hasExisting);

        if ($isDefault) {
            Address::where('user_id', $user->id)->update(['is_default' => false]);
        }

        $address = Address::create([
            'user_id' => $user->id,
            'label' => $data['label'] ?? 'Home',
            'recipient_name' => $data['recipient_name'] ?? $user->name,
            'phone' => $data['phone'] ?? null,
            'address' => $data['address'],
            'city' => $data['city'] ?? null,
            'is_default' => $isDefault,
        ]);

        return response()->json($address->toApi(), 201);
    }

    public function update(Request $request, Address $address): JsonResponse
    {
        abort_unless($address->user_id === $request->user()->id, 404);

        $data = $request->validate([
            'label' => ['sometimes', 'string', 'max:100'],
            'recipient_name' => ['nullable', 'string', 'max:255'],
            'phone' => ['nullable', 'string', 'max:50'],
            'address' => ['sometimes', 'required', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:100'],
            'is_default' => ['sometimes', 'boolean'],
        ]);

        if (! empty($data['is_default'])) {
            Address::where('user_id', $request->user()->id)
                ->where('id', '!=', $address->id)
                ->update(['is_default' => false]);
        }

        $address->update($data);

        return response()->json($address->fresh()->toApi());
    }

    public function destroy(Request $request, Address $address): JsonResponse
    {
        abort_unless($address->user_id === $request->user()->id, 404);

        $address->delete();

        return response()->json($this->addresses($request));
    }

    private function addresses(Request $request)
    {
        return Address::where('user_id', $request->user()->id)
            ->orderByDesc('is_default')
            ->orderByDesc('id')
            ->get()
            ->map->toApi()
            ->values();
    }
}
