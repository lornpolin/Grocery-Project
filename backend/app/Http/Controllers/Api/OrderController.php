<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use App\Models\CartItem;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    private const DELIVERY_FEE = 5.0;

    public function index(Request $request): JsonResponse
    {
        return response()->json(
            Order::with('items')->where('user_id', $request->user()->id)
                ->latest('id')->get()->map->toApi()->values()
        );
    }

    public function show(Request $request, Order $order): JsonResponse
    {
        abort_unless($order->user_id === $request->user()->id, 404);

        return response()->json($order->load('items')->toApi());
    }

    /** Creates an order from the user's cart, then clears the cart. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'address' => ['nullable', 'string', 'max:255'],
            'address_id' => ['nullable', 'integer', 'exists:addresses,id'],
        ]);
        $user = $request->user();

        $cart = CartItem::with('product')->where('user_id', $user->id)->get();
        if ($cart->isEmpty()) {
            return response()->json(['message' => 'Cart is empty'], 422);
        }

        $order = DB::transaction(function () use ($cart, $user, $data) {
            foreach ($cart as $item) {
                $updated = Product::where('id', $item->product_id)
                    ->where('stock_quantity', '>=', $item->quantity)
                    ->decrement('stock_quantity', $item->quantity);
                if (! $updated) {
                    abort(response()->json(['message' => "Not enough stock for {$item->product->name}"], 422));
                }
            }

            $addressId = null;
            $addressText = $data['address'] ?? null;

            if (! empty($data['address_id'])) {
                $savedAddress = Address::where('user_id', $user->id)->find($data['address_id']);
                if ($savedAddress) {
                    $addressId = $savedAddress->id;
                    $addressText = $addressText ?? $savedAddress->address;
                }
            } elseif (! empty($addressText)) {
                $hasAny = Address::where('user_id', $user->id)->exists();
                $savedAddress = Address::firstOrCreate(
                    ['user_id' => $user->id, 'address' => $addressText],
                    ['label' => 'Home', 'recipient_name' => $user->name, 'is_default' => ! $hasAny]
                );
                $addressId = $savedAddress->id;
            }

            $subtotal = $cart->sum(fn ($i) => $i->product->price * $i->quantity);

            $order = Order::create([
                'user_id' => $user->id,
                'subtotal' => $subtotal,
                'delivery_fee' => self::DELIVERY_FEE,
                'total' => $subtotal + self::DELIVERY_FEE,
                'status' => 'pending',
                'address_id' => $addressId,
                'address' => $addressText,
            ]);

            foreach ($cart as $item) {
                $order->items()->create([
                    'product_id' => $item->product_id,
                    'product_name' => $item->product->name,
                    'price' => $item->product->price,
                    'quantity' => $item->quantity,
                ]);
            }

            CartItem::where('user_id', $user->id)->delete();

            return $order;
        });

        return response()->json($order->load('items')->toApi(), 201);
    }
}
