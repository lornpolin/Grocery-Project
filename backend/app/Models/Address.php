<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Address extends Model
{
    protected $fillable = [
        'user_id',
        'label',
        'recipient_name',
        'phone',
        'address',
        'city',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'is_default' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /**
     * @return array{id: string, label: string, recipientName: string|null, phone: string|null, address: string, city: string|null, isDefault: bool}
     */
    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'label' => $this->label,
            'recipientName' => $this->recipient_name,
            'phone' => $this->phone,
            'address' => $this->address,
            'city' => $this->city,
            'isDefault' => (bool) $this->is_default,
        ];
    }
}
