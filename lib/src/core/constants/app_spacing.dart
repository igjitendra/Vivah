import 'package:flutter/material.dart';

/// Centralized 8dp/4dp baseline grid spacing tokens
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Screen padding clearing the floating pill tab bar on mobile
  static const double floatingTabBottomPadding = 110.0;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 14.0;
  static const double card = 16.0;
  static const double chip = 24.0;
  static const double pillBar = 36.0;

  static const BorderRadius roundedCard = BorderRadius.all(Radius.circular(card));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(pillBar));
  static const BorderRadius roundedChip = BorderRadius.all(Radius.circular(chip));
}
