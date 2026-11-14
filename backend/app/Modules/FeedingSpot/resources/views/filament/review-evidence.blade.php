<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Detail Review {{ $activity->feeding_record_ref }} — Meowtopia Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-page: #F4F6F9;
            --surface: #FFFFFF;
            --surface-subtle: #F8FAFC;
            --border: #E2E8F0;
            --border-strong: #CBD5E1;

            --text-primary: #0F172A;
            --text-secondary: #475569;
            --text-muted: #64748B;

            --sidebar-navy: #1B365D;
            --sidebar-navy-hover: #244675;
            --sidebar-navy-border: #2B4F82;
            --sidebar-text: #DCE6F4;
            --sidebar-text-muted: #93B0D6;
            --sidebar-w: 244px;

            --primary: #EA580C;
            --primary-hover: #C2410C;
            --success: #15803D;
            --success-hover: #166534;
            --success-bg: #F0FDF4;
            --success-border: #BBF7D0;
            --warning: #B45309;
            --warning-bg: #FFFBEB;
            --warning-border: #FDE68A;
            --danger: #DC2626;
            --danger-hover: #B91C1C;
            --danger-bg: #FEF2F2;
            --danger-border: #FECACA;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: var(--bg-page);
            color: var(--text-primary);
            font-size: 14px;
            line-height: 1.5;
            min-height: 100vh;
            display: flex;
            -webkit-font-smoothing: antialiased;
        }

        /* ================= NAVY SIDEBAR & EDGE TOGGLE ================= */
        .sidebar {
            width: var(--sidebar-w);
            background: var(--sidebar-navy);
            color: #FFFFFF;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0;
            left: 0;
            bottom: 0;
            z-index: 60;
            border-right: 1px solid var(--sidebar-navy-border);
            transition: transform 0.22s ease;
        }

        body.sidebar-collapsed .sidebar {
            transform: translateX(-100%);
        }

        .sidebar-edge-toggle {
            position: fixed;
            top: 18px;
            left: var(--sidebar-w);
            z-index: 65;
            width: 24px;
            height: 40px;
            background: var(--sidebar-navy);
            color: #FFFFFF;
            border: 1px solid var(--sidebar-navy-border);
            border-left: none;
            border-radius: 0 6px 6px 0;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 13px;
            font-weight: 700;
            line-height: 1;
            transition: left 0.22s ease, background 0.15s ease;
            user-select: none;
        }

        .sidebar-edge-toggle:hover {
            background: var(--sidebar-navy-hover);
        }

        body.sidebar-collapsed .sidebar-edge-toggle {
            left: 0;
        }

        .sidebar-brand {
            padding: 18px 18px;
            border-bottom: 1px solid var(--sidebar-navy-border);
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .sidebar-logo {
            width: 36px;
            height: 36px;
            border-radius: 8px;
            object-fit: cover;
            flex-shrink: 0;
            background: #FFFFFF;
        }

        .sidebar-brand-title {
            font-size: 15px;
            font-weight: 700;
            color: #FFFFFF;
            line-height: 1.2;
        }

        .sidebar-brand-sub {
            font-size: 12px;
            color: var(--sidebar-text-muted);
            margin-top: 1px;
        }

        .sidebar-nav {
            padding: 14px 10px;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 9px 12px;
            border-radius: 6px;
            color: var(--sidebar-text);
            text-decoration: none;
            font-size: 13.5px;
            font-weight: 500;
            transition: background 0.15s ease, color 0.15s ease;
        }

        .nav-item-label {
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }

        .nav-icon {
            width: 16px;
            height: 16px;
            flex-shrink: 0;
            stroke: currentColor;
            opacity: 0.9;
        }

        .nav-item:hover {
            background: var(--sidebar-navy-hover);
            color: #FFFFFF;
        }

        .nav-item.active {
            background: var(--primary);
            color: #FFFFFF;
            font-weight: 600;
        }

        /* ================= MAIN WRAPPER & TOPBAR ================= */
        .main-wrapper {
            flex: 1;
            margin-left: var(--sidebar-w);
            min-width: 0;
            display: flex;
            flex-direction: column;
            transition: margin-left 0.22s ease;
        }

        body.sidebar-collapsed .main-wrapper {
            margin-left: 0;
        }

        .topbar {
            height: 58px;
            background: var(--surface);
            border-bottom: 1px solid var(--border);
            padding: 0 28px 0 36px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            position: sticky;
            top: 0;
            z-index: 40;
        }

        .topbar-left {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .topbar-title {
            font-size: 15.5px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .page-content {
            padding: 24px 28px 48px 36px;
            max-width: 1280px;
            width: 100%;
            margin: 0 auto;
        }

        /* ================= BUTTONS & LABELS ================= */
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 8px 14px;
            font-size: 13px;
            font-weight: 600;
            border-radius: 6px;
            border: 1px solid transparent;
            cursor: pointer;
            text-decoration: none;
            transition: background 0.15s ease;
            font-family: inherit;
        }

        .btn:disabled {
            opacity: 0.55;
            cursor: not-allowed;
        }

        .btn-sm {
            padding: 6px 11px;
            font-size: 12.5px;
        }

        .btn-neutral {
            background: var(--surface);
            color: var(--text-secondary);
            border-color: var(--border-strong);
        }
        .btn-neutral:hover:not(:disabled) {
            background: var(--surface-subtle);
            color: var(--text-primary);
        }

        .btn-success {
            background: var(--success);
            color: #FFFFFF;
            border-color: var(--success);
        }
        .btn-success:hover:not(:disabled) {
            background: var(--success-hover);
        }

        .btn-danger {
            background: var(--danger);
            color: #FFFFFF;
            border-color: var(--danger);
        }
        .btn-danger:hover:not(:disabled) {
            background: var(--danger-hover);
        }

        .status-label {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-temp {
            background: var(--warning-bg);
            color: var(--warning);
        }

        .status-active {
            background: var(--success-bg);
            color: var(--success);
        }

        .status-rejected {
            background: var(--danger-bg);
            color: var(--danger);
        }

        /* ================= CLEAN 2-COLUMN LAYOUT ================= */
        .detail-layout {
            display: grid;
            grid-template-columns: 1.45fr 1fr;
            gap: 20px;
            align-items: start;
        }

        .detail-main {
            display: flex;
            flex-direction: column;
            gap: 18px;
        }

        .detail-side {
            position: sticky;
            top: 78px;
        }

        .section-box {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
        }

        .section-header {
            padding: 14px 20px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .section-title {
            font-size: 14.5px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .section-body {
            padding: 18px 20px;
        }

        /* Clean Definition Grid */
        .info-grid {
            display: grid;
            grid-template-columns: 165px 1fr;
            row-gap: 10px;
            column-gap: 16px;
            font-size: 13.5px;
        }

        .info-grid dt {
            color: var(--text-muted);
        }

        .info-grid dd {
            color: var(--text-primary);
            font-weight: 500;
        }

        .divider {
            height: 1px;
            background: var(--border);
            margin: 16px 0;
        }

        /* Photo Evidence */
        .evidence-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 14px;
        }

        .evidence-card {
            border: 1px solid var(--border);
            border-radius: 6px;
            overflow: hidden;
            background: var(--surface-subtle);
        }

        .evidence-card img {
            width: 100%;
            height: 260px;
            object-fit: cover;
            display: block;
            cursor: pointer;
        }

        .evidence-caption {
            padding: 10px 12px;
            font-size: 12.5px;
            color: var(--text-secondary);
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-top: 1px solid var(--border);
            background: var(--surface);
        }

        /* Inspection Indicators */
        .flag-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 16px;
        }

        .flag-row {
            padding: 10px 12px;
            border-radius: 6px;
            background: var(--surface-subtle);
            border: 1px solid var(--border);
            font-size: 13px;
        }

        .flag-row strong {
            color: var(--text-primary);
            display: block;
            margin-bottom: 2px;
        }

        .flag-row span {
            color: var(--text-secondary);
        }

        table.simple-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        table.simple-table th {
            padding: 9px 12px;
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            background: var(--surface-subtle);
            border-bottom: 1px solid var(--border);
        }

        table.simple-table td {
            padding: 10px 12px;
            border-bottom: 1px solid var(--border);
            font-size: 13px;
        }

        table.simple-table tr:last-child td {
            border-bottom: none;
        }

        /* Decision Form */
        .textarea-control {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--border-strong);
            border-radius: 6px;
            font-family: inherit;
            font-size: 13.5px;
            color: var(--text-primary);
            resize: vertical;
            min-height: 100px;
            outline: none;
        }

        .textarea-control:focus {
            border-color: var(--primary);
        }

        .decision-actions {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 14px;
        }

        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 18px;
            background: var(--danger-bg);
            border: 1px solid var(--danger-border);
            color: var(--danger);
            font-size: 13.5px;
        }

        .lightbox-backdrop {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.8);
            z-index: 120;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .lightbox-backdrop.open {
            display: flex;
        }

        .lightbox-box {
            max-width: 900px;
            width: 100%;
            background: #0F172A;
            border-radius: 8px;
            overflow: hidden;
        }

        .lightbox-box img {
            width: 100%;
            max-height: 80vh;
            object-fit: contain;
            display: block;
        }

        @media (max-width: 1024px) {
            .sidebar {
                transform: translateX(-100%);
            }
            .sidebar.mobile-open {
                transform: translateX(0);
            }
            .sidebar-edge-toggle {
                left: 0;
            }
            .sidebar.mobile-open + .sidebar-edge-toggle {
                left: var(--sidebar-w);
            }
            .main-wrapper {
                margin-left: 0 !important;
            }
            .detail-layout {
                grid-template-columns: 1fr;
            }
            .detail-side {
                position: static;
            }
        }
    </style>
</head>
<body>
@php
    $flagLabels = [
        'FIRST_TWO_SUBMISSIONS' => 'Dua pengajuan pertama dari relawan ini perlu pemeriksaan manual.',
        'NEW_USER_SAMPLE' => 'Sampel evaluasi akun relawan baru.',
        'PHOTO_REUSED' => 'Hash berkas foto terdeteksi sama dengan sesi sebelumnya.',
        'RANDOM_SAMPLE' => 'Terpilih sebagai sampel pemeriksaan berkala.',
        'NIGHT_FEEDING' => 'Sesi pemberian pakan dilakukan pada malam hari.',
        'RAPID_RESUBMISSION' => 'Jeda waktu sangat dekat dengan pengajuan sebelumnya.',
    ];
@endphp

    <!-- NAVY BLUE SIDEBAR -->
    <aside class="sidebar" id="appSidebar">
        <div class="sidebar-brand">
            <img src="/api/v1/feeding/assets/logo.jpg" alt="Meowtopia" class="sidebar-logo">
            <div>
                <div class="sidebar-brand-title">Meowtopia</div>
                <div class="sidebar-brand-sub">Feeding Spot</div>
            </div>
        </div>

        <nav class="sidebar-nav">
            <a href="/api/v1/feeding/admin-preview?tab=spots" class="nav-item">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <span>Lokasi Feeding Spot</span>
                </span>
            </a>
            <a href="/api/v1/feeding/admin-preview?tab=reviews" class="nav-item active">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect width="8" height="4" x="8" y="2" rx="1" ry="1"/>
                        <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>
                        <path d="m9 14 2 2 4-4"/>
                    </svg>
                    <span>Antrean Review</span>
                </span>
            </a>
            <a href="/api/v1/feeding/admin-preview?tab=audit" class="nav-item">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
                        <path d="M3 3v5h5"/>
                        <path d="M12 7v5l4 2"/>
                    </svg>
                    <span>Riwayat Audit</span>
                </span>
            </a>
        </nav>
    </aside>

    <!-- SIDEBAR EDGE TOGGLE -->
    <button type="button" class="sidebar-edge-toggle" id="sidebarToggleBtn" onclick="toggleSidebar()" title="Toggle Sidebar" aria-label="Toggle Sidebar">&lt;</button>

    <div class="main-wrapper">
        <header class="topbar">
            <div class="topbar-left">
                <span class="topbar-title">Detail Antrean — {{ $activity->feeding_record_ref }}</span>
                @if($activity->status === 'UNDER_REVIEW')
                    <span class="status-label status-temp">Menunggu Review</span>
                @elseif($activity->status === 'VERIFIED')
                    <span class="status-label status-active">Disetujui</span>
                @elseif($activity->status === 'REJECTED')
                    <span class="status-label status-rejected">Ditolak</span>
                @endif
            </div>
            <a href="{{ $backUrl ?? '/api/v1/feeding/admin-preview?tab=reviews' }}" class="btn btn-neutral btn-sm">
                Kembali ke Antrean
            </a>
        </header>

        <main class="page-content">
            @if(request()->filled('error'))
                <div class="alert">{{ request()->query('error') }}</div>
            @endif

            <div class="detail-layout">
                <!-- LEFT COLUMN -->
                <div class="detail-main">
                    <!-- INFORMASI UTAMA & FEEDING -->
                    <div class="section-box">
                        <div class="section-header">
                            <h2 class="section-title">Informasi Pengajuan &amp; Pemberian Pakan</h2>
                        </div>
                        <div class="section-body">
                            <dl class="info-grid">
                                <dt>Kode Referensi</dt>
                                <dd>{{ $activity->feeding_record_ref }}</dd>
                                <dt>Nama Relawan</dt>
                                <dd>{{ $activity->user?->name ?? 'Relawan Kampus' }} ({{ $activity->user?->user_type ?? 'MAHASISWA' }})</dd>
                                <dt>Lokasi Spot</dt>
                                <dd>{{ $activity->spot?->name ?? '-' }} ({{ $activity->spot?->code ?? '-' }})</dd>
                                @if($activity->cat)
                                    <dt>Kucing</dt>
                                    <dd>{{ $activity->cat->name }} ({{ $activity->cat->unique_code }})</dd>
                                @endif
                            </dl>

                            <div class="divider"></div>

                            <dl class="info-grid">
                                <dt>Jenis &amp; Takaran Pakan</dt>
                                <dd>{{ strtoupper((string) $activity->food_type) }} — {{ $activity->food_amount ?: '-' }}</dd>
                                <dt>Waktu Scan QR</dt>
                                <dd>{{ $activity->scanned_at?->format('d M Y, H:i:s') ?? '-' }}</dd>
                                <dt>Waktu Unggah Bukti</dt>
                                <dd>{{ $activity->finalized_at?->format('d M Y, H:i:s') ?? '-' }}</dd>
                                <dt>Catatan Relawan</dt>
                                <dd>{{ $activity->notes ?: '-' }}</dd>
                            </dl>
                        </div>
                    </div>

                    <!-- BUKTI FOTO -->
                    <div class="section-box">
                        <div class="section-header">
                            <h2 class="section-title">Foto Bukti Pemberian Makan</h2>
                        </div>
                        <div class="section-body">
                            <div class="evidence-grid">
                                @forelse($activity->evidence as $ev)
                                    <div class="evidence-card">
                                        <img src="{{ $ev->signed_url }}" alt="Foto Bukti {{ $activity->feeding_record_ref }}" onclick="openLightbox('{{ $ev->signed_url }}')">
                                        <div class="evidence-caption">
                                            <span>Diambil: {{ $ev->captured_at?->format('d M Y, H:i:s') ?? '-' }}</span>
                                            <button type="button" class="btn btn-neutral btn-sm" onclick="openLightbox('{{ $ev->signed_url }}')">Perbesar</button>
                                        </div>
                                    </div>
                                @empty
                                    <div style="color: var(--text-muted);">Tidak ada foto bukti terlampir.</div>
                                @endforelse
                            </div>
                        </div>
                    </div>

                    <!-- INDIKATOR PEMERIKSAAN -->
                    <div class="section-box">
                        <div class="section-header">
                            <h2 class="section-title">Indikator Pemeriksaan</h2>
                        </div>
                        <div class="section-body">
                            <div class="flag-list">
                                @forelse($activity->flags ?? [] as $flag)
                                    <div class="flag-row">
                                        <strong>{{ $flag }}</strong>
                                        <span>{{ $flagLabels[$flag] ?? 'Perlu pemeriksaan manual oleh reviewer.' }}</span>
                                    </div>
                                @empty
                                    <div style="color: var(--text-muted); font-size: 13px;">Tidak ada catatan indikator khusus.</div>
                                @endforelse
                            </div>

                            @if($activity->ruleResults && $activity->ruleResults->count() > 0)
                                <table class="simple-table">
                                    <thead>
                                        <tr>
                                            <th>Aturan</th>
                                            <th>Hasil</th>
                                            <th>Keterangan</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @foreach($activity->ruleResults as $r)
                                            <tr>
                                                <td style="font-weight: 600;">{{ $r->rule }}</td>
                                                <td>{{ $r->result }}</td>
                                                <td style="color: var(--text-secondary);">{{ $r->detail }}</td>
                                            </tr>
                                        @endforeach
                                    </tbody>
                                </table>
                            @endif
                        </div>
                    </div>
                </div>

                <!-- RIGHT COLUMN: KEPUTUSAN REVIEWER -->
                <div class="detail-side">
                    <div class="section-box">
                        <div class="section-header">
                            <h2 class="section-title">Panel Keputusan Reviewer</h2>
                        </div>
                        <div class="section-body">
                            <form method="POST" action="{{ $reviewActionUrl ?? '/api/v1/admin/feeding/activities/' . $activity->id . '/review' }}" id="reviewDecisionForm" onsubmit="return handleDecisionSubmit(event);">
                                @csrf
                                <input type="hidden" name="decision" id="selectedDecisionInput" value="VERIFIED">

                                <div style="margin-bottom: 6px;">
                                    <label for="reasonInput" style="font-size: 13px; font-weight: 600; color: var(--text-secondary);">
                                        Alasan Keputusan *
                                    </label>
                                </div>
                                <textarea
                                    id="reasonInput"
                                    name="reason"
                                    class="textarea-control"
                                    required
                                    placeholder="Tuliskan alasan persetujuan atau penolakan..."
                                >{{ $activity->latestReview?->reason ?? '' }}</textarea>

                                <div id="decisionErrorText" style="display: none; color: var(--danger); font-size: 12.5px; margin-top: 6px;">
                                    Alasan keputusan wajib diisi.
                                </div>

                                <div class="decision-actions">
                                    <button
                                        type="submit"
                                        class="btn btn-success"
                                        id="btnApproveDecision"
                                        onclick="document.getElementById('selectedDecisionInput').value = 'VERIFIED';"
                                    >
                                        <span id="btnApproveText">Setujui</span>
                                    </button>
                                    <button
                                        type="submit"
                                        class="btn btn-danger"
                                        id="btnRejectDecision"
                                        onclick="document.getElementById('selectedDecisionInput').value = 'REJECTED';"
                                    >
                                        <span id="btnRejectText">Tolak</span>
                                    </button>
                                </div>
                            </form>

                            @if($activity->reviews && $activity->reviews->count() > 0)
                                <div class="divider"></div>
                                <div style="font-size: 12.5px; font-weight: 600; color: var(--text-secondary); margin-bottom: 8px;">
                                    Riwayat Keputusan Sebelumnya
                                </div>
                                @foreach($activity->reviews->sortByDesc('created_at') as $rev)
                                    <div style="font-size: 13px; padding: 8px 0; border-bottom: 1px solid var(--border);">
                                        <strong>{{ $rev->decision === 'REJECTED' ? 'Ditolak' : 'Disetujui' }}</strong>
                                        oleh {{ $rev->reviewer?->name ?? 'Admin' }}
                                        <div style="color: var(--text-secondary); margin-top: 2px;">{{ $rev->reason }}</div>
                                    </div>
                                @endforeach
                            @endif
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </div>

    <!-- LIGHTBOX -->
    <div class="lightbox-backdrop" id="photoLightbox" onclick="closeLightbox()">
        <div class="lightbox-box" onclick="event.stopPropagation()">
            <img src="" id="lightboxImg" alt="Foto Bukti">
        </div>
    </div>

    <script>
        function syncSidebarToggleSymbol() {
            const btn = document.getElementById('sidebarToggleBtn');
            const sidebar = document.getElementById('appSidebar');
            if (!btn || !sidebar) return;

            if (window.innerWidth <= 1024) {
                const isOpen = sidebar.classList.contains('mobile-open');
                btn.innerHTML = isOpen ? '&lt;' : '&gt;';
            } else {
                const isCollapsed = document.body.classList.contains('sidebar-collapsed');
                btn.innerHTML = isCollapsed ? '&gt;' : '&lt;';
            }
        }

        function toggleSidebar() {
            const sidebar = document.getElementById('appSidebar');
            if (window.innerWidth <= 1024) {
                sidebar.classList.toggle('mobile-open');
            } else {
                document.body.classList.toggle('sidebar-collapsed');
                localStorage.setItem('meowtopia_sidebar_collapsed', document.body.classList.contains('sidebar-collapsed') ? '1' : '0');
            }
            syncSidebarToggleSymbol();
        }

        (function restoreSidebarState() {
            if (window.innerWidth > 1024 && localStorage.getItem('meowtopia_sidebar_collapsed') === '1') {
                document.body.classList.add('sidebar-collapsed');
            }
            syncSidebarToggleSymbol();
            window.addEventListener('resize', syncSidebarToggleSymbol);
        })();

        function handleDecisionSubmit(e) {
            const reason = document.getElementById('reasonInput').value.trim();
            const errEl = document.getElementById('decisionErrorText');
            if (!reason) {
                e.preventDefault();
                errEl.style.display = 'block';
                document.getElementById('reasonInput').focus();
                return false;
            }
            errEl.style.display = 'none';
            document.getElementById('btnApproveDecision').disabled = true;
            document.getElementById('btnRejectDecision').disabled = true;
            return true;
        }

        function openLightbox(url) {
            document.getElementById('lightboxImg').src = url;
            document.getElementById('photoLightbox').classList.add('open');
        }

        function closeLightbox() {
            document.getElementById('photoLightbox').classList.remove('open');
        }
    </script>
</body>
</html>
