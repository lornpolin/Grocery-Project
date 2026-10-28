<?php

namespace App\Filament\Resources\Products\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class ProductForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(2)
            ->components([
                Select::make('category_id')
                    ->relationship('category', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Textarea::make('description')
                    ->required()
                    ->rows(3)
                    ->columnSpanFull(),
                FileUpload::make('images')
                    ->label('Product images')
                    ->image()
                    ->multiple()
                    ->required()
                    ->reorderable()
                    ->appendFiles()
                    ->maxFiles(8)
                    ->maxSize(5120)
                    ->imageEditor()
                    ->disk('public')
                    ->directory('products')
                    ->visibility('public')
                    ->panelLayout('grid')
                    ->helperText('Up to 8 images (max 5 MB each). The first image is the main one; drag to reorder.')
                    ->columnSpanFull(),
                TextInput::make('price')
                    ->required()
                    ->numeric()
                    ->minValue(0)
                    ->prefix('$'),
                TextInput::make('original_price')
                    ->label('Original price (before discount)')
                    ->numeric()
                    ->minValue(0)
                    ->prefix('$'),
                TextInput::make('unit')
                    ->required()
                    ->placeholder('1 kg'),
                TextInput::make('stock_quantity')
                    ->label('Stock')
                    ->required()
                    ->integer()
                    ->minValue(0)
                    ->default(0),
            ]);
    }
}
