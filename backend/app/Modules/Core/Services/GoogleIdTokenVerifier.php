<?php

namespace App\Modules\Core\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use JsonException;

class GoogleIdTokenVerifier
{
    /** @return array<string, mixed>|null */
    public function verify(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        try {
            $header = json_decode($this->decode($parts[0]), true, flags: JSON_THROW_ON_ERROR);
            $claims = json_decode($this->decode($parts[1]), true, flags: JSON_THROW_ON_ERROR);
            $signature = $this->decode($parts[2]);
        } catch (JsonException|\InvalidArgumentException $exception) {
            return null;
        }

        if (!is_array($header) || !is_array($claims) || ($header['alg'] ?? null) !== 'RS256' || !isset($header['kid'])) {
            return null;
        }

        $audiences = config('services.google.client_ids', []);
        $audiences = is_array($audiences) ? array_filter($audiences) : [];
        if (!$audiences || !in_array($claims['aud'] ?? null, $audiences, true)) {
            return null;
        }

        $now = time();
        if (!in_array($claims['iss'] ?? null, ['accounts.google.com', 'https://accounts.google.com'], true)
            || (int) ($claims['exp'] ?? 0) <= $now
            || (int) ($claims['iat'] ?? PHP_INT_MAX) > $now + 60
            || empty($claims['sub'])
            || empty($claims['email'])
            || !filter_var($claims['email'], FILTER_VALIDATE_EMAIL)
            || !filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN)) {
            return null;
        }

        $keys = Cache::remember('google.oauth.jwks', now()->addHour(), function () {
            return Http::timeout(8)->get('https://www.googleapis.com/oauth2/v3/certs')->throw()->json('keys', []);
        });
        $jwk = collect($keys)->first(fn ($key) => ($key['kid'] ?? null) === $header['kid'] && ($key['kty'] ?? null) === 'RSA');
        if (!$jwk) {
            Cache::forget('google.oauth.jwks');
            $keys = Cache::remember('google.oauth.jwks', now()->addHour(), function () {
                return Http::timeout(8)->get('https://www.googleapis.com/oauth2/v3/certs')->throw()->json('keys', []);
            });
            $jwk = collect($keys)->first(fn ($key) => ($key['kid'] ?? null) === $header['kid'] && ($key['kty'] ?? null) === 'RSA');
        }
        if (!$jwk || empty($jwk['n']) || empty($jwk['e'])) {
            return null;
        }

        $publicKey = openssl_pkey_get_public($this->jwkToPem($jwk));
        if (!$publicKey) {
            return null;
        }

        $valid = openssl_verify($parts[0].'.'.$parts[1], $signature, $publicKey, OPENSSL_ALGO_SHA256) === 1;
        openssl_free_key($publicKey);

        return $valid ? $claims : null;
    }

    private function jwkToPem(array $jwk): string
    {
        $modulus = $this->decode($jwk['n']);
        $exponent = $this->decode($jwk['e']);
        $integer = fn (string $value): string => $this->der(0x02, (ord($value[0]) > 0x7f ? "\0" : '').$value);
        $rsaKey = $this->der(0x30, $integer($modulus).$integer($exponent));
        $algorithm = hex2bin('300d06092a864886f70d0101010500');
        $subjectPublicKeyInfo = $this->der(0x30, $algorithm.$this->der(0x03, "\0".$rsaKey));

        return "-----BEGIN PUBLIC KEY-----\n".chunk_split(base64_encode($subjectPublicKeyInfo), 64, "\n")."-----END PUBLIC KEY-----\n";
    }

    private function der(int $tag, string $value): string
    {
        $length = strlen($value);
        if ($length < 128) {
            $encodedLength = chr($length);
        } else {
            $bytes = ltrim(pack('N', $length), "\0");
            $encodedLength = chr(0x80 | strlen($bytes)).$bytes;
        }

        return chr($tag).$encodedLength.$value;
    }

    private function decode(string $value): string
    {
        $base64 = strtr($value, '-_', '+/');
        $base64 .= str_repeat('=', (4 - strlen($base64) % 4) % 4);
        $decoded = base64_decode($base64, true);
        if ($decoded === false) {
            throw new \InvalidArgumentException('Invalid base64url value.');
        }

        return $decoded;
    }
}
