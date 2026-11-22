import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/localization/app_localizations.dart';

/// Presentation theme for the App Logo
enum AppLogoTheme {
  /// Dark canvas: Warm Cream text & symbols on deep navy
  darkCanvas,

  /// Light canvas: Deep Navy text & symbols on cream/white
  lightCanvas,

  /// Brand lockup with container card
  contained,
}

/// Layout variant for AppLogo
enum AppLogoVariant {
  /// Vertical stack: Symbol top, Wordmark center, Tagline bottom (ideal for Splash/Onboarding)
  vertical,

  /// Horizontal lockup: Symbol left, Wordmark & Tagline right (ideal for AppBars)
  horizontal,

  /// Standalone Symbol
  symbolOnly,

  /// Compact header lockup
  compactHeader,
}

/// Standalone Vector & Asset Brand Symbol for व्यवहार (Vyavahaar)
/// Renders the Open Ledger (पारंपरिक बही) + Integrated Verified Checkmark (✓).
class AppSymbol extends StatelessWidget {
  final double size;
  final Color? pageColor;
  final Color? checkmarkColor;
  final Color? accentColor;
  final bool useAssetFallback;

  const AppSymbol({
    super.key,
    this.size = 48.0,
    this.pageColor,
    this.checkmarkColor,
    this.accentColor,
    this.useAssetFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePageColor = pageColor ?? AppColors.warmCream;
    final effectiveCheckColor = checkmarkColor ?? AppColors.terracotta;
    final effectiveAccentColor = accentColor ?? AppColors.terracotta;

    return SizedBox(
      width: size,
      height: size,
      child: useAssetFallback
          ? Image.asset(
              'assets/brand/vyavahaar-symbol-48.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                size: Size(size, size),
                painter: VyavahaarSymbolPainter(
                  pageColor: effectivePageColor,
                  checkmarkColor: effectiveCheckColor,
                  accentColor: effectiveAccentColor,
                ),
              ),
            )
          : CustomPaint(
              size: Size(size, size),
              painter: VyavahaarSymbolPainter(
                pageColor: effectivePageColor,
                checkmarkColor: effectiveCheckColor,
                accentColor: effectiveAccentColor,
              ),
            ),
    );
  }
}

/// Vector Painter rendering the official Vyavahaar brand geometry
class VyavahaarSymbolPainter extends CustomPainter {
  final Color pageColor;
  final Color checkmarkColor;
  final Color accentColor;

  const VyavahaarSymbolPainter({
    required this.pageColor,
    required this.checkmarkColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Original SVG coordinate space: 512x512
    final double scale = size.width / 512.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Left Page Base
    final leftPagePaint = Paint()
      ..color = pageColor
      ..style = PaintingStyle.fill;
    final leftPage = Path()
      ..moveTo(252, 165)
      ..cubicTo(215, 152, 168, 152, 126, 172)
      ..cubicTo(118, 176, 112, 184, 112, 194)
      ..cubicTo(112, 238, 116, 284, 122, 316)
      ..cubicTo(124, 326, 132, 332, 142, 332)
      ..cubicTo(178, 330, 218, 340, 252, 358)
      ..close();
    canvas.drawPath(leftPage, leftPagePaint);

    // 2. Left Page Layer (Terracotta Accent)
    final leftAccentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final leftAccent = Path()
      ..moveTo(252, 196)
      ..cubicTo(222, 186, 185, 186, 150, 202)
      ..cubicTo(144, 205, 140, 211, 140, 218)
      ..cubicTo(140, 248, 144, 282, 148, 304)
      ..cubicTo(150, 311, 156, 316, 163, 316)
      ..cubicTo(192, 314, 224, 322, 252, 336)
      ..close();
    canvas.drawPath(leftAccent, leftAccentPaint);

    // 3. Right Page Base
    final rightPagePaint = Paint()
      ..color = pageColor
      ..style = PaintingStyle.fill;
    final rightPage = Path()
      ..moveTo(260, 165)
      ..cubicTo(297, 152, 344, 152, 386, 172)
      ..cubicTo(394, 176, 400, 184, 400, 194)
      ..cubicTo(400, 238, 396, 284, 390, 316)
      ..cubicTo(388, 326, 380, 332, 370, 332)
      ..cubicTo(334, 330, 294, 340, 260, 358)
      ..close();
    canvas.drawPath(rightPage, rightPagePaint);

    // 4. Spine Crease
    final spinePaint = Paint()
      ..color = const Color(0x4D1F3352)
      ..style = PaintingStyle.fill;
    final spine = Path()
      ..moveTo(254, 162)
      ..cubicTo(255, 220, 255, 300, 254, 362)
      ..lineTo(260, 362)
      ..cubicTo(259, 300, 259, 220, 260, 162)
      ..close();
    canvas.drawPath(spine, spinePaint);

    // 5. Integrated Verified Checkmark (Terracotta)
    final checkmarkPaint = Paint()
      ..color = checkmarkColor
      ..style = PaintingStyle.fill;
    final checkmark = Path()
      ..moveTo(198, 254)
      ..lineTo(242, 298)
      ..cubicTo(248, 304, 258, 304, 264, 298)
      ..lineTo(374, 188)
      ..cubicTo(380, 182, 380, 172, 374, 166)
      ..lineTo(360, 152)
      ..cubicTo(354, 146, 344, 146, 338, 152)
      ..lineTo(253, 237)
      ..lineTo(224, 208)
      ..cubicTo(218, 202, 208, 202, 202, 208)
      ..lineTo(198, 212)
      ..cubicTo(192, 218, 192, 228, 198, 234)
      ..close();
    canvas.drawPath(checkmark, checkmarkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VyavahaarSymbolPainter oldDelegate) {
    return oldDelegate.pageColor != pageColor ||
        oldDelegate.checkmarkColor != checkmarkColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Complete Official Brand Logo Lockup for व्यवहार (Vyavahaar)
class AppLogo extends StatelessWidget {
  final AppLogoVariant variant;
  final AppLogoTheme theme;
  final double symbolSize;
  final bool showTagline;
  final String? customTagline;

  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.vertical,
    this.theme = AppLogoTheme.darkCanvas,
    this.symbolSize = 80.0,
    this.showTagline = true,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = theme == AppLogoTheme.darkCanvas;

    final titleColor = isDark ? AppColors.warmCream : AppColors.deepNavy;
    final taglineColor = isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary;
    final pageColor = isDark ? AppColors.warmCream : AppColors.warmCream;
    const checkColor = AppColors.terracotta;

    final effectiveTagline = customTagline ?? l10n.appTagline;

    if (variant == AppLogoVariant.symbolOnly) {
      return AppSymbol(
        size: symbolSize,
        pageColor: pageColor,
        checkmarkColor: checkColor,
      );
    }

    if (variant == AppLogoVariant.horizontal || variant == AppLogoVariant.compactHeader) {
      final isCompact = variant == AppLogoVariant.compactHeader;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 4 : 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33FFFFFF) : AppColors.deepNavy,
              borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppSymbol(
              size: isCompact ? 28 : symbolSize,
              pageColor: AppColors.warmCream,
              checkmarkColor: AppColors.terracotta,
            ),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.appName,
                style: TextStyle(
                  fontSize: isCompact ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
              if (showTagline && !isCompact) ...[
                const SizedBox(height: 2),
                Text(
                  effectiveTagline,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: taglineColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Default: Vertical (Hero / Splash / Onboarding)
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Elevated Symbol Card
        Container(
          width: symbolSize * 1.3,
          height: symbolSize * 1.3,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16253D) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x40000000) : const Color(0x201F3352),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0x26F4EFE7) : const Color(0x1A1F3352),
              width: 1.5,
            ),
          ),
          child: Center(
            child: AppSymbol(
              size: symbolSize,
              pageColor: AppColors.warmCream,
              checkmarkColor: AppColors.terracotta,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Devanagari Wordmark
        Text(
          l10n.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: symbolSize >= 80 ? 36 : 28,
            fontWeight: FontWeight.w900,
            color: titleColor,
            letterSpacing: 1.2,
            height: 1.1,
          ),
        ),

        // Tagline
        if (showTagline) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1AF4EFE7) : const Color(0x121F3352),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              effectiveTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: taglineColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
