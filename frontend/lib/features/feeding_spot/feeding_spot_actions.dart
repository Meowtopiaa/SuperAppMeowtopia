import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/hub/cat_action_registry.dart';

/// Mendaftarkan tombol aksi Hub Kucing milik modul Adopt Feeding Spot (`feeding.start`)
/// sesuai spesifikasi PRD Bagian 10.2 (`MEOW-18`).
void registerFeedingSpotActions() {
  CatActionRegistry.register(
    CatActionSpec(
      id: 'feeding.start',
      label: 'Beri Makan di Spot',
      icon: Icons.restaurant_rounded,
      onTap: (context, catId) {
        context.push('/feeding');
      },
    ),
  );
}

