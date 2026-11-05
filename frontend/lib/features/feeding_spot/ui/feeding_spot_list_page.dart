import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../logic/feeding_spot_provider.dart';
import 'feeding_widgets.dart';

class FeedingSpotListPage extends StatefulWidget {
  const FeedingSpotListPage({super.key});
  @override
  State<FeedingSpotListPage> createState() => _FeedingSpotListPageState();
}

class _FeedingSpotListPageState extends State<FeedingSpotListPage> {
  String _query = '';
  String _filter = 'Semua';
  bool _mapVisible = true;
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
    final spots = provider.spots.where((spot) {
      final search = '${spot.name} ${spot.locationName}'.toLowerCase().contains(
        _query.toLowerCase(),
      );
      final filter = switch (_filter) {
        'Jarang tercatat' => spot.isActive && spot.hasLowActivity,
        'Favorit' => provider.isFavorite(spot.id),
        'Aktif' => spot.isActive,
        _ => true,
      };
      return search && filter;
    }).toList();
    return MeowPage(
      back: false,
      child: RefreshIndicator(
        onRefresh: () => provider.fetchSpots(refresh: true),
        child: ListView(
          padding: MeowPage.scrollPadding(context),
          children: [
            Row(
              children: [
                const IconBubble(Icons.restaurant_outlined),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adopt Feeding Spot',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Satu mangkuk, banyak kebaikan.',
                        style: TextStyle(fontSize: 12, color: MeowStyle.brown),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Riwayat pemberian makan',
                  onPressed: () => context.push('/feeding/history'),
                  icon: const Icon(Icons.history_rounded),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Titik kecil. Dampak besar.',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Temukan spot resmi dan catat\nkebaikanmu hari ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: MeowStyle.brown,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/figma/meowtopia-badge.png',
                          width: 74,
                          height: 74,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  MeowButton(
                    label: 'Pindai QR Spot',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () => context.push('/feeding/scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Cari spot atau area kampus',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: Colors.white.withValues(alpha: .85),
                suffixIcon: IconButton(
                  tooltip: _mapVisible ? 'Sembunyikan peta' : 'Tampilkan peta',
                  onPressed: () => setState(() => _mapVisible = !_mapVisible),
                  icon: Icon(
                    _mapVisible ? Icons.map_rounded : Icons.map_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'Semua',
                    'Jarang tercatat',
                    'Aktif',
                    'Favorit',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: MeowStyle.peach,
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: _filter == filter
                              ? MeowStyle.orangeDark
                              : MeowStyle.brown,
                        ),
                        shape: const StadiumBorder(),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
            ),
            if (_mapVisible && provider.spots.isNotEmpty) ...[
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 2, 4, 12),
                      child: SectionTitle(
                        'Peta spot kampus',
                        icon: Icons.layers_outlined,
                      ),
                    ),
                    CampusSpotMap(
                      spots: provider.spots,
                      isDemo: provider.isDemo,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Warna menunjukkan aktivitas tercatat, bukan tingkat lapar kucing.',
                      style: TextStyle(fontSize: 10, color: MeowStyle.brown),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SectionTitle(
              'Spot resmi kampus',
              trailing: MeowPill('${spots.length} spot'),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (provider.errorMessage != null)
              FeedingMessage(
                provider.errorMessage!,
                action: 'Coba lagi',
                onAction: () => provider.fetchSpots(refresh: true),
              ),
            if (!provider.isLoading &&
                provider.errorMessage == null &&
                spots.isEmpty)
              const FeedingMessage(
                'Tidak ada spot yang sesuai. Coba kata pencarian atau filter lainnya.',
              ),
            for (final spot in spots) ...[
              GlassCard(
                padding: const EdgeInsets.all(14),
                onTap: () => context.push('/feeding/spot/${spot.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        SpotPhoto(spot, isDemo: provider.isDemo, height: 172),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: MeowPill(
                            spot.isActive ? 'Spot aktif' : 'Sementara ditutup',
                            color: Colors.white,
                            foreground: spot.isActive
                                ? MeowStyle.green
                                : MeowStyle.brown,
                            icon: spot.isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_outline,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            tooltip: provider.isFavorite(spot.id)
                                ? 'Hapus dari favorit'
                                : 'Simpan spot',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () => provider.toggleFavorite(spot.id),
                            icon: Icon(
                              provider.isFavorite(spot.id)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_outline_rounded,
                              color: MeowStyle.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spot.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (spot.distanceLabel != null)
                          MeowPill(
                            spot.distanceLabel!,
                            color: MeowStyle.lavender,
                            foreground: MeowStyle.brown,
                            icon: Icons.near_me_outlined,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      spot.locationName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MeowStyle.brown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: MeowStyle.orangeDark,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            spot.lastFedSentence,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MeowStyle.orangeDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: MeowPill(
                            spot.activityLabel,
                            color: spot.hasLowActivity
                                ? MeowStyle.peach
                                : MeowStyle.lilac,
                            foreground: spot.hasLowActivity
                                ? MeowStyle.orangeDark
                                : MeowStyle.brown,
                            icon: Icons.pets_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          spot.verifiedCount14Days == null
                              ? 'Belum tersedia'
                              : '${spot.verifiedCount14Days}x / 14 hari',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: MeowStyle.orangeDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
