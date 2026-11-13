import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/adoption_enums.dart';
import '../data/adoption_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 3 — Status & Detail Pengajuan Kelayakan (Web & Mobile Responsif)
class AdoptionDetailPage extends StatefulWidget {
  final int applicationId;

  const AdoptionDetailPage({
    super.key,
    required this.applicationId,
  });

  @override
  State<AdoptionDetailPage> createState() => _AdoptionDetailPageState();
}

class _AdoptionDetailPageState extends State<AdoptionDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdoptionProvider>().fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();

    final application = provider.myApplications.cast().firstWhere(
          (a) => a.id == widget.applicationId,
          orElse: () => null,
        );

    if (application == null) {
      return Scaffold(
        backgroundColor: AdoptionTheme.pageBg,
        appBar: AppBar(
          backgroundColor: AdoptionTheme.pageBg,
          elevation: 0,
          title: const Text('Detail Pengajuan', style: AdoptionTheme.titleStyle),
        ),
        body: AdoptionErrorState(
          message: 'Data pengajuan tidak ditemukan.',
          onRetry: () => provider.fetchMyApplications(),
        ),
      );
    }

    final catName = application.catName ??
        (application.cat != null ? application.cat!.name : 'Kucing Kampus (Umum)');

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Status Pengajuan', style: AdoptionTheme.titleStyle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          if (isDesktop) {
            // ── Tampilan Desktop (2 Kolom Seimbang) ─────────────────────
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kolom Kiri: Status Utama, Pemeriksaan Awal, & Aksi
                        SizedBox(
                          width: 380,
                          child: Column(
                            children: [
                              _buildStatusHeaderCard(application, catName),
                              const SizedBox(height: 16),
                              _buildPrecheckCard(application),
                              if (application.isRevisionRequested) ...[
                                const SizedBox(height: 16),
                                _buildRevisionActionCard(context, application),
                              ],
                              if (application.isApproved) ...[
                                const SizedBox(height: 16),
                                _buildApprovedNextStepCard(context, application),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        // Kolom Kanan: Timeline, Keputusan Admin, & Rincian Form
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTimelineCard(application),
                              if (application.adminNotes != null &&
                                  application.adminNotes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildAdminDecisionCard(context, application, catName),
                              ],
                              const SizedBox(height: 20),
                              _buildFormDetailsCard(application),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Tampilan Mobile / Tablet (1 Kolom Rapi) ───────────────────
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildStatusHeaderCard(application, catName),
                  const SizedBox(height: 16),
                  _buildTimelineCard(application),
                  const SizedBox(height: 16),
                  _buildPrecheckCard(application),
                  if (application.adminNotes != null &&
                      application.adminNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAdminDecisionCard(context, application, catName),
                  ],
                  if (application.isApproved) ...[
                    const SizedBox(height: 16),
                    _buildApprovedNextStepCard(context, application),
                  ],
                  const SizedBox(height: 20),
                  _buildFormDetailsCard(application),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Kartu Status Utama & Profil Kucing ─────────────────────────────────────
  Widget _buildStatusHeaderCard(AdoptionApplicationModel application, String catName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LargeStatusBadge(status: application.status),
          const SizedBox(height: 16),
          Text(
            catName,
            style: AdoptionTheme.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Pemohon: ${application.applicantName}',
            style: AdoptionTheme.bodyStyle.copyWith(color: AdoptionTheme.textSub),
          ),
        ],
      ),
    );
  }

  // ── Kartu Aksi Revisi ─────────────────────────────────────────────────────
  Widget _buildRevisionActionCard(BuildContext context, AdoptionApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tindakan Diperlukan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('Admin meminta perbaikan data kelayakan.', style: TextStyle(fontSize: 11, color: AdoptionTheme.textSub)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdoptionTheme.warning,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
            ),
            onPressed: () {
              context.push(
                '/adoption/apply?edit_id=${app.id}&cat_id=${app.catId ?? ''}&name=${Uri.encodeComponent(app.catName ?? '')}',
              );
            },
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Perbaiki & Kirim Ulang', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Kartu Timeline Status ─────────────────────────────────────────────────
  Widget _buildTimelineCard(AdoptionApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tahapan Pengajuan', style: AdoptionTheme.subtitleStyle),
          const SizedBox(height: 16),
          Row(
            children: [
              _timelineStep(
                title: 'Draf',
                isDone: true,
                isActive: app.isDraft,
              ),
              _timelineConnector(isDone: !app.isDraft),
              _timelineStep(
                title: 'Terkirim',
                isDone: !app.isDraft,
                isActive: app.isSubmitted,
              ),
              _timelineConnector(isDone: app.isApproved || app.isRejected || app.isRevisionRequested),
              _timelineStep(
                title: app.isRevisionRequested
                    ? 'Revisi'
                    : (app.isRejected ? 'Ditolak' : 'Keputusan'),
                isDone: app.isApproved || app.isRejected,
                isActive: app.isApproved || app.isRejected || app.isRevisionRequested,
                isWarning: app.isRevisionRequested,
                isDanger: app.isRejected,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required bool isDone,
    required bool isActive,
    bool isWarning = false,
    bool isDanger = false,
  }) {
    Color bg;
    Color fg;

    if (isDanger) {
      bg = AdoptionTheme.danger;
      fg = Colors.white;
    } else if (isWarning) {
      bg = AdoptionTheme.warning;
      fg = Colors.white;
    } else if (isDone || isActive) {
      bg = AdoptionTheme.accent;
      fg = Colors.white;
    } else {
      bg = AdoptionTheme.chipBg;
      fg = AdoptionTheme.textHint;
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isDone ? Icons.check_rounded : Icons.circle,
              size: 14,
              color: fg,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AdoptionTheme.captionStyle.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AdoptionTheme.textMain : AdoptionTheme.textHint,
          ),
        ),
      ],
    );
  }

  Widget _timelineConnector({required bool isDone}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isDone ? AdoptionTheme.accent : AdoptionTheme.divider,
      ),
    );
  }

  // ── Kartu Pemeriksaan Awal (Precheck) ─────────────────────────────────────
  Widget _buildPrecheckCard(AdoptionApplicationModel app) {
    final passed = app.precheckPassed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(
          color: passed
              ? AdoptionTheme.success.withValues(alpha: 0.3)
              : AdoptionTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.verified_outlined : Icons.pending_outlined,
            size: 20,
            color: passed ? AdoptionTheme.success : AdoptionTheme.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passed
                      ? 'Pemeriksaan Awal Sistem: Terpenuhi'
                      : 'Pemeriksaan Awal Sistem: Belum Lengkap',
                  style: AdoptionTheme.subtitleStyle.copyWith(
                    color: passed ? const Color(0xFF166534) : const Color(0xFF92400E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  passed
                      ? 'Dokumen kelayakan dasar (izin tempat tinggal, kesiapan finansial, dan komitmen) telah terisi lengkap. Menunggu keputusan final pengelola.'
                      : 'Beberapa persyaratan kelayakan dasar belum lengkap atau memerlukan perbaikan.',
                  style: AdoptionTheme.captionStyle.copyWith(
                    color: passed ? const Color(0xFF166534) : const Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Keputusan Admin & Catatan ───────────────────────────────────────
  Widget _buildAdminDecisionCard(
    BuildContext context,
    AdoptionApplicationModel app,
    String catName,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined, size: 18, color: AdoptionTheme.accent),
              const SizedBox(width: 8),
              Text(
                'Catatan dari Pengelola Kampus',
                style: AdoptionTheme.subtitleStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F7),
              borderRadius: AdoptionTheme.borderMd,
              border: Border.all(color: AdoptionTheme.divider),
            ),
            child: Text(
              app.adminNotes!,
              style: AdoptionTheme.bodyStyle.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Langkah Berikutnya (APPROVED) ───────────────────────────────────
  Widget _buildApprovedNextStepCard(
    BuildContext context,
    AdoptionApplicationModel app,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 20, color: AdoptionTheme.success),
              const SizedBox(width: 8),
              Text(
                'Kelayakan Disetujui',
                style: AdoptionTheme.subtitleStyle.copyWith(
                  color: const Color(0xFF166534),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelayakan Anda telah disetujui. Ini belum berarti adopsi aktif. Silakan lakukan serah terima fisik dan pemindaian kalung QR di kampus untuk mengaktifkan adopsi.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF166534),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (app.catId != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdoptionTheme.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
                ),
                onPressed: () {
                  context.push('/adoption/pickup?app_id=${app.id}&cat_id=${app.catId}');
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Lanjut ke Pengambilan Kucing', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Kartu Rincian Formulir ────────────────────────────────────────────────
  Widget _buildFormDetailsCard(AdoptionApplicationModel application) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderLg,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Formulir Kelayakan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AdoptionTheme.divider),
          const SizedBox(height: 14),
          _detailItem('Tipe Tempat Tinggal', _housingTypeLabel(application.housingType)),
          const Divider(height: 20, color: AdoptionTheme.divider),
          _detailItem('Kesiapan Finansial', application.financialReadiness ? 'Sanggup memenuhi kebutuhan mandiri' : 'Belum sanggup'),
          const Divider(height: 20, color: AdoptionTheme.divider),
          _detailItem('Izin Pemilik Tempat / Keluarga', application.familyPermission ? 'Sudah ada izin resmi' : 'Belum ada izin'),
          const Divider(height: 20, color: AdoptionTheme.divider),
          _detailItem('Persetujuan Komitmen Adopter', application.commitmentAccepted ? 'Disetujui (Lembar Komitmen v1.0)' : 'Belum disetujui'),
          if (application.longTermPlan != null && application.longTermPlan!.isNotEmpty) ...[
            const Divider(height: 20, color: AdoptionTheme.divider),
            _detailItem('Rencana Jangka Panjang', application.longTermPlan!),
          ],
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: AdoptionTheme.captionStyle.copyWith(
              color: AdoptionTheme.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AdoptionTheme.bodyStyle.copyWith(
              color: AdoptionTheme.textMain,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _housingTypeLabel(String type) {
    switch (type) {
      case 'kos':
        return 'Kos (diizinkan memelihara hewan)';
      case 'rumah_kontrakan':
        return 'Rumah Kontrakan';
      case 'rumah_pribadi':
        return 'Rumah Pribadi / Keluarga';
      default:
        return type;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LARGE STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _LargeStatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const _LargeStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 20),
          const SizedBox(width: 8),
          Text(
            status.labelId,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
