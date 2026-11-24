<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic feature test example.
     */
    public function test_api_status(): void
    {
        $response = $this->getJson('/api/v1/me');
        // Unauthenticated access should return 401
        $response->assertStatus(401);
    }
}

