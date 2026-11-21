<?php

namespace Tests\Feature;

use App\Mail\AuthOtpMail;
use App\Models\User;
use App\Modules\Core\Services\GoogleIdTokenVerifier;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;
use Symfony\Component\Mailer\Exception\TransportException;
use Tests\TestCase;

class AuthLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_email_otp_delivers_the_code_and_issues_a_token_once(): void
    {
        config(['mail.default' => 'array']);
        $user = User::factory()->create(['is_active' => true, 'email_verified_at' => null]);
        $this->postJson('/api/v1/auth/email/otp/request', ['email' => $user->email])->assertOk();

        $mail = Mail::getSymfonyTransport()->messages()->sole()->getOriginalMessage();
        $this->assertSame($user->email, $mail->getTo()[0]->getAddress());
        $this->assertStringContainsString('Logo Meowtopia', $mail->getHtmlBody());
        $this->assertSame(1, preg_match('/\b([0-9]{6})\b/', $mail->getTextBody(), $matches));
        $body = ['email' => $user->email, 'otp' => $matches[1]];
        $this->postJson('/api/v1/auth/email/otp/login', array_replace($body, ['otp' => '000000']))->assertUnprocessable();
        $login = $this->postJson('/api/v1/auth/email/otp/login', $body)
            ->assertOk()->assertJsonPath('data.user.email_verified', true);
        $this->postJson('/api/v1/auth/email/otp/login', $body)->assertUnprocessable();

        $token = $login->json('data.token');
        $this->assertTrue(Str::isUlid(Str::before($token, '|')));
        $this->withToken($token)->getJson('/api/v1/me')
            ->assertOk()->assertJsonPath('data.id', $user->id);
    }

    public function test_failed_registration_email_does_not_leave_a_duplicate_account(): void
    {
        Role::findOrCreate('user', 'web');
        Mail::shouldReceive('to->send')->once()->withArgs(fn ($message) => $message instanceof AuthOtpMail)
            ->andThrow(new TransportException('Simulated delivery outage'));

        $email = 'new-user@example.com';
        $this->postJson('/api/v1/auth/register', [
            'name' => 'New User',
            'email' => $email,
            'password' => 'example-password',
        ])->assertServiceUnavailable();
        $this->assertDatabaseMissing('users', ['email' => $email]);
        $this->assertDatabaseCount('email_otps', 0);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_google_login_creates_a_verified_account_and_issues_a_valid_token(): void
    {
        Role::findOrCreate('user', 'web');
        $this->mock(GoogleIdTokenVerifier::class, function ($verifier) {
            $verifier->shouldReceive('verify')->once()->with('rejected')->andReturn(null);
            $verifier->shouldReceive('verify')->once()->with('accepted')->andReturn([
                'sub' => 'test-google-subject', 'email' => 'test-meowtopia@gmail.com', 'name' => 'Google User',
            ]);
        });

        $this->postJson('/api/v1/auth/google', ['id_token' => 'rejected'])->assertUnauthorized();
        $login = $this->postJson('/api/v1/auth/google', ['id_token' => 'accepted'])
            ->assertOk()->assertJsonPath('data.user.email_verified', true);
        $this->assertDatabaseHas('users', ['google_sub' => 'test-google-subject']);
        $this->withToken($login->json('data.token'))->getJson('/api/v1/me')
            ->assertOk()->assertJsonPath('data.email', 'test-meowtopia@gmail.com');
    }
}
