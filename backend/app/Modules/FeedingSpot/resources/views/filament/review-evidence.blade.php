<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Review Bukti Pakan - {{ $activity->feeding_record_ref }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #F8FAFC;
            color: #1E293B;
            margin: 0;
            padding: 24px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: #FFFFFF;
            border-radius: 12px;
            border: 1px solid #E2E8F0;
            padding: 28px;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid #E2E8F0;
            padding-bottom: 18px;
            margin-bottom: 24px;
        }
        .title {
            font-size: 20px;
            font-weight: 700;
            color: #0F172A;
        }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 9999px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge-warning { background: #FEF3C7; color: #92400E; }
        .badge-success { background: #DCFCE7; color: #166534; }
        .badge-danger { background: #FEE2E2; color: #991B1B; }
        .grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }
        .info-card {
            background: #F8FAFC;
            border: 1px solid #E2E8F0;
            border-radius: 8px;
            padding: 14px 18px;
        }
        .info-label {
            font-size: 12px;
            color: #64748B;
            margin-bottom: 4px;
            text-transform: uppercase;
            font-weight: 600;
        }
        .info-value {
            font-size: 15px;
            font-weight: 600;
            color: #1E293B;
        }
        .section-title {
            font-size: 16px;
            font-weight: 700;
            margin: 20px 0 12px 0;
            color: #334155;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .rule-list {
            list-style: none;
            padding: 0;
            margin: 0 0 24px 0;
        }
        .rule-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 14px;
            border-bottom: 1px solid #F1F5F9;
        }
        .photos-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 28px;
        }
        .photo-card {
            border: 1px solid #CBD5E1;
            border-radius: 8px;
            overflow: hidden;
            background: #000;
            text-align: center;
        }
        .photo-card img {
            width: 100%;
            height: 220px;
            object-fit: cover;
            display: block;
        }
        .photo-meta {
            padding: 8px;
            background: #F8FAFC;
            font-size: 12px;
            color: #64748B;
        }
        .actions-bar {
            display: flex;
            gap: 12px;
            justify-content: flex-end;
            border-top: 1px solid #E2E8F0;
            padding-top: 20px;
        }
        .btn {
            padding: 10px 20px;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            border: none;
            cursor: pointer;
            text-decoration: none;
        }
        .btn-success { background: #16A34A; color: white; }
        .btn-danger { background: #DC2626; color: white; }
        .btn-secondary { background: #E2E8F0; color: #475569; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div>
                <div class="title">Review Aktivitas Pakan Kampus</div>
                <div style="font-size: 13px; color: #64748B; margin-top: 4px;">Referensi: <code>{{ $activity->feeding_record_ref }}</code></div>
            </div>
            <div class="badge badge-warning">MENUNGGU REVIEW (UNDER_REVIEW)</div>
        </div>

        <div class="grid">
            <div class="info-card">
                <div class="info-label">Relawan / Feeder</div>
                <div class="info-value">{{ $activity->user->name ?? 'Mahasiswa' }} ({{ $activity->user->email ?? '-' }})</div>
            </div>
            <div class="info-card">
                <div class="info-label">Spot Pakan</div>
                <div class="info-value">{{ $activity->spot->name ?? 'Spot' }} ({{ $activity->spot->code ?? '-' }})</div>
            </div>
            <div class="info-card">
                <div class="info-label">Waktu Sesi</div>
                <div class="info-value">Pindai: {{ $activity->scanned_at }} | Selesai: {{ $activity->finalized_at }}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Detail Pakan</div>
                <div class="info-value">{{ ucfirst(str_replace('_', ' ', $activity->food_type)) }} &bull; {{ $activity->food_amount ?? 'Porsi standar' }}</div>
            </div>
        </div>

        <div class="section-title">Hasil Pemeriksaan Mesin Aturan (Rule Engine R1-R8)</div>
        <ul class="rule-list">
            @forelse($activity->ruleResults as $rule)
                <li class="rule-item">
                    <div>
                        <strong>{{ $rule->rule }}</strong>: <span style="color: #64748B;">{{ $rule->detail ?? 'Evaluasi otomatis' }}</span>
                    </div>
                    <span class="badge {{ $rule->result === 'PASS' ? 'badge-success' : ($rule->result === 'REVIEW' ? 'badge-warning' : 'badge-danger') }}">
                        {{ $rule->result }}
                    </span>
                </li>
            @empty
                <li class="rule-item" style="color: #64748B;">Tidak ada catatan anomali sistem.</li>
            @endforelse
        </ul>

        <div class="section-title">Foto Bukti Pemberian Makan ({{ $activity->evidence->count() }} Foto)</div>
        <div class="photos-grid">
            @forelse($activity->evidence as $idx => $ev)
                <div class="photo-card">
                    <img src="{{ $ev->media_url ?? 'data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%22240%22 height=%22200%22><rect width=%22240%22 height=%22200%22 fill=%22%23e2e8f0%22/><text x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 fill=%22%2364748b%22>Foto Bukti</text></svg>' }}" alt="Bukti Pakan">
                    <div class="photo-meta">
                        Foto #{{ $idx + 1 }} &bull; Diambil: {{ $ev->captured_at }}
                    </div>
                </div>
            @empty
                <div style="grid-column: 1 / -1; color: #64748B; font-style: italic;">Tidak ada foto bukti terlampir.</div>
            @endforelse
        </div>

        <div class="actions-bar">
            <button onclick="window.history.back()" class="btn btn-secondary">Kembali</button>
            <form method="POST" action="/api/v1/admin/feeding/activities/{{ $activity->id }}/review" style="display:inline;">
                <input type="hidden" name="decision" value="REJECTED">
                <input type="hidden" name="reason" value="Foto bukti tidak memenuhi kriteria verifikasi">
                <button type="submit" class="btn btn-danger" onclick="return confirm('Tolak pengajuan pakan ini?')">Tolak (REJECTED)</button>
            </form>
            <form method="POST" action="/api/v1/admin/feeding/activities/{{ $activity->id }}/review" style="display:inline;">
                <input type="hidden" name="decision" value="VERIFIED">
                <button type="submit" class="btn btn-success" onclick="return confirm('Setujui pengajuan pakan ini dan kreditkan poin?')">Setujui (VERIFIED)</button>
            </form>
        </div>
    </div>
</body>
</html>
