<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CartItem;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CartController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json($this->items($request));
    }

    /** Adds quantity to the product's cart line (creates it if missing). */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'product_id' => ['required', 'exists:products,id'],
            'quantity' => ['sometimes', 'integer', 'min:1'],
        ]);

        $product = Product::findOrFail($data['product_id']);
        if ($product->stock_quantity <= 0) {
            return response()->json([
                'message' => "{$product->name} is out of stock",
            ], 422);
        }

        $item = CartItem::firstOrNew([
            'user_id' => $request->user()->id,
            'product_id' => $product->id,
        ]);
        $newQuantity = ($item->exists ? $item->quantity : 0) + ($data['quantity'] ?? 1);
        if ($newQuantity > $product->stock_quantity) {
            return response()->json([
                'message' => "Only {$product->stock_quantity} left in stock for {$product->name}",
            ], 422);
        }

        $item->quantity = $newQuantity;
        $item->save();

        return response()->json($this->items($request), 201);
    }

    /** Sets an absolute quantity; 0 removes the line. */
    public function update(Request $request, Product $product): JsonResponse
    {
        $data = $request->validate(['quantity' => ['required', 'integer', 'min:0']]);

        $query = CartItem::where('user_id', $request->user()->id)->where('product_id', $product->id);
        if ($data['quantity'] === 0) {
            $query->delete();
        } else {
            if ($product->stock_quantity <= 0) {
                return response()->json([
                    'message' => "{$product->name} is out of stock",
                ], 422);
            }
            if ($data['quantity'] > $product->stock_quantity) {
                return response()->json([
                    'message' => "Only {$product->stock_quantity} left in stock for {$product->name}",
                ], 422);
            }
            $query->update(['quantity' => $data['quantity']]);
        }

        return response()->json($this->items($request));
    }

    public function destroy(Request $request, Product $product): JsonResponse
    {
        CartItem::where('user_id', $request->user()->id)->where('product_id', $product->id)->delete();

        return response()->json($this->items($request));
    }

    public function clear(Request $request): JsonResponse
    {
        CartItem::where('user_id', $request->user()->id)->delete();

        return response()->json([]);
    }

    private function items(Request $request)
    {
        return CartItem::with('product')
            ->where('user_id', $request->user()->id)
            ->orderBy('id')->get()->map->toApi()->values();
    }
}
