<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    protected $fillable = [
        'category_id', 'name', 'description', 'images', 'image_url',
        'price', 'original_price', 'unit', 'stock_quantity',
    ];

    protected static function booted(): void
    {
        static::saving(function (Product $product) {
            if (! empty($product->images)) {
                $first = array_values($product->images)[0];
                $product->image_url = url('api/media/'.ltrim($first, '/'));
            }
        });

        static::saved(function (Product $product) {
            $paths = array_values(array_filter($product->images ?? []));
            if (! $paths && $product->image_url) {
                $paths = [$product->image_url];
            }

            $product->productImages()->delete();
            foreach ($paths as $index => $path) {
                $product->productImages()->create([
                    'image_path' => $path,
                    'sort_order' => $index,
                    'is_primary' => $index === 0,
                ]);
            }
        });

        // Remove uploaded files together with the product.
        static::deleting(function (Product $product) {
            foreach ($product->images ?? [] as $path) {
                Storage::disk('public')->delete($path);
            }
        });
    }

    protected function casts(): array
    {
        return [
            'images' => 'array',
            'price' => 'float',
            'original_price' => 'float',
            'stock_quantity' => 'integer',
        ];
    }

    /**
     * Absolute image URLs. Built from the current request host so the same
     * response works for localhost, LAN IPs and the Android emulator (10.0.2.2).
     * Falls back to the legacy image_url for products without uploads.
     */
    public function imageUrls(): array
    {
        $urls = collect($this->images ?? [])
            ->map(fn ($path) => url('api/media/'.ltrim($path, '/')))
            ->values()
            ->all();

        if (! $urls && $this->image_url) {
            $urls = [$this->image_url];
        }

        return $urls;
    }

    public function productImages(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('sort_order');
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    /** Shape expected by the Flutter Product model. */
    public function toApi(bool $isFavorite = false): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'description' => $this->description,
            'imageUrl' => $this->imageUrls()[0] ?? '',
            'images' => $this->imageUrls(),
            'price' => $this->price,
            'originalPrice' => $this->original_price,
            'unit' => $this->unit,
            'categoryId' => (string) $this->category_id,
            'stockQuantity' => $this->stock_quantity,
            'isFavorite' => $isFavorite,
        ];
    }
}
