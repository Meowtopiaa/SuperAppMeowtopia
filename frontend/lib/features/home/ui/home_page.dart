import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../../../core/widgets/feature_shortcuts.dart';
import '../../auth/logic/auth_provider.dart';
import '../../feeding_spot/logic/feeding_spot_provider.dart';
import '../../feeding_spot/ui/feeding_widgets.dart';
import 'feature_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FeedingSpotProvider>().fetchSpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedingSpotProvider>();
    final user = context.watch<AuthProvider>().user;
    final name = user?.name.split(' ').first ?? 'Teman Kucing';
    final priority = provider.spots
        .where((s) => s.isActive && s.hasLowActivity)
        .toList();
    return MeowPage(
      back: false,
      child: RefreshIndicator(
        onRefresh: () => provider.fetchSpots(refresh: true),
        child: ListView(
          padding: MeowPage.scrollPadding(context, top: 16, bottom: 28),
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/figma/meowtopia-logo.png',
                    width: 46,
                    height: 46,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meowtopia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7,
                        ),
                      ),
                      Text(
                        'Kampus ramah, kucing bahagia.',
                        style: TextStyle(fontSize: 11, color: MeowStyle.brown),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Aktivitas saya',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => context.go('/activity'),
                ),
                IconButton(
                  tooltip: 'Akun saya',
                  icon: const IconBubble(
                    Icons.person_outline_rounded,
                    size: 36,
                  ),
                  onPressed: () => context.go('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Halo, $name!',
              style: const TextStyle(fontSize: 14, color: MeowStyle.brown),
            ),
            const SizedBox(height: 5),
            const Text(
              'Sedikit peduli,\nbesar artinya.',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.16,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 18),
            const FeatureShortcuts(),
            const SizedBox(height: 22),
            const FeatureCarousel(),
            const SizedBox(height: 12),
            _OverviewBento(
              activeSpots: provider.spots.where((spot) => spot.isActive).length,
              pending: provider.pendingCount,
              points: provider.isDemo
                  ? provider.creditedPoints
                  : user?.pointsBalance ?? 0,
            ),
            const SizedBox(height: 24),
            SectionTitle(
              'Spot yang perlu dilihat',
              trailing: TextButton(
                onPressed: () => context.go('/feeding'),
                child: const Text('Lihat semua'),
              ),
            ),
            const SizedBox(height: 10),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (provider.errorMessage != null)
              FeedingMessage(
                provider.errorMessage!,
                action: 'Coba lagi',
                onAction: () => provider.fetchSpots(refresh: true),
              ),
            if (!provider.isLoading &&
                provider.errorMessage == null &&
                priority.isEmpty)
              const FeedingMessage(
                'Belum ada data prioritas. Buka daftar spot untuk melihat lokasi resmi.',
              ),
            for (final spot in priority.take(2)) ...[
              FeedingSpotPreviewCard(spot: spot, isDemo: provider.isDemo),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            GlassCard(
              color: const Color(0xFFFFEEE3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBubble(
                    Icons.volunteer_activism_outlined,
                    color: MeowStyle.orange,
                    foreground: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peduli dengan cara yang tepat',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Gunakan spot resmi, jaga kebersihan, dan biarkan kucing mendekat dengan nyaman.',
                          style: TextStyle(
                            fontSize: 12,
                            color: MeowStyle.brown,
                            height: 1.55,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/feeding'),
                          child: const Text('Mulai dari satu mangkuk →'),
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
    );
  }
}

class _OverviewBento extends StatelessWidget {
  const _OverviewBento({
    required this.activeSpots,
    required this.pending,
    required this.points,
  });

  final int activeSpots, pending, points;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.location_on_outlined,
                  value: '$activeSpots',
                  label: 'Spot aktif',
                  detail: 'Titik resmi',
                  color: MeowStyle.green,
                  background: const Color(0xFFE7F4EE),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _OverviewMetric(
                  icon: Icons.schedule_rounded,
                  value: '$pending',
                  label: 'Dalam review',
                  detail: 'Verifikasi',
                  color: const Color(0xFF65508C),
                  background: const Color(0xFFF0ECF8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA6481D),
                  Color(0xFF703B27),
                  Color(0xFF3B2821),
                ],
                stops: [0, .52, 1],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
            ),
            child: Stack(
              children: [
                const Positioned(
                  right: -22,
                  top: 29,
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.stars_rounded,
                      size: 118,
                      color: Color(0x14FFC08A),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            color: MeowStyle.peach,
                            size: 15,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'POIN SAYA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: MeowStyle.peach,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$points',
                              style: const TextStyle(
                                fontSize: 68,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                letterSpacing: -3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'poin',
                              style: TextStyle(
                                fontSize: 12,
                                color: MeowStyle.peach,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: MeowStyle.peach.withValues(alpha: .22),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dari aksi baikmu',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFF0E0D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String value, label, detail;
  final Color color, background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .9)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: color.withValues(alpha: .85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 4,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.5,
                height: 1,
                color: color,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
