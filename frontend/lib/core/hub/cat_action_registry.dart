import 'package:flutter/material.dart';

class CatActionSpec {
  final String id; // e.g. 'game.encounter', 'adoption.apply', 'incident.report', 'feeding.start'
  final String label;
  final IconData icon;
  final void Function(BuildContext context, String catId) onTap;

  const CatActionSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class CatActionRegistry {
  static final Map<String, CatActionSpec> _items = {};

  static void register(CatActionSpec spec) => _items[spec.id] = spec;

  static CatActionSpec? byId(String id) => _items[id];

  static List<CatActionSpec> all() => _items.values.toList();
}

