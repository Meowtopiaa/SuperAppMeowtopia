import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'cat_action_registry.dart';

void registerDefaultCatActions() {
  // 1. Encounter Action (Cat Hunter)
  CatActionRegistry.register(
    CatActionSpec(
      id: 'game.encounter',
      label: 'Dekati & Elus',
      icon: Icons.pets,
      onTap: (context, catId) {
        context.push('/cat-hunter/encounter', extra: {'cat_id': catId});
      },
    ),
  );

  // 2. Adoption Action (Cat Adoption)
  CatActionRegistry.register(
    CatActionSpec(
      id: 'adoption.apply',
      label: 'Ajukan Adopsi',
      icon: Icons.favorite,
      onTap: (context, catId) {
        context.push('/cat-adoption/apply', extra: {'cat_id': catId});
      },
    ),
  );

  // 3. Emergency Incident Action (Incident Report)
  CatActionRegistry.register(
    CatActionSpec(
      id: 'incident.report',
      label: 'Laporkan Kondisi/Insiden',
      icon: Icons.warning_amber_rounded,
      onTap: (context, catId) {
        context.push('/incident-report/create', extra: {'cat_id': catId});
      },
    ),
  );

  // 4. Feeding Spot Action
  CatActionRegistry.register(
    CatActionSpec(
      id: 'feeding.start',
      label: 'Beri Makan di Titik Spot',
      icon: Icons.restaurant,
      onTap: (context, catId) {
        context.push('/feeding-spots');
      },
    ),
  );
}

