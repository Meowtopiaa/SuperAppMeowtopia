import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/hub/cat_action_registry.dart';

/// Registrasi aksi Hub Profil Kucing untuk Modul Adopsi (PRD §10.1, id: 'adoption.apply')
/// Dipanggil di app startup atau oleh register_actions.dart
void registerAdoptionActions() {
  CatActionRegistry.register(
    CatActionSpec(
      id: 'adoption.apply',
      label: 'Ajukan Adopsi',
      icon: Icons.favorite_rounded,
      onTap: (context, catId) {
        context.push('/adoption/apply?cat_id=$catId');
      },
    ),
  );
}

