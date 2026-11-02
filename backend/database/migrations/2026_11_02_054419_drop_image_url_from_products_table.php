<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('products', 'image_url')) {
            $products = DB::table('products')->get();
            foreach ($products as $product) {
                $images = $product->images ? json_decode($product->images, true) : [];
                if ((empty($images) || ! is_array($images)) && ! empty($product->image_url)) {
                    DB::table('products')
                        ->where('id', $product->id)
                        ->update(['images' => json_encode([$product->image_url])]);
                }
            }

            Schema::table('products', function (Blueprint $table) {
                $table->dropColumn('image_url');
            });
        }
    }

    public function down(): void
    {
        if (! Schema::hasColumn('products', 'image_url')) {
            Schema::table('products', function (Blueprint $table) {
                $table->string('image_url')->nullable()->after('images');
            });
        }
    }
};
