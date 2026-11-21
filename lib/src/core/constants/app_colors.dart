import 'package:flutter/material.dart';

/// Centralized brand color tokens for व्यवहार (Vyavahaar)
class AppColors {
  AppColors._();

  // Primary Brand Identity
  static const Color deepNavy = Color(0xFF1F3352);
  static const Color terracotta = Color(0xFFC05A2B);
  static const Color warmCream = Color(0xFFF4EFE7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Financial Semantics (Strictly Separated Mila & Diya)
  static const Color milaGreen = Color(0xFF15803D);
  static const Color milaGreenSoft = Color(0xFFE2F5EB);
  static const Color diyaRed = Color(0xFFB91C1C);
  static const Color diyaRedSoft = Color(0xFFFCE9E7);

  // Status Colors
  static const Color plannedAmber = Color(0xFFD97706);
  static const Color plannedAmberSoft = Color(0xFFFEF3C7);
  static const Color cancelledGrey = Color(0xFF64748B);
  static const Color cancelledGreySoft = Color(0xFFF1F5F9);

  // Neutral Typography & Borders
  static const Color textPrimary = Color(0xFF1F3352);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Elevation & Shadows
  static const Color shadow = Color(0x1F0F172A);

  // Convenience & UI Tokens
  static const Color white = surfaceWhite;
  static const Color cardBorder = borderLight;
  static const Color mutedText = textMuted;
  static const Color darkSlate = deepNavy;
  static const Color cardBackground = surfaceWhite;
  static const Color background = warmCream;
}
