import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_feature.dart';
import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/feature_shortcuts.dart';
import '../../../core/widgets/meow_widgets.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) => MeowPage(
    back: false,
    child: ListView(
      padding: MeowPage.scrollPadding(context),
      children: [
        const Text(
          'Jelajahi Meowtopia',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Setiap kepedulian punya tempatnya.',
          style: TextStyle(color: MeowStyle.brown, fontSize: 13),
        ),
        const SizedBox(height: 24),
        const FeatureShortcuts(),
        const SizedBox(height: 30),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FeatureArtwork(
                feature: AppFeature.identification,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Kenalan dulu, yuk.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pindai QR di kalung untuk mengenali kucing kampus. Kalung tidak terbaca? Coba identifikasi melalui foto atau ciri fisik.',
                style: TextStyle(
                  fontSize: 13,
                  color: MeowStyle.brown,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 20),
              MeowButton(
                label: 'Pindai kucing',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () => context.go('/identify'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          color: MeowStyle.lilac,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'Lanjutkan kepedulianmu',
                icon: Icons.volunteer_activism_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                'Semua riwayatmu, dari memberi makan sampai adopsi, tersedia di Aktivitas.',
                style: TextStyle(
                  fontSize: 13,
                  color: MeowStyle.brown,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => context.go('/activity'),
                child: const Text('Lihat aktivitas saya →'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
