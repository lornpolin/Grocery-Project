<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    protected $fillable = ['order_id', 'product_id', 'product_name', 'price', 'quantity'];

    protected function casts(): array
    {
        return ['price' => 'float'];
    }
}
