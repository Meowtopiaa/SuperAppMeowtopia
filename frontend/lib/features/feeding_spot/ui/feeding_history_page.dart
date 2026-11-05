import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_session.dart';
import '../logic/feeding_spot_provider.dart';
import 'feeding_widgets.dart';

class FeedingHistoryPage extends StatefulWidget {
  const FeedingHistoryPage({super.key});
  @override
  State<FeedingHistoryPage> createState() => _FeedingHistoryPageState();
}

class _FeedingHistoryPageState extends State<FeedingHistoryPage> {
  FeedingStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedingSpotProvider>().fetchMyActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();
    final items = provider.history
        .where((item) => _filter == null || item.status == _filter)
        .toList();
    return MeowPage(
      title: 'Riwayat Spot Makan',
      child: ListView(
        padding: MeowPage.scrollPadding(context),
        children: [
          const Text(
            'Jejak Pemberian Makan',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pantau bukti, pemeriksaan, dan poinmu.',
            style: TextStyle(fontSize: 12, color: MeowStyle.brown),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Row(
              children: [
                const IconBubble(Icons.volunteer_activism_outlined, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.history.length} kegiatan tercatat',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${provider.pendingCount} menunggu pemeriksaan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: MeowStyle.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${provider.creditedPoints}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: MeowStyle.orangeDark,
                      ),
                    ),
                    Text(
                      provider.isDemo ? 'Poin contoh' : 'Poin AFS',
                      style: const TextStyle(
                        fontSize: 10,
                        color: MeowStyle.brown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in <(FeedingStatus?, String)>[
                  (null, 'Semua'),
                  (FeedingStatus.underReview, 'Dalam review'),
                  (FeedingStatus.verified, 'Terverifikasi'),
                  (FeedingStatus.rejected, 'Perlu diperbaiki'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.$2),
                      selected: _filter == entry.$1,
                      onSelected: (_) => setState(() => _filter = entry.$1),
                      showCheckmark: false,
                      selectedColor: MeowStyle.peach,
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const FeedingMessage(
              'Belum ada kegiatan dalam kategori ini. Kegiatan baru akan muncul setelah bukti dikirim.',
            ),
          for (final item in items) ...[
            GlassCard(
              onTap: () => context.push('/feeding/submission/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MeowPill(
                          item.statusLabel,
                          color: item.status == FeedingStatus.verified
                              ? const Color(0xFFC8FBE6)
                              : item.status == FeedingStatus.rejected
                              ? const Color(0xFFFFE9E8)
                              : MeowStyle.lilac,
                          foreground: item.status == FeedingStatus.verified
                              ? MeowStyle.green
                              : item.status == FeedingStatus.rejected
                              ? MeowStyle.danger
                              : MeowStyle.brown,
                          icon: item.status == FeedingStatus.verified
                              ? Icons.check_circle_outline
                              : Icons.schedule_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        relativeTime(item.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: MeowStyle.brown,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.photo != null
                            ? Image.memory(
                                item.photo!.bytes,
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/figma/feeding-proof-summary.png',
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.spot.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.foodLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: MeowStyle.brown,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.creditedPoints > 0
                                  ? '${item.rewardStatusLabel} · +${item.creditedPoints} poin'
                                  : item.rewardStatusLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: MeowStyle.orangeDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: MeowStyle.brown,
                      ),
                    ],
                  ),
                  if (item.reason != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      item.reason!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MeowStyle.danger,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          MeowButton(
            label: 'Catat kebaikan berikutnya',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => context.push('/feeding/scan'),
          ),
        ],
      ),
    );
  }
}
