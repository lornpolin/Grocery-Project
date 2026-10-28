<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthTokenExpirationTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_issues_token_expiring_in_30_days(): void
    {
        $user = User::factory()->create([
            'email' => 'user@example.com',
            'password' => 'password123',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'user@example.com',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['token', 'expiresAt', 'user' => ['id', 'name', 'email']]);

        $accessToken = PersonalAccessToken::findToken($response->json('token'));
        $this->assertNotNull($accessToken);
        $this->assertNotNull($accessToken->expires_at);
        $this->assertEqualsWithDelta(now()->addDays(30)->timestamp, $accessToken->expires_at->timestamp, 5);
    }

    public function test_expired_token_is_rejected_and_can_be_reset_via_refresh(): void
    {
        $user = User::factory()->create();
        $expiredToken = $user->createToken('mobile', ['*'], now()->subMinute())->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$expiredToken)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();

        $refreshResponse = $this->withHeader('Authorization', 'Bearer '.$expiredToken)
            ->postJson('/api/auth/refresh');

        $refreshResponse->assertOk()
            ->assertJsonStructure(['token', 'expiresAt', 'user']);

        $newToken = $refreshResponse->json('token');
        $this->assertNotSame($expiredToken, $newToken);
        $this->assertNull(PersonalAccessToken::findToken($expiredToken));

        $this->withHeader('Authorization', 'Bearer '.$newToken)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('id', (string) $user->id);
    }
}

