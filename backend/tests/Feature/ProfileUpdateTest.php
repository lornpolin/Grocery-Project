<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProfileUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_update_profile_upload_and_remove_avatar(): void
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'name' => 'Old Name',
            'email' => 'old@example.com',
        ]);
        Sanctum::actingAs($user);

        // 1px PNG bytes (no GD dependency required)
        $pngBytes = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
        );
        $avatar = UploadedFile::fake()->createWithContent('avatar.png', $pngBytes);

        $response = $this->postJson('/api/auth/profile', [
            'name' => 'Sok Dara',
            'email' => 'dara@example.com',
            'phone' => '012345678',
            'avatar' => $avatar,
        ]);

        $response->assertOk()
            ->assertJsonPath('name', 'Sok Dara')
            ->assertJsonPath('email', 'dara@example.com')
            ->assertJsonPath('phone', '012345678');

        $this->assertNotNull($response->json('avatarUrl'));
        $this->assertStringContainsString('/api/media/avatars/', $response->json('avatarUrl'));

        $storedAvatar = $user->fresh()->avatar;
        $this->assertNotNull($storedAvatar);
        Storage::disk('public')->assertExists($storedAvatar);

        // Remove avatar -> reverts to null (default silhouette in Flutter)
        $removeResponse = $this->putJson('/api/auth/profile', [
            'name' => 'Sok Dara',
            'email' => 'dara@example.com',
            'remove_avatar' => true,
        ]);

        $removeResponse->assertOk()
            ->assertJsonPath('avatarUrl', null);

        $this->assertNull($user->fresh()->avatar);
        Storage::disk('public')->assertMissing($storedAvatar);
    }

    public function test_user_can_change_password_with_valid_current_password(): void
    {
        $user = User::factory()->create([
            'password' => 'oldsecret',
        ]);
        Sanctum::actingAs($user);

        $this->putJson('/api/auth/profile', [
            'name' => $user->name,
            'email' => $user->email,
            'current_password' => 'wrongpassword',
            'new_password' => 'newsecret123',
        ])->assertStatus(422);

        $this->putJson('/api/auth/profile', [
            'name' => $user->name,
            'email' => $user->email,
            'current_password' => 'oldsecret',
            'new_password' => 'newsecret123',
        ])->assertOk();

        $this->assertTrue(Hash::check('newsecret123', $user->fresh()->password));
    }
}

