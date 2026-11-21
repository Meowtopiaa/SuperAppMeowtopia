<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Kode keamanan Meowtopia</title>
</head>
<body style="margin:0;background:#10131b;color:#f7f4f1;font-family:Arial,Helvetica,sans-serif;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#10131b;padding:36px 16px;">
        <tr><td align="center">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#1c202a;border:1px solid #343844;border-radius:24px;overflow:hidden;">
                <tr><td align="center" style="padding:34px 28px 20px;">
                    <img src="{{ $message->embed(public_path('assets/meowtopia-logo.png')) }}" alt="Logo Meowtopia" width="72" height="72" style="display:block;border:0;border-radius:18px;">
                    <p style="margin:14px 0 0;color:#fff;font-size:22px;font-weight:700;letter-spacing:1px;">MEOWTOPIA</p>
                    <p style="margin:6px 0 0;color:#c5c8d0;font-size:13px;">Campus Cat Welfare Ecosystem</p>
                </td></tr>
                <tr><td style="padding:8px 32px 34px;">
                    <h1 style="margin:0 0 12px;color:#fff;font-size:22px;line-height:1.35;">Kode verifikasi kamu</h1>
                    <p style="margin:0;color:#d4d6dc;font-size:15px;line-height:1.65;">Halo {{ $recipientName }}, gunakan kode ini untuk masuk ke akun Meowtopia:</p>
                    <div style="margin:24px 0;padding:18px 12px;border:1px solid #4a3c34;border-radius:16px;background:#171a22;text-align:center;">
                        <span style="color:#ff9b54;font-size:38px;font-weight:800;letter-spacing:12px;font-family:Arial,Helvetica,sans-serif;">{{ $otp }}</span>
                    </div>
                    <p style="margin:0;color:#c5c8d0;font-size:14px;line-height:1.65;">Tekan dan tahan kode untuk menyalin. Kode berlaku selama <strong style="color:#fff;">15 menit</strong> dan hanya dapat digunakan sekali.</p>
                    <p style="margin:18px 0 0;color:#aeb2bc;font-size:13px;line-height:1.6;">Jangan bagikan kode ini kepada siapa pun. Jika kamu tidak meminta kode, abaikan email ini.</p>
                </td></tr>
                <tr><td style="padding:18px 28px;border-top:1px solid #343844;color:#8e929d;font-size:12px;text-align:center;">Meowtopia · Telkom University Campus Cat Welfare Ecosystem</td></tr>
            </table>
        </td></tr>
    </table>
</body>
</html>
