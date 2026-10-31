import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_feature.dart';
import '../theme/meow_style.dart';

/// Compact app-wide shortcuts. The raised artwork is drawn locally in Flutter.
class FeatureShortcuts extends StatelessWidget {
  const FeatureShortcuts({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = (constraints.maxWidth / 5 - 12).clamp(44.0, 62.0);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final feature in AppFeature.values)
            Expanded(
              child: Semantics(
                button: true,
                label: feature.label,
                child: InkWell(
                  key: ValueKey('feature-${feature.name}'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go(feature.route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: Column(
                      children: [
                        FeatureArtwork(feature: feature, size: size),
                        const SizedBox(height: 10),
                        Text(
                          feature.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class FeatureArtwork extends StatelessWidget {
  const FeatureArtwork({super.key, required this.feature, this.size = 58});

  final AppFeature feature;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Color.lerp(feature.color, MeowStyle.ink, .22)!;
    final light = Color.lerp(feature.color, Colors.white, .38)!;
    final symbolSize = size * .57;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            right: 4,
            bottom: -2,
            height: size * .38,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: dark.withValues(alpha: .25),
                borderRadius: BorderRadius.circular(size * .3),
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withValues(alpha: .22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * .31),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, feature.color, dark],
                  stops: const [0, .6, 1],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .6),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            left: 7,
            right: 7,
            height: size * .34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * .25),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: .25),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: -.10,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final offset in [
                    const Offset(3, 4),
                    const Offset(2, 3),
                    const Offset(1, 2),
                  ])
                    Transform.translate(
                      offset: offset,
                      child: Icon(
                        feature.icon,
                        size: symbolSize,
                        color: dark.withValues(alpha: .5),
                      ),
                    ),
                  Icon(
                    feature.icon,
                    size: symbolSize,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: dark.withValues(alpha: .25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
