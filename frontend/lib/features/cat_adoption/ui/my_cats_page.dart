import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_indicator.dart';
import '../data/adoption_model.dart';
import '../logic/adoption_provider.dart';
import 'adoption_theme.dart';
import 'adoption_widgets.dart';

/// Layar 5: Kucing Saya. Hanya adopsi ACTIVE yang tampil (ADP-08);
/// status kelayakan ditampilkan terpisah di bawahnya.
class MyCatsPage extends StatefulWidget {
  const MyCatsPage({super.key});

  @override
  State<MyCatsPage> createState() => _MyCatsPageState();
}

class _MyCatsPageState extends State<MyCatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final provider = context.read<AdoptionProvider>();
    await provider.fetchMyActiveAdoptions();
    await provider.fetchMyApplications();
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
        title: const Text('Kucing saya', style: AdoptionTheme.titleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            tooltip: 'Riwayat pengajuan kelayakan',
            onPressed: () => _showApplicationsSheet(context, provider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: provider.isLoading
          ? const LoadingIndicator(message: 'Memuat adopsimu...')
          : provider.errorMessage != null
              ? AdoptionErrorState(
                  message: provider.errorMessage!,
                  onRetry: _reload,
                )
              : RefreshIndicator(
                  color: AdoptionTheme.accent,
                  onRefresh: _reload,
                  child: AdoptionPageBody(
                    children: [
                      if (provider.myActiveAdoptions.isEmpty)
                        AdoptionEmptyState(
                          message: 'Kamu belum mengadopsi kucing',
                          submessage: 'Kucing muncul di sini setelah kelayakanmu disetujui '
                              'dan pengambilan selesai.',
                          action: AdoptionSecondaryButton(
                            label: 'Lihat katalog',
                            onPressed: () => context.push('/adoption'),
                          ),
                        )
                      else
                        ...provider.myActiveAdoptions.map(
                          (adoption) => _AdoptionBlock(adoption: adoption),
                        ),
                      const SizedBox(height: 8),
                      _buildEligibilitySection(provider),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEligibilitySection(AdoptionProvider provider) {
    final apps = provider.myApplications;
    final latest = apps.isEmpty ? null : apps.first;

    return AdoptionSection(
      title: 'Status kelayakan',
      child: Row(
        children: [
          Expanded(
            child: latest == null
                ? const Text('Belum ada pengajuan.', style: AdoptionTheme.bodyStyle)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ApplicationStatusBadge(status: latest.status),
                  ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AdoptionTheme.accent),
            onPressed: () => latest == null
                ? context.push('/adoption/apply')
                : context.push('/adoption/detail/${latest.id}'),
            child: Text(latest == null ? 'Isi form kelayakan' : 'Lihat rincian'),
          ),
        ],
      ),
    );
  }

  void _showApplicationsSheet(BuildContext context, AdoptionProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdoptionTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final apps = provider.myApplications;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(ctx).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Riwayat pengajuan', style: AdoptionTheme.titleStyle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              if (apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Belum ada pengajuan.', style: AdoptionTheme.bodyStyle),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: apps.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AdoptionTheme.divider),
                    itemBuilder: (_, index) {
                      final item = apps[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.catName ?? 'Belum memilih kucing',
                          style: AdoptionTheme.subtitleStyle,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ApplicationStatusBadge(status: item.status),
                          ),
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

/// Satu adopsi: identitas kucing, laporan berikutnya, dan aksi lain.
class _AdoptionBlock extends StatelessWidget {
  final ActiveAdoptionModel adoption;

  const _AdoptionBlock({required this.adoption});

  @override
  Widget build(BuildContext context) {
    final cat = adoption.cat;
    final catName = cat?.name ?? 'Kucing adopsi';
    final total = adoption.totalFollowups > 0 ? adoption.totalFollowups : 6;
    final done = adoption.completedFollowups.clamp(0, total);
    final allDone = done >= total;
    final currentCycle = done + 1;
    final diffDays = adoption.nextFollowupDue.difference(DateTime.now()).inDays;
    final isLate = !allDone && diffDays < 0;
    final encodedName = Uri.encodeComponent(catName);

    final dueText = allDone
        ? 'Semua laporan tiga bulan pertama sudah dikirim.'
        : isLate
            ? 'Laporan ke-$currentCycle terlambat ${diffDays.abs()} hari. '
                'Kirim sekarang, laporan terlambat tetap diterima.'
            : 'Laporan ke-$currentCycle paling lambat '
                '${formatAdoptionDate(adoption.nextFollowupDue)}.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: CatPhotoBox(photoUrl: cat?.primaryPhotoUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(catName, style: AdoptionTheme.headlineStyle),
                    const SizedBox(height: 4),
                    if (cat != null)
                      Text(
                        '${cat.gender == 'male' ? 'Jantan' : 'Betina'}, ${cat.breed}',
                        style: AdoptionTheme.bodyStyle,
                      ),
                    Text(
                      'Diadopsi sejak ${formatAdoptionDate(adoption.adoptedAt)}',
                      style: AdoptionTheme.bodyStyle,
                    ),
                    const SizedBox(height: 8),
                    ActiveAdoptionStatusBadge(status: adoption.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AdoptionSection(
            title: 'Laporan kondisi',
            trailing: Text('$done dari $total terkirim', style: AdoptionTheme.captionStyle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FollowupProgress(total: total, done: done, isLate: isLate),
                const SizedBox(height: 12),
                Text(
                  dueText,
                  style: AdoptionTheme.bodyStyle.copyWith(
                    color: isLate ? AdoptionTheme.danger : AdoptionTheme.textMain,
                  ),
                ),
                if (!allDone) ...[
                  const SizedBox(height: 14),
                  AdoptionPrimaryButton(
                    label: 'Kirim laporan ke-$currentCycle',
                    icon: Icons.photo_camera_outlined,
                    onPressed: () => context.push(
                      '/adoption/followup?adoption_id=${adoption.id}&cycle=$currentCycle&cat_name=$encodedName',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AdoptionTheme.divider),
          _LinkRow(
            label: 'Laporkan kendala',
            description: 'Sakit, hilang, meninggal, atau kalung rusak',
            onTap: () => context.push(
              '/adoption/issue?adoption_id=${adoption.id}&cat_id=${adoption.catId}&name=$encodedName',
            ),
          ),
          const Divider(height: 1, color: AdoptionTheme.divider),
          _LinkRow(
            label: 'Ajukan pengembalian',
            description: 'Syarat dan alur pengembalian kucing',
            onTap: () => context.push(
              '/adoption/return?adoption_id=${adoption.id}&name=$encodedName',
            ),
          ),
          const Divider(height: 1, color: AdoptionTheme.divider),
        ],
      ),
    );
  }
}

/// Garis kemajuan laporan: satu ruas per laporan.
class _FollowupProgress extends StatelessWidget {
  final int total;
  final int done;
  final bool isLate;

  const _FollowupProgress({
    required this.total,
    required this.done,
    required this.isLate,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$done dari $total laporan terkirim',
      child: Row(
        children: List.generate(total, (i) {
          final Color color;
          if (i < done) {
            color = AdoptionTheme.accent;
          } else if (i == done && isLate) {
            color = AdoptionTheme.danger;
          } else {
            color = AdoptionTheme.divider;
          }
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onTap;

  const _LinkRow({
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AdoptionTheme.bodyStyle.copyWith(
                      color: AdoptionTheme.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(description, style: AdoptionTheme.captionStyle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AdoptionTheme.textHint),
          ],
        ),
      ),
    );
  }
}
