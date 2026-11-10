import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Accents
  static const Color primary = Color(0xFFF26A1B); // Vibrant Cat Orange
  static const Color primaryLight = Color(0xFFFF7A00); // Bright Orange Hover/Active
  static const Color primaryPeach = Color(0xFFFFF3EB); // Soft Peach
  static const Color primaryPeachDark = Color(0xFF9A3412); // Deep Terracotta for text on peach

  // Canvas & Surfaces
  static const Color background = Color(0xFFF8F9FA); // Soft Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White Card
  static const Color surfaceSubtle = Color(0xFFF4F4F5); // Gray-Blue Callout Container
  static const Color surfaceHover = Color(0xFFF0EDF1);

  // Borders
  static const Color borderCard = Color(0xFFEDEDED); // Subtle card outline
  static const Color borderSubtle = Color(0xFFEFEFEF);
  static const Color borderInteractive = Color(0xFFE4E4E7);

  // Typography
  static const Color textPrimary = Color(0xFF18181B); // Charcoal Black
  static const Color textSecondary = Color(0xFF71717A); // Muted Gray
  static const Color textTertiary = Color(0xFFA1A1AA);

  // Gamification & Semantics (Timing Bar & Health status)
  static const Color sweetSpotGreen = Color(0xFF16A34A); // Success / Sweet Spot
  static const Color sweetSpotGreenLight = Color(0xFF22C55E);
  static const Color sweetSpotGreenBg = Color(0xFFDCFCE7);

  static const Color goodYellow = Color(0xFFEAB308); // Good Zone
  static const Color goodYellowBg = Color(0xFFFEF9C3);

  static const Color missRed = Color(0xFFDC2626); // Miss Zone
  static const Color missRedLight = Color(0xFFEF4444);
  static const Color missRedBg = Color(0xFFFEE2E2);

  // Catbook Polaroid Tone
  static const Color polaroidCard = Color(0xFFFFFDF5); // Warm Cream Notebook
}
