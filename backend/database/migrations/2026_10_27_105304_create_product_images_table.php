<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_images', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->string('image_path');
            $table->unsignedInteger('sort_order')->default(0);
            $table->boolean('is_primary')->default(false);
            $table->timestamps();
        });

        // Backfill existing products into product_images
        $products = DB::table('products')->get();
        foreach ($products as $product) {
            $images = $product->images ? json_decode($product->images, true) : [];
            if (! is_array($images) || empty($images)) {
                $images = $product->image_url ? [$product->image_url] : [];
            }

            foreach (array_values($images) as $index => $path) {
                DB::table('product_images')->insert([
                    'product_id' => $product->id,
                    'image_path' => $path,
                    'sort_order' => $index,
                    'is_primary' => $index === 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('product_images');
    }
};
