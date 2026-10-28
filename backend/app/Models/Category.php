<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Category extends Model
{
    protected $fillable = ['name', 'icon_asset'];

    protected static function booted(): void
    {
        static::deleting(function (Category $category) {
            if ($category->icon_asset
                && ! str_starts_with($category->icon_asset, 'assets/')
                && ! str_starts_with($category->icon_asset, 'http://')
                && ! str_starts_with($category->icon_asset, 'https://')) {
                Storage::disk('public')->delete($category->icon_asset);
            }

            $category->products->each->delete();
        });
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function iconUrl(): ?string
    {
        if (! $this->icon_asset) {
            return null;
        }

        if (str_starts_with($this->icon_asset, 'assets/')
            || str_starts_with($this->icon_asset, 'http://')
            || str_starts_with($this->icon_asset, 'https://')) {
            return $this->icon_asset;
        }

        return url('api/media/'.ltrim($this->icon_asset, '/'));
    }

    /**
     * Shape expected by the Flutter Category model.
     *
     * @return array{id: string, name: string, iconAsset: string|null}
     */
    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'iconAsset' => $this->iconUrl(),
        ];
    }
}
