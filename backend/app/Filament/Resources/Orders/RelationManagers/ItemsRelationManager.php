<?php

namespace App\Filament\Resources\Orders\RelationManagers;

use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ItemsRelationManager extends RelationManager
{
    protected static string $relationship = 'items';

    protected static ?string $title = 'Order items';

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('product_name')
            ->columns([
                TextColumn::make('product_name')->label('Product'),
                TextColumn::make('price')->money('USD'),
                TextColumn::make('quantity'),
                TextColumn::make('line_total')
                    ->label('Subtotal')
                    ->state(fn ($record) => $record->price * $record->quantity)
                    ->money('USD'),
            ])
            ->paginated(false);
    }
}
