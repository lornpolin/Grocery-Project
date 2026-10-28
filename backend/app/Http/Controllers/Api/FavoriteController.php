<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $ids = Favorite::where('user_id', $request->user()->id)->pluck('product_id');

        return response()->json(
            Product::whereIn('id', $ids)->get()->map(fn (Product $p) => $p->toApi(true))->values()
        );
    }

    /** Toggles favorite state and returns the new state. */
    public function toggle(Request $request, Product $product): JsonResponse
    {
        $attrs = ['user_id' => $request->user()->id, 'product_id' => $product->id];
        $existing = Favorite::where($attrs)->first();

        if ($existing) {
            $existing->delete();
            return response()->json(['isFavorite' => false]);
        }

        Favorite::create($attrs);

        return response()->json(['isFavorite' => true]);
    }
}
