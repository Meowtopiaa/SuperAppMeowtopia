import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/utils/date_labels.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../logic/feeding_spot_provider.dart';
import 'feeding_widgets.dart';

class FeedingSpotDetailPage extends StatefulWidget {
  const FeedingSpotDetailPage({super.key, required this.spotId});
  final String spotId;
  @override
  State<FeedingSpotDetailPage> createState() => _FeedingSpotDetailPageState();
}

class _FeedingSpotDetailPageState extends State<FeedingSpotDetailPage> {
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
    final spot = provider.spotById(widget.spotId);
    if (spot == null) {
      return MeowPage(
        title: 'Detail Spot',
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : FeedingMessage(
                  provider.errorMessage ??
                      'Spot tidak ditemukan atau sudah dinonaktifkan.',
                  action: 'Kembali ke daftar spot',
                  onAction: () => context.go('/feeding'),
                ),
        ),
      );
    }
    return MeowPage(
      title: 'Detail Spot',
      bottom: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Salin lokasi spot',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '${spot.name}\n${spot.locationName}\nhttps://maps.google.com/?q=${spot.latitude},${spot.longitude}',
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lokasi spot disalin.')),
                );
              }
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MeowButton(
              label: spot.isActive
                  ? 'Pindai QR Spot'
                  : 'Spot sementara ditutup',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: spot.isActive
                  ? () => context.push('/feeding/scan?spot_id=${spot.id}')
                  : null,
            ),
          ),
        ],
      ),
      child: ListView(
        padding: MeowPage.scrollPadding(context, top: 0, bottom: 20),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    IconBubble(Icons.radar_rounded, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peta Aktivitas Spot',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Catatan 14 hari terakhir',
                            style: TextStyle(
                              color: MeowStyle.brown,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MeowPill(
                      'Spot resmi',
                      foreground: MeowStyle.green,
                      color: Color(0xFFC8FBE6),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CampusSpotMap(
                  spots: provider.spots,
                  selectedId: spot.id,
                  isDemo: provider.isDemo,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lokasi spot, bukan pelacakan relawan',
                        style: TextStyle(fontSize: 10, color: MeowStyle.brown),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (dialog) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Peta spot kampus',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Tutup peta',
                                      onPressed: () => Navigator.pop(dialog),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ],
                                ),
                                InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 3,
                                  child: CampusSpotMap(
                                    spots: provider.spots,
                                    selectedId: spot.id,
                                    isDemo: provider.isDemo,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Cubit untuk memperbesar skema lokasi.',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_full_rounded, size: 13),
                      label: const Text(
                        'Perbesar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SpotPhoto(spot, isDemo: provider.isDemo),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: MeowPill(
                        spot.isActive ? 'Aktif dipantau' : 'Sementara ditutup',
                        color: Colors.white,
                        foreground: spot.isActive
                            ? MeowStyle.green
                            : MeowStyle.brown,
                        icon: Icons.circle,
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        tooltip: provider.isFavorite(spot.id)
                            ? 'Hapus favorit'
                            : 'Simpan spot',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => provider.toggleFavorite(spot.id),
                        icon: Icon(
                          provider.isFavorite(spot.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: MeowStyle.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  spot.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spot.distanceLabel != null
                      ? '${spot.locationName} · ${spot.distanceLabel} · Shelter kampus'
                      : '${spot.locationName} · Shelter kampus',
                  style: const TextStyle(
                    fontSize: 14,
                    color: MeowStyle.brown,
                    height: 1.5,
                  ),
                ),
                if (!spot.isActive) ...[
                  const SizedBox(height: 12),
                  const MeowPill(
                    'Pengajuan baru dinonaktifkan sementara',
                    color: MeowStyle.peach,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBubble(Icons.pets_rounded, size: 36),
                      const SizedBox(height: 14),
                      Text(
                        spot.verifiedCount14Days == null
                            ? '—'
                            : '${spot.verifiedCount14Days}x',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Aktivitas terverifikasi',
                        style: TextStyle(fontSize: 12, color: MeowStyle.brown),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '14 hari terakhir',
                        style: TextStyle(
                          fontSize: 11,
                          color: MeowStyle.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBubble(
                        Icons.schedule_rounded,
                        color: MeowStyle.lilac,
                        foreground: MeowStyle.ink,
                        size: 36,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        relativeTime(spot.lastFedAt),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spot.lastFedSentence,
                        style: const TextStyle(
                          fontSize: 11,
                          color: MeowStyle.brown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        spot.aggregateUpdatedAt == null
                            ? 'Agregat belum tersedia'
                            : 'Data ${relativeTime(spot.aggregateUpdatedAt)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: MeowStyle.brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const GlassCard(
            color: Color(0xFFFFE8DC),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(
                  Icons.restaurant_rounded,
                  color: MeowStyle.orange,
                  foreground: Colors.white,
                  size: 36,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips teman kucing',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Periksa mangkuk terlebih dahulu. Gunakan pakan yang sesuai, jaga kebersihan, dan dokumentasikan kegiatanmu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: MeowStyle.orangeDark,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (provider.isDemo) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  const SectionTitle(
                    'Kucing pernah tercatat',
                    icon: Icons.volunteer_activism_outlined,
                    trailing: MeowPill('Contoh'),
                  ),
                  const SizedBox(height: 14),
                  for (final cat in [
                    ('Oyen', 'Tabby oranye · ramah', 'oyen.png'),
                    ('Mochi', 'Calico · suka tidur siang', 'mochi.png'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/figma/${cat.$3}',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          cat.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          cat.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            color: MeowStyle.brown,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: MeowStyle.orange,
                        ),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (dialog) => AlertDialog(
                            title: Text('${cat.$1} · data contoh'),
                            content: const Text(
                              'Profil kucing berasal dari layanan identifikasi bersama. Buka fitur Kenali Kucing untuk melihat data yang tersedia.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialog);
                                  context.go('/identify');
                                },
                                child: const Text('Kenali Kucing'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('Fasilitas spot ini'),
                  SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MeowPill(
                        'Mangkuk air bersih',
                        icon: Icons.water_drop_outlined,
                      ),
                      MeowPill('Atap pelindung', icon: Icons.roofing_rounded),
                      MeowPill(
                        'Area terawat',
                        icon: Icons.cleaning_services_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Informasi fasilitas contoh untuk pratinjau.',
                    style: TextStyle(fontSize: 10, color: MeowStyle.brown),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Jumlah aktivitas tidak menunjukkan jumlah pakan yang dimakan atau tingkat lapar kucing.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: MeowStyle.brown, height: 1.5),
          ),
        ],
      ),
    );
  }
}
