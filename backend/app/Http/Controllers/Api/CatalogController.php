<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Favorite;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json(Category::orderBy('id')->get()->map->toApi()->values());
    }

    public function products(Request $request): JsonResponse
    {
        $query = Product::query();

        if ($request->filled('category')) {
            $query->where('category_id', $request->query('category'));
        }
        if ($request->filled('q')) {
            $query->where('name', 'like', '%'.$request->query('q').'%');
        }

        $favorites = $this->favoriteIds($request);

        return response()->json(
            $query->orderBy('id')->get()
                ->map(fn (Product $p) => $p->toApi(in_array($p->id, $favorites, true)))
                ->values()
        );
    }

    public function product(Request $request, Product $product): JsonResponse
    {
        return response()->json(
            $product->toApi(in_array($product->id, $this->favoriteIds($request), true))
        );
    }

    /** Products are public; favorites flag is filled in only if a valid token is sent. */
    private function favoriteIds(Request $request): array
    {
        $user = $request->user('sanctum');

        return $user ? Favorite::where('user_id', $user->id)->pluck('product_id')->all() : [];
    }
}
