import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../data/adoption_enums.dart';
import '../data/adoption_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 5 — Kucing Saya (Dashboard Adopsi Aktif, Web & Mobile Responsif)
class MyCatsPage extends StatefulWidget {
  const MyCatsPage({super.key});

  @override
  State<MyCatsPage> createState() => _MyCatsPageState();
}

class _MyCatsPageState extends State<MyCatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AdoptionProvider>();
      provider.fetchMyActiveAdoptions();
      provider.fetchMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdoptionProvider>();

    return Scaffold(
      backgroundColor: AdoptionTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AdoptionTheme.pageBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Kucing Saya', style: AdoptionTheme.titleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            tooltip: 'Riwayat Pengajuan Kelayakan',
            onPressed: () => _showApplicationsSheet(context, provider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator(message: 'Memuat data adopsi aktif...')
          : provider.errorMessage != null
              ? AdoptionErrorState(
                  message: provider.errorMessage!,
                  onRetry: () {
                    provider.fetchMyActiveAdoptions();
                    provider.fetchMyApplications();
                  },
                )
              : provider.myActiveAdoptions.isEmpty
                  ? _buildEmptyState(context, provider)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 960;

                        if (isDesktop) {
                          // ── Tampilan Desktop (2 Kolom Dashboard Adopter) ──
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1140),
                              child: RefreshIndicator(
                                color: AdoptionTheme.accent,
                                onRefresh: () async {
                                  await provider.fetchMyActiveAdoptions();
                                  await provider.fetchMyApplications();
                                },
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                                  children: [
                                    ...provider.myActiveAdoptions.map((adoption) {
                                      return _buildDesktopDashboard(context, adoption, provider);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        // ── Tampilan Mobile / Tablet (1 Kolom Rapi) ─────────
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: RefreshIndicator(
                              color: AdoptionTheme.accent,
                              onRefresh: () async {
                                await provider.fetchMyActiveAdoptions();
                                await provider.fetchMyApplications();
                              },
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                children: [
                                  _buildEligibilityStatusBanner(provider),
                                  const SizedBox(height: 16),
                                  ...provider.myActiveAdoptions.map((adoption) {
                                    return _ActiveAdoptionCardMobile(adoption: adoption);
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  // ── Desktop Dashboard Layout (2 Kolom Seimbang) ───────────────────────────
  Widget _buildDesktopDashboard(
    BuildContext context,
    ActiveAdoptionModel adoption,
    AdoptionProvider provider,
  ) {
    final cat = adoption.cat;
    final catName = cat?.name ?? 'Kucing #${adoption.catId}';
    final adoptedDate =
        '${adoption.adoptedAt.day}/${adoption.adoptedAt.month}/${adoption.adoptedAt.year}';
    final nextDue = adoption.nextFollowupDue;
    final dueStr = '${nextDue.day}/${nextDue.month}/${nextDue.year}';
    final diffDays = nextDue.difference(DateTime.now()).inDays;
    final currentCycle = adoption.completedFollowups + 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Kolom Kiri: Profil Kucing & Aksi Cepat (width: 380) ───────────
        SizedBox(
          width: 380,
          child: Column(
            children: [
              // Kartu Profil Kucing Adopsi
              Container(
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
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: AdoptionTheme.borderMd,
                          child: Container(
                            width: 64,
                            height: 64,
                            color: AdoptionTheme.accentSurface,
                            child: const Center(
                              child: Icon(
                                Icons.pets_rounded,
                                size: 30,
                                color: AdoptionTheme.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: AdoptionTheme.titleStyle.copyWith(fontSize: 17),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _ActiveBadge(status: adoption.status),
                                ],
                              ),
                              const SizedBox(height: 3),
                              if (cat != null)
                                Text(
                                  '${cat.breed} · ${cat.gender == 'male' ? 'Jantan' : 'Betina'}',
                                  style: AdoptionTheme.captionStyle,
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Mulai adopsi: $adoptedDate',
                                style: AdoptionTheme.captionStyle.copyWith(
                                  color: AdoptionTheme.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AdoptionTheme.divider),
                    const SizedBox(height: 14),
                    _buildEligibilityStatusBanner(provider),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Kartu Aksi Cepat (Lapor Kendala & Pengembalian)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AdoptionTheme.borderLg,
                  border: Border.all(color: AdoptionTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pusat Bantuan Adopter',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: AdoptionTheme.borderMd,
                      onTap: () {
                        context.push(
                          '/adoption/issue?adoption_id=${adoption.id}&cat_id=${adoption.catId}&name=${Uri.encodeComponent(catName)}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                          borderRadius: AdoptionTheme.borderMd,
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.report_problem_outlined, size: 20, color: Color(0xFFD97706)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lapor Kendala Kucing',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Sakit, hilang, meninggal, atau kalung rusak',
                                    style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: AdoptionTheme.borderMd,
                      onTap: () {
                        context.push(
                          '/adoption/return?adoption_id=${adoption.id}&name=${Uri.encodeComponent(catName)}',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: AdoptionTheme.borderMd,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.assignment_return_outlined, size: 20, color: Color(0xFF4B5563)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ajukan Pengembalian',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Informasi kebijakan pengembalian kampus',
                                    style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF4B5563)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // ── Kolom Kanan: Pemantauan Follow-up Berkala ───────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Jadwal Laporan Berikutnya
              Container(
                padding: const EdgeInsets.all(22),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AdoptionTheme.accentLight,
                            borderRadius: AdoptionTheme.borderSm,
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            size: 24,
                            color: AdoptionTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan Follow-up ke-$currentCycle dari 6',
                                style: AdoptionTheme.titleStyle.copyWith(fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                diffDays >= 0
                                    ? 'Jatuh tempo: $dueStr (sisa $diffDays hari lagi)'
                                    : 'Jatuh tempo: $dueStr (melewati batas waktu $diffDays hari)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: diffDays < 0 ? AdoptionTheme.danger : AdoptionTheme.textSub,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdoptionTheme.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AdoptionTheme.borderMd,
                            ),
                          ),
                          onPressed: () {
                            context.push(
                              '/adoption/followup?adoption_id=${adoption.id}&cycle=$currentCycle&cat_name=${Uri.encodeComponent(catName)}',
                            );
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 16),
                              SizedBox(width: 6),
                              Text('Isi Laporan Sekarang', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AdoptionTheme.divider),
                    const SizedBox(height: 18),

                    // Rincian 6 Siklus Pemantauan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progres 6 Siklus Pemantauan (14 Harian)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${adoption.completedFollowups} dari 6 selesai',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AdoptionTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final cycleNum = index + 1;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 4,
                              right: index == 5 ? 0 : 4,
                            ),
                            child: _CycleBadge(
                              cycleNumber: cycleNum,
                              completedCycles: adoption.completedFollowups,
                              isLate: diffDays < 0 && cycleNum == currentCycle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AdoptionTheme.accentSurface,
                        borderRadius: AdoptionTheme.borderMd,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AdoptionTheme.accent),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Laporan foto kamera dan kondisi kucing wajib dikirim setiap 14 hari selama 3 bulan pertama.',
                              style: TextStyle(fontSize: 11, color: AdoptionTheme.textMain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AdoptionProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildEligibilityStatusBanner(provider),
              const SizedBox(height: 32),
              AdoptionEmptyState(
                icon: Icons.pets_rounded,
                message: 'Belum ada kucing yang Anda adopsi',
                submessage:
                    'Setelah pengajuan kelayakan disetujui dan proses pengambilan selesai, kucing Anda akan muncul di sini.',
                action: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdoptionTheme.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
                  ),
                  onPressed: () => context.push('/adoption'),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Jelajahi Katalog Adopsi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEligibilityStatusBanner(AdoptionProvider provider) {
    final apps = provider.myApplications;
    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AdoptionTheme.borderMd,
          border: Border.all(color: AdoptionTheme.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: AdoptionTheme.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status Kelayakan: Belum ada pengajuan',
                style: AdoptionTheme.captionStyle.copyWith(color: AdoptionTheme.textSub),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/adoption/apply'),
              child: Text(
                'Ajukan',
                style: AdoptionTheme.captionStyle.copyWith(
                  color: AdoptionTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final latest = apps.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AdoptionTheme.borderMd,
        border: Border.all(color: AdoptionTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            latest.status.icon,
            size: 16,
            color: latest.status.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kelayakan: ${latest.status.labelId}',
              style: AdoptionTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: AdoptionTheme.textMain,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/adoption/detail/${latest.id}'),
            child: Text(
              'Rincian →',
              style: AdoptionTheme.captionStyle.copyWith(
                color: AdoptionTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationsSheet(BuildContext context, AdoptionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final apps = provider.myApplications;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Riwayat Pengajuan Kelayakan', style: AdoptionTheme.titleStyle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Belum ada pengajuan.', style: AdoptionTheme.bodyStyle),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: apps.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 12, color: AdoptionTheme.divider),
                    itemBuilder: (_, index) {
                      final item = apps[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: item.status.backgroundColor,
                          child: Icon(item.status.icon, color: item.status.color, size: 18),
                        ),
                        title: Text(
                          item.catName ?? 'Draf Pengajuan',
                          style: AdoptionTheme.subtitleStyle,
                        ),
                        subtitle: Text(
                          item.status.labelId,
                          style: AdoptionTheme.captionStyle.copyWith(color: item.status.color),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/adoption/detail/${item.id}');
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Kartu Adopsi Aktif (Versi Mobile) ───────────────────────────────────────
class _ActiveAdoptionCardMobile extends StatelessWidget {
  final ActiveAdoptionModel adoption;

  const _ActiveAdoptionCardMobile({required this.adoption});

  @override
  Widget build(BuildContext context) {
    final cat = adoption.cat;
    final catName = cat?.name ?? 'Kucing #${adoption.catId}';
    final adoptedDate =
        '${adoption.adoptedAt.day}/${adoption.adoptedAt.month}/${adoption.adoptedAt.year}';
    final nextDue = adoption.nextFollowupDue;
    final dueStr = '${nextDue.day}/${nextDue.month}/${nextDue.year}';
    final diffDays = nextDue.difference(DateTime.now()).inDays;
    final currentCycle = adoption.completedFollowups + 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AdoptionTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AdoptionTheme.borderMd,
                  child: Container(
                    width: 72,
                    height: 72,
                    color: AdoptionTheme.accentSurface,
                    child: Center(
                      child: Icon(
                        Icons.pets_rounded,
                        size: 32,
                        color: AdoptionTheme.accent.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              catName,
                              style: AdoptionTheme.titleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _ActiveBadge(status: adoption.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (cat != null)
                        Text(
                          '${cat.breed} · ${cat.gender == 'male' ? 'Jantan' : 'Betina'}',
                          style: AdoptionTheme.captionStyle,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Mulai adopsi: $adoptedDate',
                        style: AdoptionTheme.captionStyle.copyWith(
                          color: AdoptionTheme.textHint,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdoptionTheme.divider),
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFFAF9F7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event_note_rounded, size: 18, color: AdoptionTheme.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Follow-up Berikutnya', style: AdoptionTheme.subtitleStyle),
                          const SizedBox(height: 2),
                          Text(
                            diffDays >= 0
                                ? 'Jatuh tempo: $dueStr (sisa $diffDays hari)'
                                : 'Jatuh tempo: $dueStr (terlambat ${diffDays.abs()} hari)',
                            style: AdoptionTheme.captionStyle.copyWith(
                              color: diffDays < 0 ? AdoptionTheme.danger : AdoptionTheme.textSub,
                              fontWeight: diffDays < 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdoptionTheme.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: const RoundedRectangleBorder(borderRadius: AdoptionTheme.borderMd),
                      ),
                      onPressed: () {
                        context.push(
                          '/adoption/followup?adoption_id=${adoption.id}&cycle=$currentCycle&cat_name=${Uri.encodeComponent(catName)}',
                        );
                      },
                      child: const Text('Isi Laporan'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Progres Pemantauan (Siklus 1 - 6):',
                  style: AdoptionTheme.captionStyle.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final cycleNum = index + 1;
                    return _CycleBadge(
                      cycleNumber: cycleNum,
                      completedCycles: adoption.completedFollowups,
                      isLate: diffDays < 0 && cycleNum == currentCycle,
                    );
                  }),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdoptionTheme.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AdoptionTheme.textSub,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      context.push(
                        '/adoption/issue?adoption_id=${adoption.id}&cat_id=${adoption.catId}&name=${Uri.encodeComponent(catName)}',
                      );
                    },
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: const Text('Lapor Kendala', style: TextStyle(fontSize: 12)),
                  ),
                ),
                Container(width: 1, height: 16, color: AdoptionTheme.divider),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AdoptionTheme.textSub,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      context.push(
                        '/adoption/return?adoption_id=${adoption.id}&name=${Uri.encodeComponent(catName)}',
                      );
                    },
                    icon: const Icon(Icons.assignment_return_outlined, size: 16),
                    label: const Text('Pengembalian', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final ActiveAdoptionStatus status;

  const _ActiveBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: Color(0xFFDCFCE7),
        borderRadius: AdoptionTheme.borderSm,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 12, color: Color(0xFF15803D)),
          SizedBox(width: 4),
          Text(
            'Aktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleBadge extends StatelessWidget {
  final int cycleNumber;
  final int completedCycles;
  final bool isLate;

  const _CycleBadge({
    required this.cycleNumber,
    required this.completedCycles,
    required this.isLate,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = cycleNumber <= completedCycles;
    final isCurrent = cycleNumber == completedCycles + 1;

    Color bg;
    Color fg;
    String label;

    if (isCompleted) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'Selesai';
    } else if (isCurrent) {
      if (isLate) {
        bg = const Color(0xFFFEE2E2);
        fg = AppConstants.dangerColor;
        label = 'Terlambat';
      } else {
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'Menunggu';
      }
    } else {
      bg = AdoptionTheme.chipBg;
      fg = AdoptionTheme.textHint;
      label = 'Nanti';
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: isCurrent ? Border.all(color: fg, width: 1.5) : null,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, size: 16, color: fg)
                : Text(
                    '$cycleNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: fg,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
