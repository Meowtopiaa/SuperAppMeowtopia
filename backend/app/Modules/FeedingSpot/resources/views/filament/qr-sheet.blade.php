<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lembar QR Spot — {{ $spot->code }} — {{ $spot->name }}</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 18mm;
        }
        * {
            box-sizing: border-box;
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            color: #131B2E;
            margin: 0;
            padding: 24px;
            background: #FAF8FF;
            text-align: center;
        }
        .toolbar {
            max-width: 640px;
            margin: 0 auto 16px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            height: 36px;
            padding: 0 16px;
            border-radius: 7px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            border: 1px solid transparent;
        }
        .btn-primary {
            background: #F97316;
            color: #FFFFFF;
        }
        .btn-neutral {
            background: #FFFFFF;
            color: #475569;
            border-color: #CBD2E6;
        }
        .sheet-container {
            max-width: 640px;
            margin: 0 auto;
            background: #FFFFFF;
            border: 2px solid #E2E6F3;
            border-radius: 14px;
            padding: 36px 32px;
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            border-bottom: 1px solid #E2E6F3;
            padding-bottom: 20px;
            margin-bottom: 24px;
        }
        .brand-logo {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            object-fit: cover;
        }
        .logo-title {
            font-size: 20px;
            font-weight: 800;
            color: #131B2E;
            text-align: left;
        }
        .sub-header {
            font-size: 12.5px;
            color: #64748B;
            text-align: left;
        }
        .spot-badge {
            display: inline-block;
            background: #FFF7ED;
            border: 1px solid #FED7AA;
            padding: 5px 14px;
            border-radius: 6px;
            font-size: 12px;
            font-weight: 700;
            color: #9A3412;
            margin-bottom: 10px;
        }
        .spot-name {
            font-size: 24px;
            font-weight: 800;
            color: #131B2E;
            margin: 4px 0 8px 0;
        }
        .spot-desc {
            font-size: 13.5px;
            color: #475569;
            max-width: 480px;
            margin: 0 auto 24px auto;
        }
        .qr-wrapper {
            background: #FFFFFF;
            border: 2px solid #E2E6F3;
            border-radius: 12px;
            padding: 24px;
            display: inline-block;
            margin-bottom: 24px;
        }
        .qr-placeholder {
            width: 240px;
            height: 240px;
            background: #FAF8FF;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            border: 1px solid #CBD2E6;
            border-radius: 10px;
            margin: 0 auto;
        }
        .qr-payload {
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 13px;
            font-weight: 700;
            color: #131B2E;
            background: #F4F5FB;
            padding: 8px 14px;
            border-radius: 6px;
            display: inline-block;
            margin-top: 12px;
            word-break: break-all;
        }
        .instructions {
            background: #F4F5FB;
            border: 1px solid #E2E6F3;
            border-radius: 10px;
            padding: 16px 20px;
            text-align: left;
            margin-top: 16px;
        }
        .instructions h4 {
            margin: 0 0 8px 0;
            color: #131B2E;
            font-size: 13.5px;
        }
        .instructions ol {
            margin: 0;
            padding-left: 18px;
            color: #475569;
            font-size: 13px;
            line-height: 1.6;
        }
        .footer {
            margin-top: 24px;
            font-size: 11.5px;
            color: #64748B;
            border-top: 1px solid #E2E6F3;
            padding-top: 14px;
        }
        @media print {
            body {
                background: none;
                padding: 0;
            }
            .sheet-container {
                border: 1px solid #000;
            }
            .no-print {
                display: none !important;
            }
        }
    </style>
</head>
<body>
    <div class="toolbar no-print">
        <a href="/api/v1/feeding/admin-preview?tab=spots" class="btn btn-neutral">Kembali ke Dashboard</a>
        <button type="button" onclick="window.print()" class="btn btn-primary">Cetak Lembar QR</button>
    </div>

    <div class="sheet-container">
        <div class="header">
            <img src="/api/v1/feeding/assets/logo.jpg" alt="Logo Meowtopia" class="brand-logo">
            <div>
                <div class="logo-title">MEOWTOPIA SUPER APP</div>
                <div class="sub-header">Telkom University Campus Cat Welfare Ecosystem</div>
            </div>
        </div>

        <div class="spot-badge">TITIK PAKAN RESMI KAMPUS</div>
        <div class="spot-name">{{ $spot->name }}</div>
        <div class="spot-desc">{{ $spot->description ?? 'Titik pakan resmi yang terpantau dan dikelola secara berkala di lingkungan Kampus Telkom University.' }}</div>

        <div class="qr-wrapper">
            <div class="qr-placeholder">
                <svg width="190" height="190" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect width="200" height="200" fill="#FFFFFF"/>
                    <rect x="20" y="20" width="40" height="40" fill="#131B2E"/>
                    <rect x="28" y="28" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="34" y="34" width="12" height="12" fill="#131B2E"/>
                    <rect x="140" y="20" width="40" height="40" fill="#131B2E"/>
                    <rect x="148" y="28" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="154" y="34" width="12" height="12" fill="#131B2E"/>
                    <rect x="20" y="140" width="40" height="40" fill="#131B2E"/>
                    <rect x="28" y="148" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="34" y="154" width="12" height="12" fill="#131B2E"/>
                    <rect x="85" y="85" width="30" height="30" fill="#F97316" rx="6"/>
                    <circle cx="100" cy="100" r="8" fill="#FFFFFF"/>
                </svg>
                <div style="font-size: 11px; color: #64748B; margin-top: 6px;">Pindai melalui aplikasi Meowtopia</div>
            </div>
            <div class="qr-payload">MTP1.S.{{ $spot->qr_token }}</div>
        </div>

        <div class="instructions">
            <h4>Panduan Pemberian Pakan:</h4>
            <ol>
                <li>Buka aplikasi <strong>Meowtopia</strong> dan pilih menu <strong>Pindai QR</strong>.</li>
                <li>Arahkan kamera ke kode QR di atas untuk memulai sesi pemberian makan.</li>
                <li>Isi wadah pakan dan unggah 1–3 foto bukti pemberian pakan.</li>
            </ol>
        </div>

        <div class="footer">
            Kode Spot: {{ $spot->code }} &bull; Telkom University Bandung
        </div>
    </div>
</body>
</html>
