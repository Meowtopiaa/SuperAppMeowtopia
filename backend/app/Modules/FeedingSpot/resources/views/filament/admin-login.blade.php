<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login Admin - Meowtopia</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; min-height: 100vh; display: grid; place-items: center; padding: 24px; background: #f3f6fa; color: #17243b; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
        .login-card { width: min(100%, 420px); padding: 36px; border: 1px solid #e0e6ef; border-radius: 18px; background: #fff; box-shadow: 0 18px 48px #17243b14; }
        .brand { display: flex; align-items: center; gap: 12px; margin-bottom: 28px; }
        .brand img { width: 48px; height: 48px; object-fit: contain; border-radius: 12px; }
        .brand strong { display: block; font-size: 17px; letter-spacing: .04em; }
        .brand span { color: #6b7890; font-size: 13px; }
        h1 { margin: 0 0 8px; font-size: 24px; }
        .intro { margin: 0 0 24px; color: #68758a; font-size: 14px; line-height: 1.5; }
        label { display: block; margin: 16px 0 7px; font-size: 13px; font-weight: 600; }
        input { width: 100%; padding: 12px 13px; border: 1px solid #cfd7e3; border-radius: 9px; font: inherit; outline: none; }
        input:focus { border-color: #3157a4; box-shadow: 0 0 0 3px #3157a41c; }
        .error { margin-top: 6px; color: #b42318; font-size: 12px; }
        button { width: 100%; margin-top: 24px; padding: 13px; border: 0; border-radius: 9px; background: #263f79; color: #fff; font: inherit; font-weight: 650; cursor: pointer; }
        button:hover { background: #1d3264; }
    </style>
</head>
<body>
    <main class="login-card">
        <div class="brand">
            <img src="/api/v1/feeding/assets/logo.jpg" alt="">
            <div><strong>MEOWTOPIA</strong><span>Panel Admin Feeding Spot</span></div>
        </div>
        <h1>Masuk sebagai admin</h1>
        <p class="intro">Gunakan akun aktif yang memiliki izin mengelola spot atau meninjau pengajuan pakan.</p>

        <form method="POST" action="{{ route('admin.login.submit') }}">
            @csrf
            <label for="email">Email</label>
            <input id="email" name="email" type="email" value="{{ old('email') }}" autocomplete="username" required autofocus>
            @error('email')<div class="error">{{ $message }}</div>@enderror

            <label for="password">Kata sandi</label>
            <input id="password" name="password" type="password" autocomplete="current-password" required>
            @error('password')<div class="error">{{ $message }}</div>@enderror

            <button type="submit">Masuk ke Panel Admin</button>
        </form>
    </main>
</body>
</html>
