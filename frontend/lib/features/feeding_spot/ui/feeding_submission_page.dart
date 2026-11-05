import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_session.dart';
import '../logic/feeding_spot_provider.dart';
import 'feeding_widgets.dart';

class FeedingSubmissionPage extends StatelessWidget {
  const FeedingSubmissionPage({super.key, required this.submissionId});
  final String submissionId;
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();
    final item = provider.submissionById(submissionId);
    if (item == null) {
      return MeowPage(
        title: 'Status Pengajuan',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FeedingMessage(
            'Pengajuan tidak ditemukan. Pengajuan pratinjau hanya tersedia selama aplikasi ini dibuka.',
            action: 'Lihat aktivitas',
            onAction: () => context.go('/activity'),
          ),
        ),
      );
    }
    final verified = item.status == FeedingStatus.verified;
    final rejected = item.status == FeedingStatus.rejected;
    return MeowPage(
      title: 'Status Pengajuan',
      child: ListView(
        padding: MeowPage.scrollPadding(context, top: 0, bottom: 30),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/figma/ginger-cat-hero.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x55283044), Color(0xF20A0E14)],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: MeowStyle.peach,
                                border: Border.all(
                                  color: MeowStyle.orange,
                                  width: 3,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/figma/meowtopia-badge.png',
                                  width: 56,
                                  height: 56,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -3,
                              right: -3,
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: verified
                                    ? MeowStyle.green
                                    : rejected
                                    ? MeowStyle.danger
                                    : MeowStyle.orange,
                                child: Icon(
                                  verified
                                      ? Icons.check_rounded
                                      : rejected
                                      ? Icons.priority_high_rounded
                                      : Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          verified
                              ? 'Kebaikanmu terverifikasi!'
                              : rejected
                              ? 'Bukti perlu ditinjau kembali'
                              : provider.isDemo
                              ? 'Pengajuan contoh dibuat!'
                              : 'Bukti berhasil dikirim!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          verified
                              ? 'Terima kasih telah merawat kucing kampus.'
                              : rejected
                              ? 'Lihat alasan pemeriksaan pada ringkasan.'
                              : 'Terima kasih sudah peduli.\nBukti menunggu pemeriksaan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFCED4DE),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        MeowPill(
                          item.statusLabel,
                          color: const Color(0x99283044),
                          foreground: MeowStyle.peach,
                          icon: verified
                              ? Icons.verified_outlined
                              : Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Ringkasan Pengajuan',
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 10),
                Text(
                  'ID ${item.id}',
                  style: const TextStyle(fontSize: 10, color: MeowStyle.brown),
                ),
                const Divider(height: 28, color: MeowStyle.lilac),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.photo != null
                      ? Image.memory(
                          item.photo!.bytes,
                          height: 175,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : provider.isDemo
                      ? Image.asset(
                          'assets/images/figma/feeding-proof-summary.png',
                          height: 175,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox.shrink(),
                ),
                if (item.evidence.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final photo in item.evidence.skip(1))
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              photo.bytes,
                              width: 70,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                _ReportLine(
                  label: 'LOKASI TITIK',
                  value: item.spot.name,
                  icon: Icons.location_on_outlined,
                ),
                _ReportLine(
                  label: 'PAKAN DIBERIKAN',
                  value: '${item.foodLabel}\n${item.quantity}',
                  icon: Icons.restaurant_rounded,
                ),
                _ReportLine(
                  label: 'WAKTU PENGAJUAN',
                  value:
                      '${relativeTime(item.createdAt)}\n${wibTime(item.createdAt)}',
                  icon: Icons.schedule_rounded,
                ),
                if (item.notes.isNotEmpty)
                  _ReportLine(
                    label: 'CATATAN',
                    value: item.notes,
                    icon: Icons.notes_rounded,
                  ),
                if (item.reason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.reason!,
                      style: const TextStyle(
                        color: MeowStyle.danger,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                const IconBubble(
                  Icons.stars_outlined,
                  color: MeowStyle.mint,
                  foreground: MeowStyle.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status reward',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.creditedPoints > 0
                            ? '+${item.creditedPoints} poin ${provider.isDemo ? 'contoh' : 'dikreditkan'}'
                            : 'Belum ada poin dikreditkan',
                        style: const TextStyle(
                          fontSize: 13,
                          color: MeowStyle.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.potentialPoints != null && !verified
                            ? 'Potensi ${item.potentialPoints} poin · mengikuti hasil pemeriksaan.'
                            : 'Status kegiatan dan status poin dicatat terpisah.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MeowStyle.brown,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.isDemo) ...[
            const SizedBox(height: 14),
            const Text(
              'Pengajuan ini adalah simulasi lokal. Tidak dikirim ke reviewer dan tidak mengubah saldo akun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: MeowStyle.brown,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 28),
          MeowButton(
            label: 'Kembali ke Beranda',
            icon: Icons.home_outlined,
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => context.go('/activity'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Lihat riwayat aktivitas'),
          ),
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: MeowStyle.lavender)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconBubble(icon, size: 30),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: MeowStyle.brown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}
