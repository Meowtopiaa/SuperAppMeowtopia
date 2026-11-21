<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Meowtopia Admin — Feeding Spot</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" crossorigin="" />
    <style>
        :root {
            /* Clean Neutral Surfaces */
            --bg-page: #F4F6F9;
            --surface: #FFFFFF;
            --surface-subtle: #F8FAFC;
            --border: #E2E8F0;
            --border-strong: #CBD5E1;

            /* Typography */
            --text-primary: #0F172A;
            --text-secondary: #475569;
            --text-muted: #64748B;

            /* Dark Navy Blue Collapsible Sidebar */
            --sidebar-navy: #0B192C;
            --sidebar-navy-hover: #152B4A;
            --sidebar-navy-border: #1C3559;
            --sidebar-text: #D5E2F2;
            --sidebar-text-muted: #8AA4C8;
            --sidebar-w: 248px;
            --sidebar-collapsed-w: 76px;

            /* Functional Action Colors */
            --primary: #EA580C;
            --primary-hover: #C2410C;
            --edit: #1D4ED8;
            --edit-bg: #EFF6FF;
            --edit-border: #BFDBFE;
            --success: #15803D;
            --success-bg: #F0FDF4;
            --success-border: #BBF7D0;
            --warning: #B45309;
            --warning-bg: #FFFBEB;
            --warning-border: #FDE68A;
            --danger: #DC2626;
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

        /* ================= NAVY COLLAPSIBLE SIDEBAR & EDGE TOGGLE ================= */
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
            overflow: visible;
            transition: width 0.26s cubic-bezier(0.4, 0, 0.2, 1), transform 0.26s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .sidebar-edge-toggle {
            position: fixed;
            top: 21px;
            left: var(--sidebar-w);
            z-index: 65;
            width: 22px;
            height: 34px;
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
            transition: left 0.26s cubic-bezier(0.4, 0, 0.2, 1), background 0.15s ease;
            user-select: none;
        }

        .sidebar-edge-toggle:hover {
            background: var(--sidebar-navy-hover);
        }

        .sidebar-brand {
            position: relative;
            padding: 18px 19px;
            border-bottom: 1px solid var(--sidebar-navy-border);
            display: flex;
            align-items: center;
            gap: 12px;
            min-height: 75px;
            transition: gap 0.26s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .sidebar-logo {
            width: 38px;
            height: 38px;
            border-radius: 8px;
            object-fit: cover;
            flex-shrink: 0;
            background: #FFFFFF;
            border: 1.5px solid rgba(255, 255, 255, 0.22);
            transition: border-radius 0.26s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.26s ease, box-shadow 0.26s ease;
        }

        .sidebar-brand-text {
            overflow: hidden;
            white-space: nowrap;
            max-width: 170px;
            opacity: 1;
            transition: max-width 0.26s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.18s ease;
        }

        .sidebar-brand-title {
            font-size: 15px;
            font-weight: 800;
            letter-spacing: 0.04em;
            color: #FFFFFF;
            line-height: 1.2;
        }

        .sidebar-brand-sub {
            font-size: 12px;
            color: var(--sidebar-text-muted);
            margin-top: 2px;
        }

        .sidebar-nav {
            padding: 14px 12px;
            flex: 1;
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .nav-item {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            border-radius: 8px;
            color: var(--sidebar-text);
            text-decoration: none;
            font-size: 13.5px;
            font-weight: 500;
            border: none;
            background: transparent;
            width: 100%;
            text-align: left;
            cursor: pointer;
            font-family: inherit;
            transition: background 0.18s ease, color 0.18s ease, padding 0.26s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.18s ease;
        }

        .nav-item-label {
            display: inline-flex;
            align-items: center;
            gap: 11px;
            min-width: 0;
            transition: gap 0.26s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .nav-item-text {
            white-space: nowrap;
            overflow: hidden;
            max-width: 150px;
            opacity: 1;
            transition: max-width 0.26s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.18s ease;
        }

        .nav-icon {
            width: 18px;
            height: 18px;
            flex-shrink: 0;
            stroke: currentColor;
            opacity: 0.92;
        }

        .nav-item:hover {
            background: var(--sidebar-navy-hover);
            color: #FFFFFF;
        }

        .nav-item.active {
            background: var(--primary);
            color: #FFFFFF;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(234, 88, 12, 0.28);
        }

        .nav-count {
            font-size: 11.5px;
            font-weight: 600;
            padding: 1px 7px;
            border-radius: 4px;
            background: rgba(255, 255, 255, 0.14);
            color: #FFFFFF;
            white-space: nowrap;
            overflow: hidden;
            max-width: 48px;
            opacity: 1;
            flex-shrink: 0;
            transition: max-width 0.26s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.18s ease, padding 0.26s ease;
        }

        .nav-item.active .nav-count {
            background: rgba(0, 0, 0, 0.22);
        }

        /* ================= MAIN WRAPPER & TOPBAR ================= */
        .main-wrapper {
            flex: 1;
            margin-left: var(--sidebar-w);
            min-width: 0;
            display: flex;
            flex-direction: column;
            transition: margin-left 0.26s cubic-bezier(0.4, 0, 0.2, 1);
        }

        @media (min-width: 1025px) {
            body.sidebar-collapsed .sidebar {
                width: var(--sidebar-collapsed-w);
            }

            body.sidebar-collapsed .sidebar-edge-toggle {
                left: var(--sidebar-collapsed-w);
            }

            body.sidebar-collapsed .main-wrapper {
                margin-left: var(--sidebar-collapsed-w);
            }

            body.sidebar-collapsed .sidebar-brand {
                gap: 0;
            }

            body.sidebar-collapsed .sidebar-logo {
                border-radius: 50%;
                border-color: rgba(255, 255, 255, 0.35);
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.28);
            }

            body.sidebar-collapsed .sidebar-brand-text {
                max-width: 0;
                opacity: 0;
                pointer-events: none;
            }

            body.sidebar-collapsed .nav-item {
                padding: 10px 17px;
            }

            body.sidebar-collapsed .nav-item-label {
                gap: 0;
            }

            body.sidebar-collapsed .nav-item-text {
                max-width: 0;
                opacity: 0;
                pointer-events: none;
            }

            body.sidebar-collapsed .nav-count {
                max-width: 0;
                opacity: 0;
                padding: 0;
                margin: 0;
                pointer-events: none;
            }

            /* Custom Tooltip on Collapsed Icons */
            body.sidebar-collapsed .sidebar .nav-item[data-tooltip]::after,
            body.sidebar-collapsed .sidebar .sidebar-brand[data-tooltip]::after {
                content: attr(data-tooltip);
                position: absolute;
                left: calc(100% + 12px);
                top: 50%;
                transform: translateY(-50%) translateX(-4px);
                background: #0F172A;
                color: #F8FAFC;
                border: 1px solid #334155;
                padding: 6px 11px;
                border-radius: 6px;
                font-size: 12.5px;
                font-weight: 600;
                white-space: nowrap;
                box-shadow: 0 10px 25px -5px rgba(2, 6, 23, 0.45);
                opacity: 0;
                visibility: hidden;
                pointer-events: none;
                z-index: 120;
                transition: opacity 0.16s ease, transform 0.16s ease, visibility 0.16s ease;
            }

            body.sidebar-collapsed .sidebar .sidebar-brand[data-tooltip]::after {
                left: calc(100% + 30px);
            }

            body.sidebar-collapsed .sidebar .nav-item[data-tooltip]:hover::after,
            body.sidebar-collapsed .sidebar .nav-item[data-tooltip]:focus-visible::after,
            body.sidebar-collapsed .sidebar .sidebar-brand[data-tooltip]:hover::after {
                opacity: 1;
                visibility: visible;
                transform: translateY(-50%) translateX(0);
            }
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

        .topbar-title {
            font-size: 16px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .page-content {
            padding: 24px 28px 48px 36px;
            max-width: 1360px;
            width: 100%;
            margin: 0 auto;
        }

        /* ================= BUTTONS ================= */
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
            transition: background 0.15s ease, border-color 0.15s ease;
            font-family: inherit;
            line-height: 1.25;
            white-space: nowrap;
        }

        .btn:disabled {
            opacity: 0.55;
            cursor: not-allowed;
        }

        .btn-sm {
            padding: 5px 10px;
            font-size: 12.5px;
        }

        .btn-primary {
            background: var(--primary);
            color: #FFFFFF;
            border-color: var(--primary);
        }
        .btn-primary:hover:not(:disabled) {
            background: var(--primary-hover);
            border-color: var(--primary-hover);
        }

        .btn-edit {
            background: var(--edit-bg);
            color: var(--edit);
            border-color: var(--edit-border);
        }
        .btn-edit:hover:not(:disabled) {
            background: #DBEAFE;
        }

        .btn-danger {
            background: var(--danger-bg);
            color: var(--danger);
            border-color: var(--danger-border);
        }
        .btn-danger:hover:not(:disabled) {
            background: #FEE2E2;
        }

        .btn-success {
            background: var(--success-bg);
            color: var(--success);
            border-color: var(--success-border);
        }
        .btn-success:hover:not(:disabled) {
            background: #DCFCE7;
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

        /* ================= ALERTS ================= */
        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            font-size: 13.5px;
            font-weight: 500;
        }

        .alert-success {
            background: var(--success-bg);
            border: 1px solid var(--success-border);
            color: var(--success);
        }

        .alert-danger {
            background: var(--danger-bg);
            border: 1px solid var(--danger-border);
            color: var(--danger);
        }

        .alert-close {
            background: none;
            border: none;
            color: inherit;
            cursor: pointer;
            font-size: 18px;
            line-height: 1;
            padding: 0 4px;
        }

        /* ================= CLEAN SUMMARY METRICS ================= */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 12px;
            margin-bottom: 20px;
        }

        .stat-item {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 14px 16px;
            text-decoration: none;
            color: inherit;
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            transition: border-color 0.15s ease;
        }

        .stat-item:hover {
            border-color: var(--border-strong);
        }

        .stat-item.active {
            border-color: var(--primary);
            background: #FFFBF7;
        }

        .stat-label {
            font-size: 13px;
            font-weight: 500;
            color: var(--text-secondary);
        }

        .stat-value {
            font-size: 20px;
            font-weight: 700;
            color: var(--text-primary);
        }

        /* ================= MAIN PANEL & TOOLBAR ================= */
        .panel {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
        }

        .toolbar {
            padding: 14px 18px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            flex-wrap: wrap;
        }

        .toolbar-filters {
            display: flex;
            align-items: center;
            gap: 8px;
            flex: 1;
            min-width: 260px;
        }

        .input-control, .select-control {
            padding: 7px 11px;
            border: 1px solid var(--border-strong);
            border-radius: 6px;
            font-size: 13px;
            font-family: inherit;
            color: var(--text-primary);
            background: var(--surface);
            outline: none;
        }

        .input-control:focus, .select-control:focus {
            border-color: var(--primary);
        }

        .input-search {
            width: 280px;
            max-width: 100%;
        }

        /* ================= TABLES ================= */
        .table-scroll {
            overflow-x: auto;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        table.data-table th {
            padding: 11px 16px;
            font-size: 12px;
            font-weight: 600;
            color: var(--text-secondary);
            background: var(--surface-subtle);
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
        }

        table.data-table td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            vertical-align: middle;
            font-size: 13.5px;
        }

        table.data-table tbody tr:last-child td {
            border-bottom: none;
        }

        table.data-table tbody tr:hover {
            background: #FAFBFD;
        }

        .spot-code {
            font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
            font-size: 12.5px;
            font-weight: 600;
            color: var(--text-primary);
        }

        /* Simple Status Labels (No Decorative Dots) */
        .status-label {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            white-space: nowrap;
        }

        .status-active {
            background: var(--success-bg);
            color: var(--success);
        }

        .status-temp {
            background: var(--warning-bg);
            color: var(--warning);
        }

        .status-inactive {
            background: #F1F5F9;
            color: #475569;
        }

        .status-rejected {
            background: var(--danger-bg);
            color: var(--danger);
        }

        .row-actions {
            display: flex;
            align-items: center;
            gap: 6px;
            flex-wrap: nowrap;
        }

        /* Cat Dropdown in Table (Point 4) */
        .cat-dropdown {
            min-width: 185px;
            max-width: 220px;
            padding: 5px 9px;
            font-size: 12.5px;
            border: 1px solid var(--border-strong);
            border-radius: 6px;
            background: var(--surface);
            color: var(--text-primary);
            cursor: pointer;
        }

        .cat-dropdown:focus {
            border-color: var(--primary);
            outline: none;
        }

        .table-footer {
            padding: 12px 18px;
            background: var(--surface-subtle);
            border-top: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 12.5px;
            color: var(--text-muted);
        }

        /* ================= MODALS ================= */
        .modal-backdrop {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.45);
            z-index: 100;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }

        .modal-backdrop.open {
            display: flex;
        }

        .modal-box {
            background: var(--surface);
            border-radius: 10px;
            border: 1px solid var(--border);
            width: 100%;
            max-width: 780px;
            max-height: 90vh;
            display: flex;
            flex-direction: column;
            box-shadow: 0 20px 40px -15px rgba(15, 23, 42, 0.2);
            overflow: hidden;
        }

        .modal-box.modal-sm {
            max-width: 540px;
        }

        .modal-form-flex {
            display: flex;
            flex-direction: column;
            flex: 1;
            min-height: 0;
            overflow: hidden;
        }

        .modal-header {
            padding: 15px 20px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
        }

        .modal-header h3 {
            font-size: 15.5px;
            font-weight: 700;
            color: var(--text-primary);
        }

        .btn-icon-close {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 34px;
            height: 34px;
            border-radius: 6px;
            border: 1px solid var(--border-strong);
            background: var(--surface);
            color: var(--text-secondary);
            cursor: pointer;
            padding: 0;
            flex-shrink: 0;
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease;
        }

        .btn-icon-close:hover {
            background: var(--surface-subtle);
            color: var(--text-primary);
            border-color: var(--text-muted);
        }

        .btn-icon-only {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            border-radius: 6px;
            border: 1px solid var(--border-strong);
            background: var(--surface);
            color: var(--text-secondary);
            cursor: pointer;
            padding: 0;
            flex-shrink: 0;
            transition: background 0.15s ease, color 0.15s ease, border-color 0.15s ease, transform 0.15s ease;
        }

        .btn-icon-only:hover {
            background: var(--surface-subtle);
            color: var(--primary);
            border-color: var(--primary);
        }

        .btn-icon-only:active {
            transform: scale(0.96);
        }

        .modal-body {
            padding: 18px 20px;
            overflow-y: auto;
            flex: 1;
            min-height: 0;
        }

        .modal-footer {
            padding: 13px 20px;
            border-top: 1px solid var(--border);
            background: var(--surface-subtle);
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 8px;
            flex-shrink: 0;
        }

        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 14px;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .form-group.full {
            grid-column: 1 / -1;
        }

        .form-label {
            font-size: 12.5px;
            font-weight: 600;
            color: var(--text-secondary);
        }

        #spotPickerMap {
            width: 100%;
            height: 260px;
            border-radius: 6px;
            border: 1px solid var(--border-strong);
        }

        .map-info-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            padding: 9px 12px;
            background: var(--surface-subtle);
            border: 1px solid var(--border);
            border-radius: 6px;
            font-size: 12.5px;
            margin-top: 6px;
        }

        .area-identified-tag {
            font-weight: 600;
            color: var(--sidebar-navy);
        }

        .tab-section {
            display: none;
        }
        .tab-section.active {
            display: block;
        }

        .detail-dl {
            display: grid;
            grid-template-columns: 145px 1fr;
            row-gap: 10px;
            column-gap: 12px;
            font-size: 13.5px;
        }

        .detail-dl dt {
            color: var(--text-muted);
        }

        .detail-dl dd {
            color: var(--text-primary);
            font-weight: 500;
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
        }

        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
            .form-grid {
                grid-template-columns: 1fr;
            }
            .page-content {
                padding: 18px 16px 36px 28px;
            }
        }
    </style>
</head>
<body>
@php
    $activeCount = (int) ($statusCounts['ACTIVE'] ?? 0);
    $tempCount = (int) ($statusCounts['TEMPORARILY_UNAVAILABLE'] ?? 0);
    $inactiveCount = (int) ($statusCounts['INACTIVE'] ?? 0);
    $pendingCount = $pendingActivities->count();

    $actionLabels = [
        'CREATED' => 'Spot Ditambahkan',
        'UPDATED' => 'Spot Diperbarui',
        'DEACTIVATED' => 'Spot Dinonaktifkan',
        'REACTIVATED' => 'Spot Diaktifkan Kembali',
        'MARKED_UNAVAILABLE' => 'Spot Ditutup Sementara',
        'QR_REGENERATED' => 'Token QR Diperbarui',
        'SPOT_CREATED' => 'Spot Ditambahkan',
        'SPOT_UPDATED' => 'Spot Diperbarui',
        'SPOT_STATUS_CHANGED' => 'Status Spot Diubah',
        'SPOT_LOCATION_CHANGED' => 'Lokasi Spot Diubah',
        'SPOT_LOCATION_AND_STATUS_CHANGED' => 'Lokasi & Status Diubah',
        'SPOT_QR_REGENERATED' => 'Token QR Diperbarui',
        'FEEDING_REVIEW_APPROVED' => 'Review Disetujui',
        'FEEDING_REVIEW_REJECTED' => 'Review Ditolak',
    ];
@endphp

    <!-- DARK NAVY COLLAPSIBLE SIDEBAR (ICON-ONLY WHEN COLLAPSED) -->
    <aside class="sidebar" id="appSidebar">
        <div class="sidebar-brand" data-tooltip="MEOWTOPIA — Feeding Spot">
            <img src="/api/v1/feeding/assets/logo.jpg" alt="Meowtopia" class="sidebar-logo">
            <div class="sidebar-brand-text">
                <div class="sidebar-brand-title">MEOWTOPIA</div>
                <div class="sidebar-brand-sub">Feeding Spot</div>
            </div>
        </div>

        <nav class="sidebar-nav">
            @if($canManageSpots)
            <button type="button" class="nav-item {{ $activeTab === 'spots' ? 'active' : '' }}" id="navBtn-spots" onclick="switchTab('spots')" data-tooltip="Lokasi Feeding Spot ({{ $allSpotsCount }})" aria-label="Lokasi Feeding Spot">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <span class="nav-item-text">Lokasi Feeding Spot</span>
                </span>
                <span class="nav-count">{{ $allSpotsCount }}</span>
            </button>
            @endif

            @if($canReview)
            <button type="button" class="nav-item {{ $activeTab === 'reviews' ? 'active' : '' }}" id="navBtn-reviews" onclick="switchTab('reviews')" data-tooltip="Antrean Review ({{ $pendingCount }})" aria-label="Antrean Review">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <rect width="8" height="4" x="8" y="2" rx="1" ry="1"/>
                        <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>
                        <path d="m9 14 2 2 4-4"/>
                    </svg>
                    <span class="nav-item-text">Antrean Review</span>
                </span>
                <span class="nav-count">{{ $pendingCount }}</span>
            </button>
            @endif

            <button type="button" class="nav-item {{ $activeTab === 'audit' ? 'active' : '' }}" id="navBtn-audit" onclick="switchTab('audit')" data-tooltip="Riwayat Spot & Review" aria-label="Riwayat Spot dan Review">
                <span class="nav-item-label">
                    <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/>
                        <path d="M3 3v5h5"/>
                        <path d="M12 7v5l4 2"/>
                    </svg>
                    <span class="nav-item-text">Riwayat Spot &amp; Review</span>
                </span>
                <span class="nav-count">{{ $spotHistoryCount + $reviewHistoryCount }}</span>
            </button>
        </nav>
    </aside>

    <!-- SIDEBAR EDGE TOGGLE -->
    <button type="button" class="sidebar-edge-toggle" id="sidebarToggleBtn" onclick="toggleSidebar()" title="Toggle Sidebar" aria-label="Toggle Sidebar">&lt;</button>

    <!-- MAIN CONTENT (NO GREEN CIRCLE DOT OR DECORATIVE TOPBAR BADGES) -->
    <div class="main-wrapper">
        <header class="topbar">
            <h1 class="topbar-title" id="topbarActiveTitle">
                @if($activeTab === 'reviews')
                    Antrean Review
                @elseif($activeTab === 'audit')
                    Riwayat Spot &amp; Review
                @else
                    Lokasi Feeding Spot
                @endif
            </h1>
            <form method="POST" action="/admin/feeding/logout">
                @csrf
                <button type="submit" class="btn btn-neutral btn-sm">Keluar ({{ auth()->user()->name }})</button>
            </form>
        </header>

        <main class="page-content">
            @if(request()->filled('notice'))
                <div class="alert alert-success" id="noticeBanner">
                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <span>{{ request()->query('notice') }}</span>
                        @if(request()->filled('regenerated_spot'))
                            <a href="/admin/feeding/spots/{{ request()->query('regenerated_spot') }}/qr-sheet" target="_blank" class="btn btn-neutral btn-sm">
                                Lihat &amp; Cetak QR Baru
                            </a>
                            <a href="/admin/feeding/spots/{{ request()->query('regenerated_spot') }}/qr-download?format=png" class="btn btn-primary btn-sm">
                                Unduh QR Baru (PNG)
                            </a>
                        @endif
                    </div>
                    <button type="button" class="alert-close" onclick="this.closest('.alert').remove()" title="Tutup" aria-label="Tutup">&times;</button>
                </div>
            @endif

            @if(request()->filled('error') || (isset($errors) && $errors->any()))
                <div class="alert alert-danger" id="errorBanner">
                    <span>
                        {{ request()->query('error') }}
                        @if(isset($errors) && $errors->any())
                            {{ implode(' ', $errors->all()) }}
                        @endif
                    </span>
                    <button type="button" class="alert-close" onclick="this.closest('.alert').remove()">&times;</button>
                </div>
            @endif

            <!-- ================= TAB 1: LOKASI FEEDING SPOT ================= -->
            @if($canManageSpots)
            <section id="tabSection-spots" class="tab-section {{ $activeTab === 'spots' ? 'active' : '' }}">
                <div class="stats-grid">
                    <a href="/admin/feeding?tab=spots" class="stat-item {{ empty($filters['status']) ? 'active' : '' }}">
                        <span class="stat-label">Total Spot</span>
                        <span class="stat-value">{{ $allSpotsCount }}</span>
                    </a>
                    <a href="/admin/feeding?tab=spots&status=ACTIVE" class="stat-item {{ ($filters['status'] ?? '') === 'ACTIVE' ? 'active' : '' }}">
                        <span class="stat-label">Aktif</span>
                        <span class="stat-value">{{ $activeCount }}</span>
                    </a>
                    <a href="/admin/feeding?tab=spots&status=TEMPORARILY_UNAVAILABLE" class="stat-item {{ ($filters['status'] ?? '') === 'TEMPORARILY_UNAVAILABLE' ? 'active' : '' }}">
                        <span class="stat-label">Sementara Tutup</span>
                        <span class="stat-value">{{ $tempCount }}</span>
                    </a>
                    <a href="/admin/feeding?tab=spots&status=INACTIVE" class="stat-item {{ ($filters['status'] ?? '') === 'INACTIVE' ? 'active' : '' }}">
                        <span class="stat-label">Nonaktif</span>
                        <span class="stat-value">{{ $inactiveCount }}</span>
                    </a>
                </div>

                <div class="panel">
                    <div class="toolbar">
                        <form method="GET" action="/admin/feeding" class="toolbar-filters">
                            <input type="hidden" name="tab" value="spots">
                            <input
                                type="text"
                                name="search"
                                value="{{ $filters['search'] ?? '' }}"
                                placeholder="Cari nama atau kode spot..."
                                class="input-control input-search"
                            >
                            <select name="status" class="select-control">
                                <option value="">Semua Status</option>
                                <option value="ACTIVE" {{ ($filters['status'] ?? '') === 'ACTIVE' ? 'selected' : '' }}>Aktif</option>
                                <option value="TEMPORARILY_UNAVAILABLE" {{ ($filters['status'] ?? '') === 'TEMPORARILY_UNAVAILABLE' ? 'selected' : '' }}>Sementara Tutup</option>
                                <option value="INACTIVE" {{ ($filters['status'] ?? '') === 'INACTIVE' ? 'selected' : '' }}>Nonaktif</option>
                            </select>
                            <button type="submit" class="btn btn-neutral">Cari</button>
                            @if(!empty($filters['search']) || !empty($filters['status']))
                                <a href="/admin/feeding?tab=spots" class="btn btn-neutral">Reset</a>
                            @endif
                        </form>

                        <div class="row-actions">
                            <a href="/admin/feeding/qr-sheet" target="_blank" class="btn btn-neutral">
                                Cetak Semua QR
                            </a>
                            <button type="button" class="btn btn-primary" onclick="openCreateSpotModal()">
                                + Tambah Feeding Spot
                            </button>
                        </div>
                    </div>

                    <div class="table-scroll">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Kode</th>
                                    <th>Nama Lokasi</th>
                                    <th>Area Kampus</th>
                                    <th>Informasi Kucing</th>
                                    <th>Status</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($spots as $spot)
                                    @php
                                        $selectedCatId = !empty($spot['cats'][0]['id']) ? $spot['cats'][0]['id'] : '';
                                    @endphp
                                    <tr>
                                        <td>
                                            <span class="spot-code">{{ $spot['code'] }}</span>
                                        </td>
                                        <td>
                                            <div style="display: flex; align-items: center; gap: 10px;">
                                                @if(!empty($spot['image_url']))
                                                    <img src="{{ $spot['image_url'] }}" alt="Foto {{ $spot['name'] }}" style="width: 40px; height: 40px; border-radius: 6px; object-fit: cover; border: 1px solid var(--border); flex-shrink: 0;">
                                                @endif
                                                <div>
                                                    <div style="font-weight: 600; color: var(--text-primary);">{{ $spot['name'] }}</div>
                                                    @if(!empty($spot['description']))
                                                        <div style="font-size: 12px; color: var(--text-muted); margin-top: 1px;">{{ $spot['description'] }}</div>
                                                    @endif
                                                </div>
                                            </div>
                                        </td>
                                        <td style="color: var(--text-secondary);">
                                            {{ $spot['location_name'] ?? $spot['territory']['name'] ?? 'Area Kampus Telkom University' }}
                                        </td>
                                        <td>
                                            <!-- STANDARD DROPDOWN FOR CAT INFORMATION (POINT 4) -->
                                            <form method="POST" action="/admin/feeding/spots/{{ $spot['id'] }}/cats" style="margin: 0;">
                                                @csrf
                                                <select
                                                    name="cat_id"
                                                    class="cat-dropdown"
                                                    aria-label="Pilih Kucing untuk {{ $spot['code'] }}"
                                                    data-spot-id="{{ $spot['id'] }}"
                                                    onchange="handleTableCatChange(this)"
                                                >
                                                    <option value="">Pilih kucing...</option>
                                                    @foreach($availableCats as $cat)
                                                        <option value="{{ $cat->id }}" {{ $selectedCatId === $cat->id ? 'selected' : '' }}>
                                                            {{ $cat->name }} ({{ $cat->unique_code }})
                                                        </option>
                                                    @endforeach
                                                </select>
                                            </form>
                                        </td>
                                        <td>
                                            @if($spot['status'] === 'ACTIVE')
                                                <span class="status-label status-active">Aktif</span>
                                            @elseif($spot['status'] === 'TEMPORARILY_UNAVAILABLE')
                                                <span class="status-label status-temp">Sementara Tutup</span>
                                            @else
                                                <span class="status-label status-inactive">Nonaktif</span>
                                            @endif
                                        </td>
                                        <td>
                                            <div class="row-actions">
                                                <button type="button" class="btn btn-neutral btn-sm" onclick='openDetailSpotModal(@json($spot))'>Detail</button>
                                                <button type="button" class="btn btn-edit btn-sm" onclick='openEditSpotModal(@json($spot))'>Edit</button>
                                                <a href="/admin/feeding/spots/{{ $spot['id'] }}/qr-sheet" target="_blank" class="btn btn-neutral btn-sm">Cetak QR</a>
                                                <form method="POST" action="/admin/feeding/spots/{{ $spot['id'] }}/qr" onsubmit="return confirm('Apakah Anda yakin ingin mengganti QR Code spot ini? QR Code sebelumnya akan dinonaktifkan dan tidak dapat digunakan lagi.');" style="display:inline;">
                                                    @csrf
                                                    <button type="submit" class="btn btn-neutral btn-sm">Ganti QR</button>
                                                </form>
                                                @if($spot['status'] !== 'INACTIVE')
                                                    <form method="POST" action="/admin/feeding/spots/{{ $spot['id'] }}/update" onsubmit="return confirm('Nonaktifkan spot {{ $spot['code'] }}?');" style="display:inline;">
                                                        @csrf
                                                        <input type="hidden" name="status" value="INACTIVE">
                                                        <input type="hidden" name="status_reason" value="Dinonaktifkan oleh Admin">
                                                        <button type="submit" class="btn btn-danger btn-sm">Nonaktifkan</button>
                                                    </form>
                                                @else
                                                    <form method="POST" action="/admin/feeding/spots/{{ $spot['id'] }}/update" style="display:inline;">
                                                        @csrf
                                                        <input type="hidden" name="status" value="ACTIVE">
                                                        <button type="submit" class="btn btn-success btn-sm">Aktifkan</button>
                                                    </form>
                                                @endif
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" style="text-align: center; padding: 36px 20px; color: var(--text-muted);">
                                            Belum ada lokasi feeding spot yang sesuai.
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    <div class="table-footer">
                        <div>
                            Menampilkan {{ $spots->count() }} dari {{ $spotsPaginator->total() }} spot
                        </div>
                        <div class="row-actions">
                            @if($spotsPaginator->onFirstPage())
                                <button class="btn btn-neutral btn-sm" disabled>Sebelumnya</button>
                            @else
                                <a href="{{ $spotsPaginator->previousPageUrl() }}" class="btn btn-neutral btn-sm">Sebelumnya</a>
                            @endif

                            @if($spotsPaginator->hasMorePages())
                                <a href="{{ $spotsPaginator->nextPageUrl() }}" class="btn btn-neutral btn-sm">Berikutnya</a>
                            @else
                                <button class="btn btn-neutral btn-sm" disabled>Berikutnya</button>
                            @endif
                        </div>
                    </div>
                </div>
            </section>
            @endif

            <!-- ================= TAB 2: ANTREAN REVIEW ================= -->
            @if($canReview)
            <section id="tabSection-reviews" class="tab-section {{ $activeTab === 'reviews' ? 'active' : '' }}">
                <div class="panel">
                    <div class="table-scroll">
                        <table class="data-table">
                            <thead>
                                <tr>
                                    <th>Referensi</th>
                                    <th>Relawan</th>
                                    <th>Lokasi Spot</th>
                                    <th>Jenis &amp; Takaran Pakan</th>
                                    <th>Waktu Pengajuan</th>
                                    <th>Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($pendingActivities as $item)
                                    <tr>
                                        <td>
                                            <span class="spot-code">{{ $item->feeding_record_ref }}</span>
                                        </td>
                                        <td>
                                            <div style="font-weight: 600;">{{ $item->user?->name ?? 'Relawan' }}</div>
                                        </td>
                                        <td>
                                            {{ $item->spot?->name ?? '-' }}
                                        </td>
                                        <td>
                                            {{ strtoupper((string) $item->food_type) }} — {{ $item->food_amount }}
                                        </td>
                                        <td style="color: var(--text-secondary);">
                                            {{ $item->finalized_at?->format('d M Y, H:i') ?? '-' }}
                                        </td>
                                        <td>
                                            <a href="/admin/feeding/reviews/{{ $item->id }}" class="btn btn-primary btn-sm">
                                                Periksa Detail
                                            </a>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" style="text-align: center; padding: 40px 20px; color: var(--text-muted);">
                                            Tidak ada antrean review yang menunggu pemeriksaan.
                                        </td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>
            @endif

            <!-- ================= TAB 3: RIWAYAT SPOT & REVIEW ================= -->
            <section id="tabSection-audit" class="tab-section {{ $activeTab === 'audit' ? 'active' : '' }}">
                @if($canManageSpots)
                <div class="panel">
                    <div class="toolbar"><strong style="font-size: 14px;">Riwayat Lokasi Spot</strong></div>
                    <div class="table-scroll">
                        <table class="data-table">
                            <thead><tr><th>Waktu</th><th>Aktor</th><th>Lokasi</th><th>Perubahan</th><th>Alasan</th></tr></thead>
                            <tbody>
                                @forelse($spotHistory as $history)
                                    @php
                                        $old = $history->changes['old'] ?? [];
                                        $new = $history->changes['new'] ?? [];
                                        $changed = $history->changes['changed_fields'] ?? [];
                                    @endphp
                                    <tr>
                                        <td style="white-space: nowrap;">{{ $history->created_at?->format('d M Y, H:i') }}</td>
                                        <td>{{ $history->actor?->name ?? 'Sistem / Admin' }}</td>
                                        <td><strong>{{ $history->spot?->code ?? ($new['code'] ?? $old['code'] ?? '-') }}</strong><br><span style="color: var(--text-secondary);">{{ $history->spot?->name ?? ($new['name'] ?? $old['name'] ?? 'Spot dihapus') }}</span></td>
                                        <td>
                                            <span class="status-label status-inactive">{{ $actionLabels[$history->action] ?? $history->action }}</span>
                                            @foreach($changed as $field)
                                                @php $fieldLabels = ['name' => 'Nama', 'status' => 'Status', 'latitude' => 'Latitude', 'longitude' => 'Longitude', 'description' => 'Deskripsi', 'status_reason' => 'Alasan']; @endphp
                                                @if(isset($fieldLabels[$field]))<br><strong>{{ $fieldLabels[$field] }}:</strong> {{ $old[$field] ?? '—' }} &rarr; {{ $new[$field] ?? '—' }}@endif
                                            @endforeach
                                        </td>
                                        <td>{{ $history->reason ?: '-' }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="5" style="text-align: center; padding: 36px; color: var(--text-muted);">Belum ada riwayat perubahan lokasi.</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @endif

                @if($canReview)
                <div class="panel" style="margin-top: 20px;">
                    <div class="toolbar"><strong style="font-size: 14px;">Riwayat Keputusan Review</strong></div>
                    <div class="table-scroll">
                        <table class="data-table">
                            <thead><tr><th>Waktu</th><th>Referensi</th><th>Relawan &amp; Spot</th><th>Keputusan</th><th>Reviewer</th><th>Alasan</th></tr></thead>
                            <tbody>
                                @forelse($reviewHistory as $review)
                                    <tr>
                                        <td style="white-space: nowrap;">{{ $review->created_at?->format('d M Y, H:i') }}</td>
                                        <td><span class="spot-code">{{ $review->activity?->feeding_record_ref ?? '-' }}</span></td>
                                        <td><strong>{{ $review->activity?->user?->name ?? 'Relawan' }}</strong><br><span style="color: var(--text-secondary);">{{ $review->activity?->spot?->name ?? '-' }}</span></td>
                                        <td>@if($review->decision === 'REJECTED')<span class="status-label status-rejected">Ditolak</span>@else<span class="status-label status-active">Disetujui</span>@endif</td>
                                        <td>{{ $review->reviewer?->name ?? '-' }}</td>
                                        <td>{{ $review->reason ?: '-' }}</td>
                                    </tr>
                                @empty
                                    <tr><td colspan="6" style="text-align: center; padding: 36px; color: var(--text-muted);">Belum ada keputusan review.</td></tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>
                </div>
                @endif
            </section>
        </main>
    </div>

    <!-- ================= MODAL 1: TAMBAH / EDIT FEEDING SPOT ================= -->
    <div class="modal-backdrop" id="spotModal">
        <div class="modal-box">
            <div class="modal-header">
                <h3 id="spotModalTitle">Tambah Feeding Spot</h3>
                <button type="button" class="btn-icon-close" onclick="closeSpotModal()" title="Tutup" aria-label="Tutup">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M18 6 6 18"/>
                        <path d="m6 6 12 12"/>
                    </svg>
                </button>
            </div>

            <form method="POST" action="/admin/feeding/spots" id="spotForm" enctype="multipart/form-data" class="modal-form-flex" onsubmit="return handleSpotFormSubmit(event);">
                @csrf
                <input type="hidden" id="inputLat" name="latitude" value="-6.9731000" required>
                <input type="hidden" id="inputLng" name="longitude" value="107.6300000" required>
                <input type="hidden" id="inputTerritoryCode" name="territory_code" value="GKU">
                <input type="hidden" id="inputRemovePhoto" name="remove_photo" value="0">

                <div class="modal-body">
                    <div class="alert alert-danger" id="modalValidationBanner" style="display: none; margin-bottom: 14px;">
                        <span id="modalValidationText">Mohon lengkapi kolom wajib dan pilih titik di dalam area kampus.</span>
                    </div>

                    <div class="form-grid">
                        <div class="form-group">
                            <label class="form-label" for="inputCode">Kode Spot (Otomatis)</label>
                            <input type="text" id="inputCode" name="code" class="input-control" placeholder="Otomatis dibuat sistem (mis. SPOT-GKU-01)" readonly style="background: var(--surface-subtle); cursor: not-allowed; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-weight: 600;" maxlength="64">
                            <span style="font-size: 11px; color: var(--text-muted);">Kode unik dihasilkan otomatis oleh sistem saat spot dibuat dan tidak berubah saat diedit.</span>
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="inputStatus">Status *</label>
                            <select id="inputStatus" name="status" class="select-control" onchange="handleStatusReasonRequirement()">
                                <option value="ACTIVE">Aktif</option>
                                <option value="TEMPORARILY_UNAVAILABLE">Sementara Tutup</option>
                                <option value="INACTIVE">Nonaktif</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="inputName">Nama Lokasi Spot *</label>
                            <input type="text" id="inputName" name="name" class="input-control" placeholder="Otomatis terisi saat klik peta atau ketik manual" required maxlength="255" oninput="markNameAsManual()">
                        </div>

                        <div class="form-group">
                            <label class="form-label" for="inputCatId">Informasi Kucing</label>
                            <select id="inputCatId" name="cat_id" class="select-control">
                                <option value="">Pilih kucing...</option>
                                @foreach($availableCats as $cat)
                                    <option value="{{ $cat->id }}">{{ $cat->name }} ({{ $cat->unique_code }})</option>
                                @endforeach
                            </select>
                        </div>

                        <div class="form-group full" id="statusReasonGroup" style="display: none;">
                            <label class="form-label" for="inputStatusReason">Alasan Status *</label>
                            <input type="text" id="inputStatusReason" name="status_reason" class="input-control" placeholder="Tuliskan alasan penutupan sementara atau penonaktifan" maxlength="500">
                        </div>

                        <div class="form-group full">
                            <label class="form-label" for="inputDescription">Deskripsi Singkat</label>
                            <input type="text" id="inputDescription" name="description" class="input-control" placeholder="Patokan posisi tempat makan (opsional)" maxlength="1000">
                        </div>

                        <!-- SPOT PHOTO UPLOAD WITH PREVIEW, REPLACE, REMOVE & VALIDATION (MEOW-21) -->
                        <div class="form-group full">
                            <label class="form-label" for="inputSpotPhoto">Foto Dokumentasi Lokasi Spot (Opsional)</label>
                            <input
                                type="file"
                                id="inputSpotPhoto"
                                name="photo"
                                accept="image/jpeg,image/png,image/webp"
                                style="display: none;"
                                onchange="handleSpotPhotoChange(this)"
                            >
                            <div id="spotPhotoUploadCard" style="border: 1px dashed var(--border-strong); border-radius: 8px; padding: 12px 14px; background: var(--surface-subtle);">
                                <div id="spotPhotoEmptyState" style="display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;">
                                    <div>
                                        <div style="font-size: 13px; font-weight: 600; color: var(--text-primary);">Unggah foto lokasi feeding spot</div>
                                        <div style="font-size: 11.5px; color: var(--text-muted);">Format JPG, PNG, atau WEBP &bull; Maksimal 5 MB</div>
                                    </div>
                                    <button type="button" class="btn btn-neutral btn-sm" id="btnChooseSpotPhoto" onclick="triggerSpotPhotoPicker()">
                                        Pilih Foto dari Perangkat
                                    </button>
                                </div>

                                <div id="spotPhotoPreviewBox" style="display: none; align-items: center; justify-content: space-between; gap: 14px; flex-wrap: wrap;">
                                    <div style="display: flex; align-items: center; gap: 12px;">
                                        <img id="spotPhotoPreviewImg" src="" alt="Preview Foto Spot" style="width: 76px; height: 76px; border-radius: 8px; object-fit: cover; border: 1px solid var(--border);">
                                        <div>
                                            <div id="spotPhotoFileName" style="font-size: 13px; font-weight: 600; color: var(--text-primary);">Foto terpilih</div>
                                            <div id="spotPhotoFileSize" style="font-size: 11.5px; color: var(--text-muted);">Siap disimpan</div>
                                        </div>
                                    </div>
                                    <div class="row-actions">
                                        <button type="button" class="btn btn-edit btn-sm" id="btnReplaceSpotPhoto" onclick="triggerSpotPhotoPicker()">
                                            Ganti Foto
                                        </button>
                                        <button type="button" class="btn btn-danger btn-sm" id="btnRemoveSpotPhoto" onclick="clearSpotPhotoSelection()">
                                            Hapus Foto
                                        </button>
                                    </div>
                                </div>

                                <div id="spotPhotoErrorText" style="display: none; color: var(--danger); font-size: 12px; font-weight: 500; margin-top: 8px;"></div>
                            </div>
                        </div>

                        <!-- MAP PICKER WITH AUTOMATIC AREA IDENTIFICATION (POINT 5) -->
                        <div class="form-group full">
                            <div style="display: flex; align-items: center; justify-content: space-between;">
                                <label class="form-label">Pilih Titik Lokasi pada Peta *</label>
                                <button type="button" class="btn-icon-only" id="btnCenterMap" onclick="resetMapToCampusCenter()" title="Pusatkan Peta" aria-label="Pusatkan Peta">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                                        <line x1="2" x2="5" y1="12" y2="12"/>
                                        <line x1="19" x2="22" y1="12" y2="12"/>
                                        <line x1="12" x2="12" y1="2" y2="5"/>
                                        <line x1="12" x2="12" y1="19" y2="22"/>
                                        <circle cx="12" cy="12" r="7"/>
                                        <circle cx="12" cy="12" r="2.5"/>
                                    </svg>
                                </button>
                            </div>
                            <div id="spotPickerMap"></div>
                            <div class="map-info-bar">
                                <div>
                                    <span id="polygonCheckLabel" style="color: var(--text-secondary);">Klik pada area kampus untuk memilih lokasi.</span>
                                </div>
                                <div class="area-identified-tag" id="mapAreaBadge">Area Gedung Kuliah Umum (GKU)</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="modal-footer">
                    <button type="button" class="btn btn-neutral" onclick="closeSpotModal()">Batal</button>
                    <button type="submit" class="btn btn-primary" id="spotSubmitBtn">
                        <span id="spotSubmitBtnText">Tambah Feeding Spot</span>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- ================= MODAL 2: DETAIL SPOT ================= -->
    <div class="modal-backdrop" id="detailModal">
        <div class="modal-box modal-sm">
            <div class="modal-header">
                <h3 id="detailModalTitle">Detail Spot</h3>
                <button type="button" class="btn-icon-close" onclick="closeDetailSpotModal()" title="Tutup" aria-label="Tutup">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                        <path d="M18 6 6 18"/>
                        <path d="m6 6 12 12"/>
                    </svg>
                </button>
            </div>
            <div class="modal-body">
                <div id="detailSpotPhotoContainer" style="display: none; margin-bottom: 14px;">
                    <img id="detailSpotPhotoImg" src="" alt="Foto Dokumentasi Spot" style="width: 100%; max-height: 210px; object-fit: cover; border-radius: 8px; border: 1px solid var(--border);">
                </div>
                <dl class="detail-dl" id="detailSpotList"></dl>

                <div style="margin-top: 18px; padding-top: 14px; border-top: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;">
                    <span style="font-size: 13px; color: var(--text-secondary); font-weight: 600;">Kode QR Spot</span>
                    <div class="row-actions">
                        <a href="#" id="detailDownloadQrBtn" class="btn btn-neutral btn-sm">Unduh QR (PNG)</a>
                        <a href="#" id="detailPrintQrBtn" target="_blank" class="btn btn-neutral btn-sm">Cetak QR</a>
                        <form method="POST" action="#" id="detailRegenQrForm" onsubmit="return confirm('Apakah Anda yakin ingin mengganti QR Code spot ini? QR Code sebelumnya akan dinonaktifkan dan tidak dapat digunakan lagi.');" style="display:inline;">
                            @csrf
                            <button type="submit" class="btn btn-edit btn-sm">Ganti QR</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" crossorigin=""></script>
    <script>
        const TELKOM_POLYGON = @json($telkomBoundary);
        const CAMPUS_CENTER = [-6.9731000, 107.6300000];
        const EXISTING_SPOT_CODES = @json($existingSpotCodes ?? []);

        function computeNextSequentialSpotCode(prefix) {
            const cleanPrefix = String(prefix || 'SPOT-TELU').trim().toUpperCase().replace(/-$/, '');
            const regex = new RegExp('^' + cleanPrefix.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '-(\\d+)$', 'i');
            let maxSeq = 0;
            const existingSet = new Set(EXISTING_SPOT_CODES.map((c) => String(c).toUpperCase()));

            for (const code of existingSet) {
                const match = code.match(regex);
                if (match) {
                    const num = parseInt(match[1], 10);
                    if (num > maxSeq) maxSeq = num;
                }
            }

            let nextSeq = maxSeq + 1;
            while (true) {
                const candidate = `${cleanPrefix}-${String(nextSeq).padStart(2, '0')}`;
                if (!existingSet.has(candidate)) {
                    return candidate;
                }
                nextSeq++;
            }
        }

        // Referensi Resmi 38 Lokasi Denah Kampus Telkom University (Area Gedung TULT, Area Asrama Putri, dll.)
        const RAW_CAMPUS_LOCATIONS = @json($campusLocations ?? []);
        const TELKOM_CAMPUS_AREAS = RAW_CAMPUS_LOCATIONS.map((loc) => ({
            number: loc.number,
            name: loc.name,
            shortName: loc.short_name || loc.name,
            codePrefix: loc.code_prefix,
            territoryCode: loc.territory_code,
            lat: Number(loc.lat),
            lng: Number(loc.lng)
        }));

        function identifyCampusArea(lat, lng, spotCode = '') {
            if (spotCode) {
                const upperCode = String(spotCode).trim().toUpperCase();
                for (const area of TELKOM_CAMPUS_AREAS) {
                    const prefix = String(area.codePrefix).toUpperCase();
                    const altPrefix = prefix.replace(/^SPOT-/, 'FS-');
                    if (upperCode.startsWith(prefix + '-') || upperCode.startsWith(altPrefix + '-')) {
                        return area;
                    }
                }
            }

            let bestMatch = null;
            let minDistance = Infinity;

            for (const area of TELKOM_CAMPUS_AREAS) {
                const dLat = lat - area.lat;
                const dLng = lng - area.lng;
                const dist = Math.sqrt(dLat * dLat + dLng * dLng);
                if (dist < minDistance) {
                    minDistance = dist;
                    bestMatch = area;
                }
            }

            if (bestMatch) {
                return bestMatch;
            }

            return {
                number: 0,
                name: 'Area Kampus Telkom University',
                shortName: 'Kampus Telkom University',
                codePrefix: 'SPOT-TELU',
                territoryCode: 'GKU'
            };
        }

        // ================= SIDEBAR TOGGLE =================
        function syncSidebarToggleSymbol() {
            const btn = document.getElementById('sidebarToggleBtn');
            const sidebar = document.getElementById('appSidebar');
            if (!btn || !sidebar) return;

            if (window.innerWidth <= 1024) {
                const isOpen = sidebar.classList.contains('mobile-open');
                btn.innerHTML = isOpen ? '&lt;' : '&gt;';
                btn.title = isOpen ? 'Tutup Sidebar' : 'Buka Sidebar';
            } else {
                const isCollapsed = document.body.classList.contains('sidebar-collapsed');
                btn.innerHTML = isCollapsed ? '&gt;' : '&lt;';
                btn.title = isCollapsed ? 'Perluas Sidebar' : 'Kecilkan Sidebar';
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
            if (pickerMap) {
                setTimeout(() => pickerMap.invalidateSize(), 280);
            }
        }

        (function restoreSidebarState() {
            if (window.innerWidth > 1024 && localStorage.getItem('meowtopia_sidebar_collapsed') === '1') {
                document.body.classList.add('sidebar-collapsed');
            }
            syncSidebarToggleSymbol();
            window.addEventListener('resize', syncSidebarToggleSymbol);
        })();

        // ================= TAB NAVIGATION =================
        const TAB_TITLES = {
            spots: 'Lokasi Feeding Spot',
            reviews: 'Antrean Review',
            audit: 'Riwayat Spot & Review'
        };

        function switchTab(tabName) {
            ['spots', 'reviews', 'audit'].forEach((t) => {
                const sec = document.getElementById('tabSection-' + t);
                const btn = document.getElementById('navBtn-' + t);
                if (sec) sec.classList.toggle('active', t === tabName);
                if (btn) btn.classList.toggle('active', t === tabName);
            });
            const titleEl = document.getElementById('topbarActiveTitle');
            if (titleEl && TAB_TITLES[tabName]) {
                titleEl.textContent = TAB_TITLES[tabName];
            }
            const url = new URL(window.location.href);
            url.searchParams.set('tab', tabName);
            window.history.replaceState({}, '', url);
        }

        // ================= CAT DROPDOWN HANDLER (POINT 4) =================
        function handleTableCatChange(selectEl) {
            const form = selectEl.closest('form');
            if (!form) return;

            fetch(form.action, {
                method: 'POST',
                headers: {
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: new FormData(form)
            }).catch(() => {
                form.submit();
            });
        }

        // ================= RAY-CASTING POLYGON CHECK =================
        function isPointInsidePolygon(lat, lng, polygon) {
            let inside = false;
            const n = polygon.length;
            for (let i = 0, j = n - 1; i < n; j = i++) {
                const yi = polygon[i][0], xi = polygon[i][1];
                const yj = polygon[j][0], xj = polygon[j][1];
                const intersect = ((yi > lat) !== (yj > lat))
                    && (lng < (xj - xi) * (lat - yi) / ((yj - yi) || 1e-12) + xi);
                if (intersect) inside = !inside;
            }
            return inside;
        }

        // ================= LEAFLET PICKER MAP & AUTO AREA IDENTIFICATION =================
        let pickerMap = null;
        let pickerMarker = null;
        let isCreateMode = true;
        let isNameAutoSuggested = true;

        function markNameAsManual() {
            const val = document.getElementById('inputName').value.trim();
            isNameAutoSuggested = (val === '');
        }

        function ensurePickerMapInitialized() {
            if (pickerMap) {
                setTimeout(() => pickerMap.invalidateSize(), 60);
                return;
            }

            pickerMap = L.map('spotPickerMap', {
                center: CAMPUS_CENTER,
                zoom: 16
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap'
            }).addTo(pickerMap);

            const outerWorld = [
                [-6.940, 107.595],
                [-6.940, 107.665],
                [-7.010, 107.665],
                [-7.010, 107.595]
            ];

            L.polygon([outerWorld, TELKOM_POLYGON], {
                color: 'transparent',
                fillColor: '#0F172A',
                fillOpacity: 0.25,
                interactive: false
            }).addTo(pickerMap);

            L.polygon(TELKOM_POLYGON, {
                color: '#1B365D',
                weight: 2.2,
                fillColor: '#EA580C',
                fillOpacity: 0.06,
                interactive: false
            }).addTo(pickerMap);

            // Tampilkan titik referensi 38 lokasi sesuai Denah Telkom University
            TELKOM_CAMPUS_AREAS.forEach((loc) => {
                const pin = L.circleMarker([loc.lat, loc.lng], {
                    radius: 6,
                    color: '#1B365D',
                    weight: 1.5,
                    fillColor: '#EA580C',
                    fillOpacity: 0.85
                }).addTo(pickerMap);
                pin.bindTooltip(`${loc.number}. ${loc.name}`, { direction: 'top', offset: [0, -6] });
                pin.on('click', function () {
                    selectMapCoordinates(loc.lat, loc.lng, true, true);
                });
            });

            pickerMarker = L.marker(CAMPUS_CENTER, { draggable: true }).addTo(pickerMap);

            pickerMarker.on('dragend', function (e) {
                const pos = e.target.getLatLng();
                selectMapCoordinates(pos.lat, pos.lng, false, true);
            });

            pickerMap.on('click', function (e) {
                selectMapCoordinates(e.latlng.lat, e.latlng.lng, true, true);
            });

            setTimeout(() => pickerMap.invalidateSize(), 100);
        }

        function selectMapCoordinates(lat, lng, moveMarker = true, autoFillFields = false) {
            const latFixed = Number(lat).toFixed(7);
            const lngFixed = Number(lng).toFixed(7);
            document.getElementById('inputLat').value = latFixed;
            document.getElementById('inputLng').value = lngFixed;

            if (moveMarker && pickerMarker) {
                pickerMarker.setLatLng([lat, lng]);
            }

            const inside = isPointInsidePolygon(Number(lat), Number(lng), TELKOM_POLYGON);
            const label = document.getElementById('polygonCheckLabel');
            const areaBadge = document.getElementById('mapAreaBadge');
            const submitBtn = document.getElementById('spotSubmitBtn');
            const banner = document.getElementById('modalValidationBanner');

            if (!inside) {
                label.textContent = 'Titik berada di luar batas wilayah Kampus Telkom University.';
                label.style.color = 'var(--danger)';
                areaBadge.textContent = 'Di Luar Area Kampus';
                areaBadge.style.color = 'var(--danger)';
                submitBtn.disabled = true;
                return;
            }

            const detectedArea = identifyCampusArea(Number(lat), Number(lng));
            label.textContent = `Koordinat dipilih (${latFixed}, ${lngFixed})`;
            label.style.color = 'var(--text-secondary)';
            areaBadge.textContent = detectedArea.number
                ? `${detectedArea.number}. ${detectedArea.name}`
                : detectedArea.name;
            areaBadge.style.color = 'var(--sidebar-navy)';
            document.getElementById('inputTerritoryCode').value = detectedArea.territoryCode;
            submitBtn.disabled = false;
            if (banner) banner.style.display = 'none';

            if (autoFillFields && isCreateMode) {
                const nameInput = document.getElementById('inputName');
                if (isNameAutoSuggested || nameInput.value.trim() === '') {
                    nameInput.value = 'Spot Pakan ' + detectedArea.shortName;
                    isNameAutoSuggested = true;
                }
                const codeInput = document.getElementById('inputCode');
                if (codeInput.value.trim() === '' || codeInput.dataset.autoGenerated === '1') {
                    codeInput.value = computeNextSequentialSpotCode(detectedArea.codePrefix);
                    codeInput.dataset.autoGenerated = '1';
                }
            }
        }

        function resetMapToCampusCenter() {
            selectMapCoordinates(CAMPUS_CENTER[0], CAMPUS_CENTER[1], true, isCreateMode);
            if (pickerMap) pickerMap.setView(CAMPUS_CENTER, 16);
        }

        function handleStatusReasonRequirement() {
            const status = document.getElementById('inputStatus').value;
            const reasonGroup = document.getElementById('statusReasonGroup');
            const reasonInput = document.getElementById('inputStatusReason');

            if (status === 'TEMPORARILY_UNAVAILABLE' || status === 'INACTIVE') {
                reasonGroup.style.display = 'flex';
                reasonInput.required = (status === 'TEMPORARILY_UNAVAILABLE');
            } else {
                reasonGroup.style.display = 'none';
                reasonInput.required = false;
            }
        }

        let currentSpotPhotoObjectUrl = null;
        let hasPhotoValidationError = false;

        function triggerSpotPhotoPicker() {
            const fileInput = document.getElementById('inputSpotPhoto');
            if (fileInput) fileInput.click();
        }

        function revokeSpotPhotoObjectUrl() {
            if (currentSpotPhotoObjectUrl) {
                URL.revokeObjectURL(currentSpotPhotoObjectUrl);
                currentSpotPhotoObjectUrl = null;
            }
        }

        function handleSpotPhotoChange(fileInput) {
            const errEl = document.getElementById('spotPhotoErrorText');
            const emptyState = document.getElementById('spotPhotoEmptyState');
            const previewBox = document.getElementById('spotPhotoPreviewBox');
            const previewImg = document.getElementById('spotPhotoPreviewImg');
            const nameEl = document.getElementById('spotPhotoFileName');
            const sizeEl = document.getElementById('spotPhotoFileSize');
            const removeFlag = document.getElementById('inputRemovePhoto');

            errEl.style.display = 'none';
            errEl.textContent = '';
            hasPhotoValidationError = false;

            if (!fileInput.files || fileInput.files.length === 0) {
                return;
            }

            const file = fileInput.files[0];
            const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
            const ext = (file.name.split('.').pop() || '').toLowerCase();
            const allowedExts = ['jpg', 'jpeg', 'png', 'webp'];

            if (!allowedTypes.includes(file.type) && !allowedExts.includes(ext)) {
                fileInput.value = '';
                hasPhotoValidationError = true;
                errEl.textContent = 'Format file tidak didukung. Pilih foto berformat JPG, PNG, atau WEBP.';
                errEl.style.display = 'block';
                return;
            }

            const maxBytes = 5 * 1024 * 1024;
            if (file.size > maxBytes) {
                fileInput.value = '';
                hasPhotoValidationError = true;
                errEl.textContent = 'Ukuran file melebihi batas maksimal 5 MB. Pilih foto dengan ukuran lebih kecil.';
                errEl.style.display = 'block';
                return;
            }

            revokeSpotPhotoObjectUrl();
            currentSpotPhotoObjectUrl = URL.createObjectURL(file);
            previewImg.src = currentSpotPhotoObjectUrl;
            nameEl.textContent = file.name;
            sizeEl.textContent = `${(file.size / 1024).toFixed(1)} KB • Siap diunggah`;
            if (removeFlag) removeFlag.value = '0';

            emptyState.style.display = 'none';
            previewBox.style.display = 'flex';
        }

        function clearSpotPhotoSelection() {
            const fileInput = document.getElementById('inputSpotPhoto');
            const emptyState = document.getElementById('spotPhotoEmptyState');
            const previewBox = document.getElementById('spotPhotoPreviewBox');
            const previewImg = document.getElementById('spotPhotoPreviewImg');
            const errEl = document.getElementById('spotPhotoErrorText');
            const removeFlag = document.getElementById('inputRemovePhoto');

            if (fileInput) fileInput.value = '';
            revokeSpotPhotoObjectUrl();
            previewImg.src = '';
            errEl.style.display = 'none';
            errEl.textContent = '';
            hasPhotoValidationError = false;

            if (removeFlag) {
                removeFlag.value = isCreateMode ? '0' : '1';
            }

            previewBox.style.display = 'none';
            emptyState.style.display = 'flex';
        }

        function handleSpotFormSubmit(e) {
            const code = document.getElementById('inputCode').value.trim();
            const name = document.getElementById('inputName').value.trim();
            const status = document.getElementById('inputStatus').value;
            const reason = document.getElementById('inputStatusReason').value.trim();
            const lat = parseFloat(document.getElementById('inputLat').value);
            const lng = parseFloat(document.getElementById('inputLng').value);
            const banner = document.getElementById('modalValidationBanner');
            const bannerText = document.getElementById('modalValidationText');
            const fileInput = document.getElementById('inputSpotPhoto');

            if (hasPhotoValidationError) {
                e.preventDefault();
                bannerText.textContent = 'Perbaiki pilihan foto spot sebelum menyimpan.';
                banner.style.display = 'flex';
                return false;
            }

            if (!name || isNaN(lat) || isNaN(lng)) {
                e.preventDefault();
                bannerText.textContent = 'Nama lokasi dan titik peta wajib diisi.';
                banner.style.display = 'flex';
                return false;
            }

            if (status === 'TEMPORARILY_UNAVAILABLE' && !reason) {
                e.preventDefault();
                bannerText.textContent = 'Alasan status wajib diisi ketika status Sementara Tutup.';
                banner.style.display = 'flex';
                document.getElementById('inputStatusReason').focus();
                return false;
            }

            if (!isPointInsidePolygon(lat, lng, TELKOM_POLYGON)) {
                e.preventDefault();
                bannerText.textContent = 'Titik lokasi berada di luar wilayah Kampus Telkom University.';
                banner.style.display = 'flex';
                return false;
            }

            banner.style.display = 'none';
            const submitBtn = document.getElementById('spotSubmitBtn');
            const submitText = document.getElementById('spotSubmitBtnText');
            submitBtn.disabled = true;
            const hasUploadingFile = fileInput && fileInput.files && fileInput.files.length > 0;
            submitText.textContent = hasUploadingFile ? 'Mengunggah Foto & Menyimpan...' : 'Menyimpan...';
            return true;
        }

        function openCreateSpotModal() {
            isCreateMode = true;
            isNameAutoSuggested = true;
            document.getElementById('spotModalTitle').textContent = 'Tambah Feeding Spot';
            document.getElementById('spotForm').action = '/admin/feeding/spots';
            document.getElementById('spotSubmitBtnText').textContent = 'Tambah Feeding Spot';
            document.getElementById('spotSubmitBtn').disabled = false;
            document.getElementById('modalValidationBanner').style.display = 'none';

            const codeInput = document.getElementById('inputCode');
            codeInput.value = '';
            codeInput.dataset.autoGenerated = '1';
            codeInput.oninput = function () { codeInput.dataset.autoGenerated = '0'; };

            document.getElementById('inputName').value = '';
            document.getElementById('inputDescription').value = '';
            document.getElementById('inputStatus').value = 'ACTIVE';
            document.getElementById('inputStatusReason').value = '';
            document.getElementById('inputCatId').value = '';
            clearSpotPhotoSelection();
            document.getElementById('inputRemovePhoto').value = '0';
            handleStatusReasonRequirement();

            document.getElementById('spotModal').classList.add('open');
            ensurePickerMapInitialized();
            resetMapToCampusCenter();
        }

        function openEditSpotModal(spot) {
            isCreateMode = false;
            isNameAutoSuggested = false;
            document.getElementById('spotModalTitle').textContent = `Edit Spot — ${spot.code}`;
            document.getElementById('spotForm').action = `/admin/feeding/spots/${spot.id}/update`;
            document.getElementById('spotSubmitBtnText').textContent = 'Simpan Perubahan';
            document.getElementById('spotSubmitBtn').disabled = false;
            document.getElementById('modalValidationBanner').style.display = 'none';

            const codeInput = document.getElementById('inputCode');
            codeInput.value = spot.code || '';
            codeInput.dataset.autoGenerated = '0';

            document.getElementById('inputName').value = spot.name || '';
            document.getElementById('inputDescription').value = spot.description || '';
            document.getElementById('inputStatus').value = spot.status || 'ACTIVE';
            document.getElementById('inputStatusReason').value = spot.status_reason || '';
            document.getElementById('inputCatId').value = (spot.cats && spot.cats[0]) ? spot.cats[0].id : '';
            clearSpotPhotoSelection();
            document.getElementById('inputRemovePhoto').value = '0';

            if (spot.image_url) {
                document.getElementById('spotPhotoPreviewImg').src = spot.image_url;
                document.getElementById('spotPhotoFileName').textContent = 'Foto dokumentasi spot tersimpan';
                document.getElementById('spotPhotoFileSize').textContent = 'Klik Ganti Foto untuk memperbarui atau Hapus Foto';
                document.getElementById('spotPhotoEmptyState').style.display = 'none';
                document.getElementById('spotPhotoPreviewBox').style.display = 'flex';
            }
            handleStatusReasonRequirement();

            document.getElementById('spotModal').classList.add('open');
            ensurePickerMapInitialized();

            const lat = parseFloat(spot.latitude) || CAMPUS_CENTER[0];
            const lng = parseFloat(spot.longitude) || CAMPUS_CENTER[1];
            selectMapCoordinates(lat, lng, true, false);
            if (pickerMap) {
                setTimeout(() => pickerMap.setView([lat, lng], 17), 80);
            }
        }

        function closeSpotModal() {
            document.getElementById('spotModal').classList.remove('open');
        }

        function openDetailSpotModal(spot) {
            document.getElementById('detailModalTitle').textContent = `${spot.name} (${spot.code})`;
            document.getElementById('detailDownloadQrBtn').href = `/admin/feeding/spots/${spot.id}/qr-download?format=png`;
            document.getElementById('detailPrintQrBtn').href = `/admin/feeding/spots/${spot.id}/qr-sheet`;
            document.getElementById('detailRegenQrForm').action = `/admin/feeding/spots/${spot.id}/qr`;

            const photoContainer = document.getElementById('detailSpotPhotoContainer');
            const photoImg = document.getElementById('detailSpotPhotoImg');
            if (spot.image_url) {
                photoImg.src = spot.image_url;
                photoContainer.style.display = 'block';
            } else {
                photoImg.src = '';
                photoContainer.style.display = 'none';
            }

            const areaInfo = identifyCampusArea(parseFloat(spot.latitude), parseFloat(spot.longitude), spot.code);
            const resolvedAreaName = spot.location_name || areaInfo.name;
            const catName = (spot.cats && spot.cats[0]) ? `${spot.cats[0].name} (${spot.cats[0].unique_code})` : 'Belum dipilih';

            const dl = document.getElementById('detailSpotList');
            dl.innerHTML = `
                <dt>Kode Spot</dt>
                <dd><span class="spot-code">${spot.code}</span></dd>
                <dt>Nama Lokasi</dt>
                <dd>${spot.name}</dd>
                <dt>Area Kampus</dt>
                <dd>${resolvedAreaName}</dd>
                <dt>Informasi Kucing</dt>
                <dd>${catName}</dd>
                <dt>Status</dt>
                <dd>${spot.status}${spot.status_reason ? ' — ' + spot.status_reason : ''}</dd>
                <dt>Koordinat</dt>
                <dd>${spot.latitude}, ${spot.longitude}</dd>
                <dt>Deskripsi</dt>
                <dd>${spot.description || '-'}</dd>
            `;

            document.getElementById('detailModal').classList.add('open');
        }

        function closeDetailSpotModal() {
            document.getElementById('detailModal').classList.remove('open');
        }
    </script>
</body>
</html>
