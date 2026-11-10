<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Filament Admin Panel — Adopt Feeding Spot (AFS)</title>
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #F8FAFC;
            color: #0F172A;
            margin: 0;
            display: flex;
            min-height: 100vh;
        }
        .sidebar {
            width: 260px;
            background: #0F172A;
            color: #F8FAFC;
            padding: 24px 16px;
            flex-shrink: 0;
        }
        .brand {
            font-size: 18px;
            font-weight: 800;
            color: #F59E0B;
            padding: 0 12px 20px 12px;
            border-bottom: 1px solid #1E293B;
            margin-bottom: 20px;
        }
        .nav-group {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: #94A3B8;
            padding: 0 12px;
            margin-bottom: 8px;
            font-weight: 700;
        }
        .nav-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 12px;
            border-radius: 8px;
            color: #E2E8F0;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 4px;
        }
        .nav-item.active {
            background: #1E293B;
            color: #F59E0B;
        }
        .nav-badge {
            background: #F59E0B;
            color: #0F172A;
            font-size: 11px;
            font-weight: 800;
            padding: 2px 8px;
            border-radius: 999px;
        }
        .main {
            flex: 1;
            padding: 32px;
            max-width: 1200px;
        }
        .topbar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 28px;
        }
        .page-title {
            font-size: 24px;
            font-weight: 800;
            margin: 0;
        }
        .page-subtitle {
            color: #64748B;
            font-size: 14px;
            margin-top: 4px;
        }
        .card {
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 12px;
            padding: 24px;
            margin-bottom: 28px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }
        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }
        .card-title {
            font-size: 17px;
            font-weight: 700;
            margin: 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 14px;
        }
        th {
            text-align: left;
            padding: 12px;
            background: #F8FAFC;
            color: #475569;
            font-size: 12px;
            text-transform: uppercase;
            border-bottom: 1px solid #E2E8F0;
        }
        td {
            padding: 14px 12px;
            border-bottom: 1px solid #F1F5F9;
            vertical-align: middle;
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            margin-right: 4px;
        }
        .badge-warning { background: #FEF3C7; color: #92400E; }
        .badge-success { background: #DCFCE7; color: #166534; }
        .badge-danger { background: #FEE2E2; color: #991B1B; }
        .badge-info { background: #E0F2FE; color: #075985; }
        .btn {
            display: inline-block;
            padding: 8px 14px;
            border-radius: 6px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            border: none;
            cursor: pointer;
        }
        .btn-primary { background: #D97706; color: #FFFFFF; }
        .btn-info { background: #0284C7; color: #FFFFFF; }
        .btn-success { background: #16A34A; color: #FFFFFF; }
        .alert {
            padding: 12px 16px;
            background: #DCFCE7;
            color: #166534;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <aside class="sidebar">
        <div class="brand">🐾 Meowtopia Admin</div>
        <div class="nav-group">Adopt Feeding Spot</div>
        <a href="#review-queue" class="nav-item active">
            <span>Antrean Review Pakan</span>
            @if($pendingActivities->count() > 0)
                <span class="nav-badge">{{ $pendingActivities->count() }}</span>
            @endif
        </a>
        <a href="#spots" class="nav-item">
            <span>Titik Makan (Spots)</span>
            <span class="nav-badge" style="background:#334155;color:#F8FAFC;">{{ $spots->count() }}</span>
        </a>
        <div style="margin-top: 32px; padding: 12px; background: #1E293B; border-radius: 8px; font-size: 12px; color: #94A3B8; line-height: 1.5;">
            <strong style="color:#F8FAFC;">Login Aktif:</strong><br>
            Spot Admin Acumalaka<br>
            <code style="color:#F59E0B;">feeding.review</code> &bull; <code style="color:#F59E0B;">spot.manage</code>
        </div>
    </aside>

    <main class="main">
        @if(session('status'))
            <div class="alert">{{ session('status') }}</div>
        @endif

        <div class="topbar">
            <div>
                <h1 class="page-title">Panel Admin — Adopt Feeding Spot (MEOW-21 &amp; MEOW-22)</h1>
                <div class="page-subtitle">Kelola Antrean Review Bukti Pakan (Signed URL 10 Menit) &amp; Titik Makan Resmi Kampus</div>
            </div>
            <a href="http://127.0.0.1:3000" target="_blank" class="btn btn-primary">Buka Aplikasi Flutter (:3000) &rarr;</a>
        </div>

        <div id="review-queue" class="card">
            <div class="card-header">
                <h2 class="card-title">1. Antrean Review Pakan (MEOW-22 &bull; Status: UNDER_REVIEW)</h2>
                <span class="badge badge-warning">{{ $pendingActivities->count() }} Menunggu Keputusan</span>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Kode Referensi</th>
                        <th>Relawan / Feeder</th>
                        <th>Titik Pakan</th>
                        <th>Jenis &amp; Porsi</th>
                        <th>Bendera Sistem (Flags)</th>
                        <th>Rule Engine</th>
                        <th>Foto Bukti</th>
                        <th>Aksi Reviewer</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($pendingActivities as $act)
                        <tr>
                            <td><code>{{ $act->feeding_record_ref }}</code></td>
                            <td>
                                <strong>{{ $act->user->name ?? 'Mahasiswa' }}</strong><br>
                                <span style="font-size:12px;color:#64748B;">{{ $act->user->user_type ?? 'MAHASISWA' }} (Privasi terjaga)</span>
                            </td>
                            <td>{{ $act->spot->name ?? '-' }} (<code>{{ $act->spot->code ?? '-' }}</code>)</td>
                            <td>{{ ucfirst(str_replace('_', ' ', (string) $act->food_type)) }} &bull; {{ $act->food_amount ?? '1 porsi' }}</td>
                            <td>
                                @forelse(($act->flags ?? []) as $flag)
                                    <span class="badge badge-warning">{{ $flag }}</span>
                                @empty
                                    <span class="badge badge-info">NORMAL</span>
                                @endforelse
                            </td>
                            <td>
                                @foreach($act->ruleResults as $r)
                                    <span class="badge {{ $r->result === 'PASS' ? 'badge-success' : 'badge-warning' }}">{{ $r->rule }}: {{ $r->result }}</span>
                                @endforeach
                            </td>
                            <td>
                                <span class="badge badge-info">{{ $act->evidence->count() }} Foto (Signed 10m)</span>
                            </td>
                            <td>
                                <a href="/api/v1/feeding/admin-preview/reviews/{{ $act->id }}" class="btn btn-info">Lihat Bukti &amp; Review</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" style="text-align:center;color:#64748B;padding:24px;">Tidak ada antrean UNDER_REVIEW saat ini. Semua pengajuan telah diperiksa!</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <div id="spots" class="card">
            <div class="card-header">
                <h2 class="card-title">2. Daftar Titik Makan Resmi &amp; Cetak QR (MEOW-21)</h2>
                <span class="badge badge-success">{{ $spots->count() }} Spot Terdaftar</span>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Kode Spot</th>
                        <th>Nama Titik Pakan</th>
                        <th>Status Operasional</th>
                        <th>Payload QR Resmi</th>
                        <th>Aksi Admin</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($spots as $spot)
                        <tr>
                            <td><code>{{ $spot->code }}</code></td>
                            <td><strong>{{ $spot->name }}</strong><br><span style="font-size:12px;color:#64748B;">{{ $spot->description }}</span></td>
                            <td><span class="badge badge-success">{{ $spot->status }}</span></td>
                            <td><code>MTP1.S.{{ substr($spot->qr_token, 0, 12) }}...</code></td>
                            <td>
                                <a href="/api/v1/feeding/admin-preview/spots/{{ $spot->id }}/qr-sheet" target="_blank" class="btn btn-primary">Cetak Lembar QR</a>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </main>
</body>
</html>
