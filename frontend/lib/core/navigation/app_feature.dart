import 'package:flutter/material.dart';

import '../theme/meow_style.dart';

enum AppFeature {
  identification(
    'Kenali Kucing',
    '/identify',
    Icons.pets_rounded,
    MeowStyle.teal,
  ),
  feeding('Spot Makan', '/feeding', Icons.rice_bowl_rounded, MeowStyle.orange),
  hunter(
    'Cat Hunter',
    '/hunter',
    Icons.catching_pokemon_rounded,
    MeowStyle.violet,
  ),
  adoption('Adopsi', '/adoption', Icons.favorite_rounded, MeowStyle.rose),
  incident(
    'Lapor Insiden',
    '/incidents',
    Icons.health_and_safety_rounded,
    MeowStyle.blue,
  );

  const AppFeature(this.label, this.route, this.icon, this.color);

  final String label;
  final String route;
  final IconData icon;
  final Color color;

  Color get foreground => Color.lerp(color, MeowStyle.ink, .45)!;

  String get coverAsset =>
      'assets/images/figma/${switch (this) {
        AppFeature.feeding => 'feeding-proof-summary.png',
        AppFeature.identification || AppFeature.adoption => 'ginger-cat-hero.png',
        AppFeature.hunter => 'feeding-shelter.png',
        AppFeature.incident => 'spot-scan-background.png',
      }}';
}
