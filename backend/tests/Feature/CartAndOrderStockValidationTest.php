<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CartAndOrderStockValidationTest extends TestCase
{
    use RefreshDatabase;

    private function makeProduct(int $stock, string $name = 'Organic Bananas'): Product
    {
        $category = Category::create(['name' => 'Fruits']);

        return Product::create([
            'category_id' => $category->id,
            'name' => $name,
            'description' => 'Fresh fruit',
            'image_url' => 'https://example.com/banana.jpg',
            'price' => 4.99,
            'unit' => '1 kg',
            'stock_quantity' => $stock,
        ]);
    }

    public function test_cannot_add_out_of_stock_product_to_cart(): void
    {
        $user = User::factory()->create();
        $product = $this->makeProduct(0, 'Red Apples');
        Sanctum::actingAs($user);

        $this->postJson('/api/cart', [
            'product_id' => $product->id,
            'quantity' => 1,
        ])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Red Apples is out of stock');
    }

    public function test_cannot_exceed_available_stock_when_adding_or_updating_cart(): void
    {
        $user = User::factory()->create();
        $product = $this->makeProduct(3, 'Fresh Milk');
        Sanctum::actingAs($user);

        $this->postJson('/api/cart', [
            'product_id' => $product->id,
            'quantity' => 2,
        ])->assertCreated();

        $this->postJson('/api/cart', [
            'product_id' => $product->id,
            'quantity' => 2,
        ])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only 3 left in stock for Fresh Milk');

        $this->putJson("/api/cart/{$product->id}", [
            'quantity' => 5,
        ])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only 3 left in stock for Fresh Milk');
    }

    public function test_order_checkout_validates_live_stock_and_rolls_back_atomically(): void
    {
        $user = User::factory()->create();
        $first = $this->makeProduct(5, 'Organic Bananas');
        $second = $this->makeProduct(2, 'Broccoli');
        Sanctum::actingAs($user);

        $this->postJson('/api/cart', ['product_id' => $first->id, 'quantity' => 2])->assertCreated();
        $this->postJson('/api/cart', ['product_id' => $second->id, 'quantity' => 2])->assertCreated();

        // Stock drops to 0 before checkout
        $second->update(['stock_quantity' => 0]);

        $this->postJson('/api/orders', ['address' => 'Phnom Penh'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Broccoli is out of stock');

        // First product stock must remain untouched (transaction rolled back)
        $this->assertSame(5, $first->fresh()->stock_quantity);
    }
}

