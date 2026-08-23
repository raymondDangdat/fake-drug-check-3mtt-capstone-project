import 'package:flutter/material.dart';

/// Centralized color palette for FakeDrugChecker.
/// Inspired by trusted clinical and healthcare digital products in Nigeria.
abstract class AppColors {
  // Primary Healthcare Palette
  static const Color primary = Color(0xFF0B6B48); // Deep Medical Forest Green
  static const Color primaryDark = Color(0xFF064E35); // Deep Pine
  static const Color primaryLight = Color(0xFF10B981); // Emerald Green
  static const Color primarySurface = Color(0xFFECFDF5); // Mint Tint
  static const Color primaryBorder = Color(0xFFA7F3D0); // Soft Mint Border

  // Secondary & Accents
  static const Color accent = Color(0xFF0284C7); // Clinical Blue / Cyan
  static const Color accentLight = Color(0xFFE0F2FE); // Soft Blue Surface
  static const Color accentDark = Color(0xFF0369A1); // Deep Slate Blue

  // Neutrals & Backgrounds (Light Healthcare Theme)
  static const Color background = Color(0xFFF8FAFC); // Clean Off-White Canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Light Gray Surface
  static const Color border = Color(0xFFE2E8F0); // Subtle Divider & Card Border
  static const Color borderStrong = Color(0xFFCBD5E1); // Focused/Active Border

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate Charcoal
  static const Color textSecondary = Color(0xFF475569); // Slate Gray Body Text
  static const Color textMuted = Color(0xFF94A3B8); // Muted Captions & Placeholders
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on Primary Green

  // Verdict & Status: Low Risk / Appears Genuine
  static const Color genuine = Color(0xFF059669); // Deep Emerald
  static const Color genuineSurface = Color(0xFFECFDF5); // Light Mint
  static const Color genuineBorder = Color(0xFFA7F3D0); // Mint Border

  // Verdict & Status: Suspicious / High Risk
  static const Color suspicious = Color(0xFFDC2626); // Crimson Red
  static const Color suspiciousSurface = Color(0xFFFFF1F2); // Soft Rose Surface
  static const Color suspiciousBorder = Color(0xFFFECDD3); // Rose Border

  // Verdict & Status: Caution / Amber Warning
  static const Color warning = Color(0xFFD97706); // Warm Amber
  static const Color warningSurface = Color(0xFFFFFBEB); // Amber Tint
  static const Color warningBorder = Color(0xFFFDE68A); // Soft Amber Border

  // Status Indicator
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFFEF4444);
  static const Color checking = Color(0xFFF59E0B);

  // Dark Mode Overrides (Optional / High Contrast)
  static const Color darkBackground = Color(0xFF0B1320);
  static const Color darkSurface = Color(0xFF131F33);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
}
