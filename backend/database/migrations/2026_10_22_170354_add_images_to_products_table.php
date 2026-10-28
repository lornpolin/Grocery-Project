<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            // Uploaded image paths (public disk). image_url stays as a legacy fallback.
            $table->json('images')->nullable()->after('description');
            $table->string('image_url')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('images');
            $table->string('image_url')->nullable(false)->change();
        });
    }
};
