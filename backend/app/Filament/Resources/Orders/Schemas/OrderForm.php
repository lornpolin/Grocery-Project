<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Order;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                Select::make('user_id')
                    ->label('Customer')
                    ->relationship('user', 'name')
                    ->disabled(),
                Select::make('status')
                    ->options(Order::STATUSES)
                    ->required()
                    ->native(false),
                TextInput::make('address')
                    ->columnSpanFull(),
                TextInput::make('subtotal')->prefix('$')->disabled(),
                TextInput::make('delivery_fee')->prefix('$')->disabled(),
                TextInput::make('total')->prefix('$')->disabled(),
            ]);
    }
}
