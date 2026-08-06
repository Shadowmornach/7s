import 'package:flutter/material.dart';

/// Centralized color palette for the 7s mobile design system.
/// Implements exact brand colors extracted from the business card:
/// - Primary Orange: #E8772A, Pressed/Dark: #C25F1B
/// - Structural Dark (Espresso): #2B1710
/// - Success: #2E9E5B | Danger/SOS: #D64545 | Warning/Pending: #D9A441
/// - Light bg: Warm Off-White (#FAF7F4)
/// - Dark mode bg: #1C0F0A
class AppColors {
  // Brand Orange Palette
  static const Color primary = Color(0xFFE8772A); // Primary Orange
  static const Color primaryDark = Color(0xFFC25F1B); // Pressed/Dark Variant
  static const Color primaryLight = Color(0xFFF99D58); // Light Orange
  static const Color accent = Color(0xFFE8772A); // Accent Orange
  static const Color primarySurface = Color(0xFFFFF7F2); // Warm Orange Tint
  static const Color primaryBorder = Color(0xFFFCD3B0); // Soft Orange Border

  // Structural Dark Palette (Espresso)
  static const Color espresso = Color(0xFF2B1710); // Structural Dark Espresso
  static const Color espressoDark = Color(0xFF1C0F0A); // Dark mode background

  // Neutral Palette - Light Mode
  static const Color background = Color(0xFFFAF7F4); // Warm off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color textPrimary = Color(0xFF2B1710); // Structural Dark Espresso
  static const Color textSecondary = Color(0xFF6B5850); // Warm Espresso body text
  static const Color textMuted = Color(0xFF9E8B83); // Subtle muted text
  static const Color border = Color(0xFFEFE8E2); // Warm subtle divider

  // Neutral Palette - Dark Mode
  static const Color backgroundDark = Color(0xFF1C0F0A); // Dark mode background
  static const Color surfaceDark = Color(0xFF2B1710); // Espresso card surface
  static const Color textPrimaryDark = Color(0xFFFAF7F4); // Warm off-white
  static const Color textSecondaryDark = Color(0xFFD4C8C2); // Light warm body text
  static const Color borderDark = Color(0xFF422E25); // Dark espresso divider

  // Semantic Status Colors
  static const Color secondary = Color(0xFFFFFFFF); // White
  static const Color success = Color(0xFF2E9E5B); // Success Green
  static const Color warning = Color(0xFFD9A441); // Warning Amber
  static const Color alert = Color(0xFFD64545); // Danger/SOS Red
  static const Color info = Color(0xFFE8772A); // Info Accent

  // Glassmorphism overlays
  static Color glassLight = Colors.white.withValues(alpha: 0.85);
  static Color glassDark = const Color(0xFF2B1710).withValues(alpha: 0.85);
}
