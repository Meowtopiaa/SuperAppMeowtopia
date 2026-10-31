import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Meowtopia';
  static const String appTagline = 'Campus Cat Ecosystem Super App';

  // Base API configuration (Defaults to local Laravel dev server)
  // For Android Emulator use 'http://10.0.2.2:8000/api/v1'
  // For Real Device / Desktop use your local LAN IP or 'http://127.0.0.1:8000/api/v1'
  static const String apiBaseUrl = String.fromEnvironment(
    'MEOWTOPIA_API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  static const bool demoMode = bool.fromEnvironment(
    'MEOWTOPIA_DEMO',
    defaultValue: true,
  );

  // Storage Keys
  static const String keyAuthToken = 'meowtopia_auth_token';
  static const String keyUserData = 'meowtopia_user_data';

  // Branding Palette
  static const Color primaryColor = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFD6581F);
  static const Color primaryLight = Color(0xFFFFECE2);
  static const Color secondaryColor = Color(0xFF2C3E50); // Deep slate
  static const Color accentTeal = Color(0xFF2EC4B6);
  static const Color backgroundColor = Color(0xFFFAF8FF);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF584237);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
}
