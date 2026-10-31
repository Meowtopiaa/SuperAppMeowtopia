import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_feature.dart';
import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/cinematic_card.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/feature_shortcuts.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../../auth/logic/auth_provider.dart';
import '../../feeding_spot/logic/feeding_spot_provider.dart';
import '../data/activity_entry.dart';
import '../data/activity_service.dart';
import '../data/demo_activity_data.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final ActivityService _service = ActivityService();
  final List<ActivityEntry> _examples = previewActivities(DateTime.now());
  Future<List<ActivityEntry>>? _request;
  AppFeature? _filter;
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().user?.id;
    if (userId != _userId) {
      _userId = userId;
      _request = userId == null || context.read<FeedingSpotProvider>().isDemo
          ? null
          : _service.getMyActivities();
    }
  }

  Future<void> _refresh() async {
    if (_userId == null || context.read<FeedingSpotProvider>().isDemo) return;
    final request = _service.getMyActivities();
    setState(() => _request = request);
    try {
      await request;
    } catch (_) {
      /* FutureBuilder renders the request error. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final feeding = context.watch<FeedingSpotProvider>();
    final authenticated = context.watch<AuthProvider>().isAuthenticated;
    return MeowPage(
      back: false,
      child: FutureBuilder<List<ActivityEntry>>(
        future: _request,
        builder: (context, snapshot) {
          final entries = feeding.isDemo
              ? [
                  ...feeding.history.map(ActivityEntry.fromFeeding),
                  ..._examples,
                ]
              : [...?snapshot.data];
          entries.sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );
          final visible = entries
              .where((entry) => _filter == null || entry.feature == _filter)
              .toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: MeowPage.scrollPadding(context),
              children: [
                const Text(
                  'Aktivitas Saya',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Semua jejak kepedulianmu di Meowtopia.',
                  style: TextStyle(fontSize: 13, color: MeowStyle.brown),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'Semua'),
                      for (final feature in AppFeature.values)
                        _filterChip(feature, feature.label),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!feeding.isDemo && !authenticated)
                  GlassCard(
                    child: Column(
                      children: [
                        const IconBubble(Icons.history_rounded),
                        const SizedBox(height: 14),
                        const Text(
                          'Masuk untuk melihat aktivitas pribadimu.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        MeowButton(
                          label: 'Masuk ke akun',
                          icon: Icons.login_rounded,
                          onPressed: () => context.push('/login'),
                        ),
                      ],
                    ),
                  )
                else if (snapshot.connectionState == ConnectionState.waiting &&
                    !feeding.isDemo)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError && !feeding.isDemo)
                  GlassCard(
                    child: Column(
                      children: [
                        const Text(
                          'Riwayat aktivitas belum dapat dimuat. Silakan coba lagi.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        MeowButton(
                          label: 'Coba lagi',
                          icon: Icons.refresh_rounded,
                          onPressed: _refresh,
                        ),
                      ],
                    ),
                  )
                else if (visible.isEmpty)
                  const GlassCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          'Belum ada aktivitas di kategori ini.',
                          style: TextStyle(color: MeowStyle.brown),
                        ),
                      ),
                    ),
                  )
                else
                  for (final entry in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityCard(entry: entry),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(AppFeature? feature, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == feature,
      onSelected: (_) => setState(() => _filter = feature),
      selectedColor: MeowStyle.peach,
      backgroundColor: Colors.white.withValues(alpha: .7),
      side: BorderSide.none,
      showCheckmark: false,
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(fontSize: 12),
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) => CinematicCard(
    image: AssetImage(entry.feature.coverAsset),
    color: Color.lerp(MeowStyle.ink, entry.feature.foreground, .12)!,
    padding: const EdgeInsets.all(18),
    onTap: () => context.push(entry.route),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeatureArtwork(feature: entry.feature, size: 38),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.feature.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: MeowStyle.peach,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                entry.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD8DCE5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              MeowPill(
                entry.status,
                color: Colors.white.withValues(alpha: .13),
                foreground: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                relativeTime(entry.createdAt),
                style: const TextStyle(fontSize: 10, color: Color(0xFFCFD3DD)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white70,
          size: 20,
        ),
      ],
    ),
  );
}
