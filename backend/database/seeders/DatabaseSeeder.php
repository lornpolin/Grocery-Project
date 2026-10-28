<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => 'password',
        ]);

        $cats = collect([
            ['Fresh Fruits', 'assets/icons/fruits.png'],
            ['Vegetables', 'assets/icons/vegetables.png'],
            ['Dairy & Eggs', 'assets/icons/dairy.png'],
            ['Meat', 'assets/icons/meat.png'],
            ['Bakery', 'assets/icons/bakery.png'],
        ])->map(fn ($c) => Category::create(['name' => $c[0], 'icon_asset' => $c[1]]));

        $products = [
            [0, 'Organic Bananas', 'Fresh organic bananas directly from the farm.', 'photo-1603833665858-e61d17a86224', 4.99, null, '1 kg', 100],
            [0, 'Red Apples', 'Sweet and crunchy red apples.', 'photo-1560806887-1e4cd0b6faa6', 3.50, 4.00, '1 kg', 50],
            [1, 'Broccoli', 'Fresh green broccoli heads.', 'photo-1459411621453-7b03977f4bfc', 2.99, null, '500 g', 40],
            [2, 'Fresh Milk', 'Whole cow milk, rich in calcium.', 'photo-1550583724-b2692b85b150', 1.99, null, '1 L', 200],
            [3, 'Chicken Breast', 'Boneless, skinless chicken breast.', 'photo-1604503468506-a8da13d82791', 8.99, null, '1 kg', 30],
        ];

        foreach ($products as [$cat, $name, $desc, $photo, $price, $orig, $unit, $stock]) {
            Product::create([
                'category_id' => $cats[$cat]->id,
                'name' => $name,
                'description' => $desc,
                'image_url' => "https://images.unsplash.com/{$photo}?w=500&q=80",
                'price' => $price,
                'original_price' => $orig,
                'unit' => $unit,
                'stock_quantity' => $stock,
            ]);
        }
    }
}
