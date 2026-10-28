<?php

namespace App\Filament\Resources\Categories\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class CategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                FileUpload::make('icon_asset')
                    ->label('Category icon (PNG / SVG)')
                    ->acceptedFileTypes(['image/png', 'image/svg+xml'])
                    ->maxSize(2048)
                    ->disk('public')
                    ->directory('categories')
                    ->visibility('public')
                    ->helperText('Upload a PNG or SVG icon (max 2 MB).'),
            ]);
    }
}
