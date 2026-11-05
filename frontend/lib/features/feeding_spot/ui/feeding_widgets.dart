import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/meow_style.dart';
import '../../../core/widgets/cinematic_card.dart';
import '../../../core/widgets/meow_widgets.dart';
import '../data/feeding_spot_model.dart';

class SpotPhoto extends StatelessWidget {
  const SpotPhoto(
    this.spot, {
    super.key,
    required this.isDemo,
    this.height = 190,
  });
  final FeedingSpotModel spot;
  final bool isDemo;
  final double height;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: height,
      color: MeowStyle.lilac,
      alignment: Alignment.center,
      child: const Icon(
        Icons.cottage_outlined,
        size: 48,
        color: MeowStyle.orangeDark,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: isDemo
          ? Image.asset(
              spot.imageAsset,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : spot.imageUrl == null
          ? fallback
          : Image.network(
              spot.imageUrl!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class FeedingSpotPreviewCard extends StatelessWidget {
  const FeedingSpotPreviewCard({
    super.key,
    required this.spot,
    required this.isDemo,
  });

  final FeedingSpotModel spot;
  final bool isDemo;

  @override
  Widget build(BuildContext context) => CinematicCard(
    image: isDemo
        ? AssetImage(spot.imageAsset)
        : spot.imageUrl == null
        ? null
        : NetworkImage(spot.imageUrl!),
    imageOnLeft: true,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    onTap: () => context.push('/feeding/spot/${spot.id}'),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          SizedBox(width: constraints.maxWidth * .25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spot.verifiedCount14Days == null
                      ? 'Aktivitas belum tersedia'
                      : '${spot.verifiedCount14Days} aktivitas / 14 hari',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCFD3DD),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spot.lastFedSentence,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFE5EAEF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  spot.activityLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MeowStyle.peach,
                    fontWeight: FontWeight.w500,
                  ),
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
    ),
  );
}

class CampusSpotMap extends StatelessWidget {
  const CampusSpotMap({
    super.key,
    required this.spots,
    this.selectedId,
    required this.isDemo,
  });
  final List<FeedingSpotModel> spots;
  final String? selectedId;
  final bool isDemo;
  @override
  Widget build(BuildContext context) {
    FeedingSpotModel? selectedSpot;
    if (selectedId != null) {
      for (final s in spots) {
        if (s.id == selectedId) {
          selectedSpot = s;
          break;
        }
      }
    } else if (spots.isNotEmpty) {
      selectedSpot = spots.first;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 208,
        decoration: BoxDecoration(
          color: MeowStyle.lavender,
          border: Border.all(color: MeowStyle.lilac),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .8,
                child: SvgPicture.asset(
                  'assets/icons/figma/campus-map.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: MeowPill(
                isDemo
                    ? 'Peta ilustrasi · data contoh'
                    : 'Skema lokasi · bukan GPS',
                color: Colors.white,
              ),
            ),
            for (var i = 0; i < spots.length && i < 4; i++)
              Positioned(
                left:
                    [0.46, .15, .74, .68][i] *
                    (MediaQuery.sizeOf(context).width.clamp(280, 720) - 80),
                top: [84.0, 65.0, 111.0, 48.0][i],
                child: Semantics(
                  label: '${spots[i].name} · ${spots[i].lastFedSentence}',
                  button: true,
                  child: IconButton(
                    tooltip: '${spots[i].name}\n${spots[i].lastFedSentence}',
                    onPressed: () =>
                        context.push('/feeding/spot/${spots[i].id}'),
                    style: IconButton.styleFrom(
                      backgroundColor: selectedId == spots[i].id
                          ? MeowStyle.orange
                          : spots[i].isActive
                          ? MeowStyle.green
                          : MeowStyle.slate,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    icon: const Icon(Icons.pets_rounded, size: 19),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              left: 10,
              child: MeowPill(
                selectedSpot != null
                    ? selectedSpot.lastFedSentence
                    : 'Aktivitas terverifikasi · 14 hari',
                color: Colors.white,
                icon: Icons.schedule_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedingMessage extends StatelessWidget {
  const FeedingMessage(this.message, {super.key, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      children: [
        const IconBubble(Icons.info_outline_rounded),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: MeowStyle.brown, height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          MeowButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}
