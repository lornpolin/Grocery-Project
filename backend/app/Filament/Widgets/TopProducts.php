<?php

namespace App\Filament\Widgets;

use App\Models\OrderItem;
use App\Models\Product;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

class TopProducts extends TableWidget
{
    protected static ?int $sort = 4;

    protected static ?string $heading = 'Top selling products';

    public function table(Table $table): Table
    {
        return $table
            ->query(fn (): Builder => Product::query()
                ->withSum(['orderItems as sold' => fn ($q) => $q->whereHas('order', fn ($o) => $o->where('status', '!=', 'cancelled'))], 'quantity')
                ->orderByDesc('sold')
                ->limit(5))
            ->columns([
                TextColumn::make('name'),
                TextColumn::make('sold')->label('Units sold')->default(0)->badge(),
                TextColumn::make('stock_quantity')->label('In stock'),
            ])
            ->paginated(false);
    }
}
