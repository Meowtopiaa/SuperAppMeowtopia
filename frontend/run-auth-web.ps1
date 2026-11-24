param(
    [ValidateRange(1024, 65535)]
    [int]$Port = 5784,
    [switch]$EnableEmailServices
)

$ErrorActionPreference = 'Stop'
$envFile = Join-Path $PSScriptRoot '../backend/.env'
$googleClientId = ''
if ($EnableEmailServices -and (Test-Path -LiteralPath $envFile)) {
    $line = Get-Content -LiteralPath $envFile |
        Where-Object { $_ -match '^\s*GOOGLE_OAUTH_CLIENT_IDS\s*=' } |
        Select-Object -Last 1
    if ($line) {
        $googleClientId = (($line -split '=', 2)[1] -split '#', 2)[0].Trim()
        $googleClientId = ($googleClientId.Trim('"', "'") -split ',', 2)[0].Trim()
    }
}

$flutterArgs = @(
    'run', '-d', 'web-server', '--no-web-resources-cdn',
    '--web-hostname=localhost', "--web-port=$Port",
    '--dart-define=MEOWTOPIA_DEMO=false',
    '--dart-define=MEOWTOPIA_API_URL=http://127.0.0.1:8000/api/v1'
)
if ($EnableEmailServices) {
    $flutterArgs += '--dart-define=MEOWTOPIA_ENABLE_EMAIL_SERVICES=true'
}
if ($googleClientId) {
    if ($googleClientId -notmatch '^[A-Za-z0-9-]+\.apps\.googleusercontent\.com$') {
        throw 'Isi GOOGLE_OAUTH_CLIENT_IDS dengan OAuth Web Client ID sebagai entri pertama.'
    }
    $flutterArgs += "--dart-define=MEOWTOPIA_GOOGLE_CLIENT_ID=$googleClientId"
} elseif ($EnableEmailServices) {
    Write-Warning 'GOOGLE_OAUTH_CLIENT_IDS belum diisi di backend/.env. Google belum aktif.'
}

$flutter = Join-Path $PSScriptRoot '../.tools/flutter/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) {
    $flutter = (Get-Command flutter -CommandType Application).Source
}

Write-Host "Login: http://localhost:$Port/#/login"
Push-Location -LiteralPath $PSScriptRoot
try {
    & $flutter @flutterArgs
} finally {
    Pop-Location
}
exit $LASTEXITCODE
