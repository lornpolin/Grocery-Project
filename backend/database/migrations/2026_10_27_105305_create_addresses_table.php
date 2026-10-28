<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label')->default('Home');
            $table->string('recipient_name')->nullable();
            $table->string('phone')->nullable();
            $table->string('address');
            $table->string('city')->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('address_id')->nullable()->after('status')->constrained('addresses')->nullOnDelete();
        });

        // Backfill existing orders that have an address string
        $orders = DB::table('orders')->whereNotNull('address')->where('address', '!=', '')->get();
        foreach ($orders as $order) {
            $existing = DB::table('addresses')
                ->where('user_id', $order->user_id)
                ->where('address', $order->address)
                ->first();

            if ($existing) {
                $addressId = $existing->id;
            } else {
                $hasAny = DB::table('addresses')->where('user_id', $order->user_id)->exists();
                $addressId = DB::table('addresses')->insertGetId([
                    'user_id' => $order->user_id,
                    'label' => 'Home',
                    'address' => $order->address,
                    'is_default' => ! $hasAny,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            DB::table('orders')->where('id', $order->id)->update(['address_id' => $addressId]);
        }
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('address_id');
        });

        Schema::dropIfExists('addresses');
    }
};
