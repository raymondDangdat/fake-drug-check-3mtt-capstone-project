import 'package:flutter/material.dart';

/// Centralized spacing tokens for consistent padding, margins, and gaps.
abstract class AppSpacing {
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Insets
  static const EdgeInsets screenPaddingMobile = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
  static const EdgeInsets screenPaddingDesktop = EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(20.0);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0);
}
