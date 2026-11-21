import 'package:flutter/material.dart';

import 'walking_cat_loader.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final bool onDark;
  final bool compact;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 156,
    this.onDark = false,
    this.compact = false,
  });

  String get _resolvedLabel {
    final raw = message?.trim();
    if (raw == null || raw.isEmpty) return 'Memuat';
    final cleaned = raw.replaceFirst(RegExp(r'\.+$'), '').trim();
    return cleaned.isEmpty ? 'Memuat' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: WalkingCatLoader(
        label: _resolvedLabel,
        size: size,
        onDark: onDark,
        compact: compact,
      ),
    );
  }
}
