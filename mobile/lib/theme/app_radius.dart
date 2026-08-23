import 'package:flutter/material.dart';

/// Centralized border radius tokens for FakeDrugChecker.
/// Restrained, subtle, and professional (avoiding excessively rounded bubbles).
abstract class AppRadius {
  static const double smVal = 6.0;
  static const double mdVal = 10.0;
  static const double lgVal = 14.0;
  static const double xlVal = 18.0;
  static const double fullVal = 999.0;

  static const Radius smRadius = Radius.circular(smVal);
  static const Radius mdRadius = Radius.circular(mdVal);
  static const Radius lgRadius = Radius.circular(lgVal);
  static const Radius xlRadius = Radius.circular(xlVal);

  static const BorderRadius sm = BorderRadius.all(smRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);
  static const BorderRadius xl = BorderRadius.all(xlRadius);
  static const BorderRadius pill = BorderRadius.all(Radius.circular(fullVal));
}
