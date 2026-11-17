<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lembar QR Spot — {{ isset($spot) && $spot ? ($spot->code . ' — ' . $spot->name) : 'Daftar Feeding Spot' }}</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 15mm;
        }
        * {
            box-sizing: border-box;
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            color: #0F172A;
            margin: 0;
            padding: 24px;
            background: #F4F6F9;
            text-align: center;
        }
        .toolbar {
            max-width: 680px;
            margin: 0 auto 18px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }
        .toolbar-actions {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            height: 36px;
            padding: 0 14px;
            border-radius: 7px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            cursor: pointer;
            border: 1px solid transparent;
        }
        .btn-primary {
            background: #EA580C;
            color: #FFFFFF;
        }
        .btn-secondary {
            background: #1B365D;
            color: #FFFFFF;
        }
        .btn-neutral {
            background: #FFFFFF;
            color: #334155;
            border-color: #CBD5E1;
        }
        .sheet-list {
            display: flex;
            flex-direction: column;
            gap: 28px;
            align-items: center;
        }
        .sheet-container {
            width: 100%;
            max-width: 680px;
            margin: 0 auto;
            background: #FFFFFF;
            border: 2px solid #CBD5E1;
            border-radius: 14px;
            padding: 34px 32px;
            page-break-inside: avoid;
        }
        .sheet-container + .sheet-container {
            page-break-before: always;
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            border-bottom: 1px solid #E2E8F0;
            padding-bottom: 18px;
            margin-bottom: 22px;
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
            color: #0F172A;
            text-align: left;
        }
        .sub-header {
            font-size: 12.5px;
            color: #475569;
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
            margin-bottom: 8px;
        }
        .spot-name {
            font-size: 24px;
            font-weight: 800;
            color: #0F172A;
            margin: 4px 0 6px 0;
        }
        .spot-location {
            font-size: 13.5px;
            font-weight: 600;
            color: #1B365D;
            margin-bottom: 6px;
        }
        .spot-desc {
            font-size: 13px;
            color: #475569;
            max-width: 500px;
            margin: 0 auto 20px auto;
        }
        .qr-wrapper {
            background: #FFFFFF;
            border: 2px solid #0F172A;
            border-radius: 14px;
            padding: 20px 24px;
            display: inline-block;
            margin-bottom: 18px;
        }
        .qr-code-box {
            width: 248px;
            height: 248px;
            background: #FFFFFF;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto;
        }
        .qr-code-box svg {
            width: 240px;
            height: 240px;
            display: block;
        }
        .manual-code-box {
            margin: 12px auto 4px auto;
            padding: 8px 16px;
            background: #F8FAFC;
            border: 1.5px dashed #334155;
            border-radius: 8px;
            display: inline-block;
        }
        .manual-code-label {
            font-size: 11px;
            font-weight: 600;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.6px;
        }
        .manual-code-value {
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 20px;
            font-weight: 800;
            color: #0F172A;
            letter-spacing: 1px;
            margin-top: 2px;
        }
        .qr-payload {
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 12px;
            font-weight: 600;
            color: #334155;
            background: #F1F5F9;
            padding: 6px 12px;
            border-radius: 6px;
            display: inline-block;
            margin-top: 8px;
            word-break: break-all;
        }
        .card-actions {
            margin: 6px 0 16px 0;
            display: flex;
            justify-content: center;
            gap: 8px;
            flex-wrap: wrap;
        }
        .instructions {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 10px;
            padding: 16px 20px;
            text-align: left;
            margin-top: 12px;
        }
        .instructions h4 {
            margin: 0 0 8px 0;
            color: #0F172A;
            font-size: 13.5px;
        }
        .instructions ol {
            margin: 0;
            padding-left: 18px;
            color: #334155;
            font-size: 13px;
            line-height: 1.6;
        }
        .footer {
            margin-top: 20px;
            font-size: 11.5px;
            color: #475569;
            border-top: 1px solid #E2E8F0;
            padding-top: 12px;
        }
        @media print {
            body {
                background: #FFFFFF;
                padding: 0;
            }
            .sheet-container {
                border: 2px solid #000000;
                box-shadow: none;
            }
            .no-print {
                display: none !important;
            }
        }
    </style>
</head>
<body>
@php
    $qrServiceInstance = app(\App\Modules\FeedingSpot\Services\FeedingSpotQrCodeService::class);
    $items = $spotItems ?? [];
    if (empty($items) && isset($spot) && $spot) {
        $fallbackPayload = $qrServiceInstance->formatSpotPayload($spot->qr_token);
        $locInfo = \App\Modules\FeedingSpot\Services\FeedingSpotManagementService::resolveCampusLocation(
            (float) $spot->latitude,
            (float) $spot->longitude,
            $spot->code,
            $spot->name
        );
        $items = [[
            'spot' => $spot,
            'payload' => $fallbackPayload,
            'qr_svg' => $qrServiceInstance->renderSvg($fallbackPayload, 240, 4),
            'location_name' => $locInfo['name'],
            'location_number' => $locInfo['number'],
        ]];
    }
@endphp

    <div class="toolbar no-print">
        <a href="/api/v1/feeding/admin-preview?tab=spots" class="btn btn-neutral">Kembali ke Dashboard</a>
        <div class="toolbar-actions">
            @if(count($items) === 1 && !empty($items[0]['spot']))
                <a href="/api/v1/feeding/admin-preview/spots/{{ $items[0]['spot']->id }}/qr-download?format=png" class="btn btn-secondary">
                    Unduh QR (PNG)
                </a>
                <a href="/api/v1/feeding/admin-preview/spots/{{ $items[0]['spot']->id }}/qr-download?format=svg" class="btn btn-neutral">
                    Unduh QR (SVG)
                </a>
            @endif
            <button type="button" onclick="window.print()" class="btn btn-primary">Cetak Lembar QR</button>
        </div>
    </div>

    <div class="sheet-list">
        @foreach($items as $item)
            @php
                $s = $item['spot'];
                $payload = $item['payload'];
                $svg = $item['qr_svg'];
                $locName = $item['location_name'] ?? 'Area Kampus Telkom University';
            @endphp
            <div class="sheet-container">
                <div class="header">
                    <img src="/api/v1/feeding/assets/logo.jpg" alt="Logo Meowtopia" class="brand-logo">
                    <div>
                        <div class="logo-title">MEOWTOPIA SUPER APP</div>
                        <div class="sub-header">Telkom University Campus Cat Welfare Ecosystem</div>
                    </div>
                </div>

                <div class="spot-badge">TITIK PAKAN RESMI KAMPUS</div>
                <div class="spot-name">{{ $s->name }}</div>
                <div class="spot-location">{{ $locName }}</div>
                <div class="spot-desc">{{ $s->description ?? 'Titik pakan resmi yang terpantau dan dikelola secara berkala di lingkungan Kampus Telkom University.' }}</div>

                <div class="qr-wrapper">
                    <div class="qr-code-box">
                        {!! $svg !!}
                    </div>
                    <div class="manual-code-box">
                        <div class="manual-code-label">Kode Manual Spot</div>
                        <div class="manual-code-value">{{ $s->code }}</div>
                    </div>
                    <div>
                        <div class="qr-payload">{{ $payload }}</div>
                    </div>
                </div>

                @if(count($items) > 1)
                    <div class="card-actions no-print">
                        <a href="/api/v1/feeding/admin-preview/spots/{{ $s->id }}/qr-download?format=png" class="btn btn-secondary">
                            Unduh PNG ({{ $s->code }})
                        </a>
                        <a href="/api/v1/feeding/admin-preview/spots/{{ $s->id }}/qr-download?format=svg" class="btn btn-neutral">
                            Unduh SVG ({{ $s->code }})
                        </a>
                    </div>
                @endif

                <div class="instructions">
                    <h4>Panduan Pemberian Pakan:</h4>
                    <ol>
                        <li>Buka aplikasi <strong>Meowtopia</strong> dan pilih menu <strong>Pindai QR Spot</strong>.</li>
                        <li>Arahkan kamera ke kode QR di atas (atau masukkan kode manual <strong>{{ $s->code }}</strong> bila stiker rusak) untuk memulai sesi pemberian makan.</li>
                        <li>Isi wadah pakan dan unggah 1–3 foto bukti pemberian pakan dari kamera aplikasi.</li>
                    </ol>
                </div>

                <div class="footer">
                    Kode Spot: <strong>{{ $s->code }}</strong> &bull; Lokasi: {{ $locName }} &bull; Telkom University Bandung
                </div>
            </div>
        @endforeach
    </div>
</body>
</html>
