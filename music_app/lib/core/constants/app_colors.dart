// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// App color constants - Modern Light Blue theme
class AppColors {
  AppColors._();

  // Primary accent colors (Light Blue theme)
  static const Color primary = Color(0xFF42A5F5);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1E88E5);
  static const Color primaryMuted = Color(0xFF42A5F533);

  // SkyBlue colors (main app color)
  static const Color skyBlue = Color(0xFF42A5F5);
  static const Color skyBlueLight = Color(0xFF64B5F6);
  static const Color skyBlueDark = Color(0xFF1E88E5);
  static const Color skyBlueAccent = Color(0xFF29B6F6);

  // Dark theme backgrounds (Spotify-inspired)
  static const Color darkBg = Color(0xFF121212);
  static const Color darkBgLight = Color(0xFF181818);
  static const Color darkBgLighter = Color(0xFF282828);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkElevated = Color(0xFF2A2A2A);

  // Light theme backgrounds
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFF0F0F0);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);
  static const Color textDark = Color(0xFF191414);
  static const Color textDarkSecondary = Color(0xFF535353);

  // Accent colors
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentPurple = Color(0xFF9B59B6);
  static const Color accentBlue = Color(0xFF3498DB);
  static const Color accentOrange = Color(0xFFE67E22);
  static const Color accentRed = Color(0xFFE74C3C);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF42A5F5);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyBlueGradient = LinearGradient(
    colors: [skyBlue, skyBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [darkBg, darkBgLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF42A5F5), Color(0xFF191414)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.6],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass effect colors
  static Color glassWhite = Colors.white.withOpacity(0.1);
  static Color glassDark = Colors.black.withOpacity(0.3);
  static Color glassOverlay = Colors.white.withOpacity(0.05);
}
