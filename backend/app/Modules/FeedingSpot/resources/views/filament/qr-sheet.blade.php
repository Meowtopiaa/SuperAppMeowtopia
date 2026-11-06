<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lembar QR Spot - {{ $spot->code }} - {{ $spot->name }}</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 20mm;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: #2D3748;
            margin: 0;
            padding: 20px;
            background: #FAFAFA;
            text-align: center;
        }
        .sheet-container {
            max-width: 650px;
            margin: 0 auto;
            background: #FFFFFF;
            border: 3px solid #E2E8F0;
            border-radius: 16px;
            padding: 36px 28px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.06);
        }
        .header {
            border-bottom: 2px dashed #CBD5E0;
            padding-bottom: 20px;
            margin-bottom: 24px;
        }
        .logo-title {
            font-size: 24px;
            font-weight: 800;
            color: #C53030;
            letter-spacing: 1px;
            text-transform: uppercase;
        }
        .sub-header {
            font-size: 13px;
            color: #718096;
            margin-top: 4px;
        }
        .spot-badge {
            display: inline-block;
            background: #EDF2F7;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: 700;
            color: #4A5568;
            margin-bottom: 12px;
        }
        .spot-name {
            font-size: 26px;
            font-weight: 800;
            color: #1A202C;
            margin: 6px 0;
        }
        .spot-desc {
            font-size: 14px;
            color: #718096;
            max-width: 500px;
            margin: 0 auto 24px auto;
        }
        .qr-wrapper {
            background: #FFFFFF;
            border: 4px solid #FBD38D;
            border-radius: 20px;
            padding: 24px;
            display: inline-block;
            margin-bottom: 24px;
        }
        .qr-placeholder {
            width: 260px;
            height: 260px;
            background: #F7FAFC;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            border: 1px dashed #A0AEC0;
            border-radius: 12px;
            margin: 0 auto;
        }
        .qr-payload {
            font-family: 'Courier New', Courier, monospace;
            font-size: 13px;
            font-weight: 700;
            color: #2B6CB0;
            background: #EBF8FF;
            padding: 8px 14px;
            border-radius: 8px;
            display: inline-block;
            margin-top: 10px;
            word-break: break-all;
        }
        .instructions {
            background: #FFFAF0;
            border: 1px solid #FEEBC8;
            border-radius: 12px;
            padding: 16px 20px;
            text-align: left;
            margin-top: 20px;
        }
        .instructions h4 {
            margin: 0 0 8px 0;
            color: #C05621;
            font-size: 14px;
        }
        .instructions ol {
            margin: 0;
            padding-left: 20px;
            color: #4A5568;
            font-size: 13px;
            line-height: 1.6;
        }
        .footer {
            margin-top: 24px;
            font-size: 11px;
            color: #A0AEC0;
            border-top: 1px solid #E2E8F0;
            padding-top: 16px;
        }
        @media print {
            body {
                background: none;
                padding: 0;
            }
            .sheet-container {
                box-shadow: none;
                border: 2px solid #000;
            }
            .no-print {
                display: none !important;
            }
        }
    </style>
</head>
<body>
    <div class="no-print" style="margin-bottom: 16px;">
        <button onclick="window.print()" style="padding: 10px 20px; font-size: 15px; font-weight: 700; background: #C53030; color: white; border: none; border-radius: 8px; cursor: pointer;">
            🖨️ Cetak Lembar QR Ini (Ctrl + P)
        </button>
    </div>

    <div class="sheet-container">
        <div class="header">
            <div class="logo-title">🐾 MEOWTOPIA SUPER APP</div>
            <div class="sub-header">Telkom University Campus Cat Welfare Ecosystem</div>
        </div>

        <div class="spot-badge">TITIK PAKAN RESMI KAMPUS</div>
        <div class="spot-name">{{ $spot->name }}</div>
        <div class="spot-desc">{{ $spot->description ?? 'Titik pakan resmi yang terpantau dan terkelola secara berkala oleh komunitas kampus.' }}</div>

        <div class="qr-wrapper">
            <!-- QR Container -->
            <div class="qr-placeholder">
                <svg width="200" height="200" viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <rect width="200" height="200" fill="#FFFFFF"/>
                    <!-- QR Corner Top-Left -->
                    <rect x="20" y="20" width="40" height="40" fill="#1A202C"/>
                    <rect x="28" y="28" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="34" y="34" width="12" height="12" fill="#1A202C"/>
                    <!-- QR Corner Top-Right -->
                    <rect x="140" y="20" width="40" height="40" fill="#1A202C"/>
                    <rect x="148" y="28" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="154" y="34" width="12" height="12" fill="#1A202C"/>
                    <!-- QR Corner Bottom-Left -->
                    <rect x="20" y="140" width="40" height="40" fill="#1A202C"/>
                    <rect x="28" y="148" width="24" height="24" fill="#FFFFFF"/>
                    <rect x="34" y="154" width="12" height="12" fill="#1A202C"/>
                    <!-- Center Pattern Decorative -->
                    <rect x="85" y="85" width="30" height="30" fill="#DD6B20" rx="6"/>
                    <circle cx="100" cy="100" r="8" fill="#FFFFFF"/>
                </svg>
                <div style="font-size: 11px; color: #718096; margin-top: 6px;">Pindai via Meowtopia Super App</div>
            </div>
            <div class="qr-payload">MTP1.S.{{ $spot->qr_token }}</div>
        </div>

        <div class="instructions">
            <h4>📋 Panduan Relawan Pakan Kampus:</h4>
            <ol>
                <li>Buka aplikasi <strong>Meowtopia Super App</strong> di smartphone Anda.</li>
                <li>Pilih menu <strong>Pindai QR</strong> di halaman utama atau modul Pakan.</li>
                <li>Arahkan kamera ke kode QR spot di atas untuk memulai sesi pemberian makan (15 menit).</li>
                <li>Bersihkan mangkuk, tuang pakan secukupnya, dan ambil 1-3 foto bukti pemberian pakan.</li>
                <li>Kirim laporan pakan untuk mendapatkan Poin Kebaikan Kampus!</li>
            </ol>
        </div>

        <div class="footer">
            ID Spot: {{ $spot->id }} &bull; Kode: {{ $spot->code }} &bull; Diterbitkan oleh Tim Pengelola Meowtopia Telkom University
        </div>
    </div>
</body>
</html>
