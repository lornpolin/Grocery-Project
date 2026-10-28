<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    public const STATUSES = [
        'pending' => 'Pending',
        'confirmed' => 'Confirmed',
        'delivering' => 'Delivering',
        'delivered' => 'Delivered',
        'cancelled' => 'Cancelled',
    ];

    /** Next step in the fulfilment flow (used by the admin quick action). */
    public const NEXT_STATUS = [
        'pending' => 'confirmed',
        'confirmed' => 'delivering',
        'delivering' => 'delivered',
    ];

    protected $fillable = ['user_id', 'subtotal', 'delivery_fee', 'total', 'status', 'address_id', 'address'];

    protected static function booted(): void
    {
        // Put stock back when an order is cancelled.
        static::updating(function (Order $order) {
            if ($order->isDirty('status')
                && $order->status === 'cancelled'
                && $order->getOriginal('status') !== 'cancelled') {
                foreach ($order->items as $item) {
                    if ($item->product_id) {
                        Product::where('id', $item->product_id)->increment('stock_quantity', $item->quantity);
                    }
                }
            }
        });
    }

    protected function casts(): array
    {
        return [
            'subtotal' => 'float',
            'delivery_fee' => 'float',
            'total' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function addressRecord(): BelongsTo
    {
        return $this->belongsTo(Address::class, 'address_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'subtotal' => $this->subtotal,
            'deliveryFee' => $this->delivery_fee,
            'total' => $this->total,
            'status' => $this->status,
            'address' => $this->address,
            'createdAt' => $this->created_at?->toIso8601String(),
            'items' => $this->items->map(fn ($i) => [
                'productId' => (string) $i->product_id,
                'name' => $i->product_name,
                'price' => $i->price,
                'quantity' => $i->quantity,
            ])->values(),
        ];
    }
}
