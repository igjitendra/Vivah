import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';

/// Onboarding walkthrough screen introducing user to Vyavahaar's
/// cultural philosophy, offline privacy, and separated Mila/Diya ledger.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Whether this screen was opened from Settings as an app tour
  final bool isFromSettings;

  const OnboardingScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.setSetting('onboarding_completed', 'true');
    } catch (_) {}

    if (!mounted) return;

    if (widget.isFromSettings) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final activeLanguage = ref.watch(currentLanguageSpecProvider);

    final bg = isDark ? theme.scaffoldBackgroundColor : AppColors.warmCream;
    final textPrimary = isDark ? Colors.white : AppColors.deepNavy;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Logo & Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Brand Header
                  Row(
                    children: [
                      AppSymbol(
                        size: 32,
                        pageColor: isDark ? AppColors.warmCream : AppColors.warmCream,
                        checkmarkColor: AppColors.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.appName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button (hidden on last slide)
                  if (_currentPage < 2)
                    ExpressSquish(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F1F3352),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Middle Carousel: 3 Onboarding Slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Slide 1: Traditional Digital Bahi Khata
                  _buildSlide(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    iconBg: const Color(0xFFEBF3FC),
                    iconColor: AppColors.deepNavy,
                    badgeText: l10n.onboardingSlide1Badge,
                    badgeColor: AppColors.milaGreen,
                    badgeBg: isDark ? const Color(0xFF1B3D27) : AppColors.milaGreenSoft,
                    title: l10n.onboardingSlide1Title,
                    description: l10n.onboardingSlide1Desc,
                    points: [
                      _SlidePoint(
                        icon: Icons.receipt_long_rounded,
                        title: l10n.received,
                        detail: l10n.onboardingSlide1Detail1,
                      ),
                      _SlidePoint(
                        icon: Icons.card_giftcard_rounded,
                        title: l10n.giftItem,
                        detail: l10n.onboardingSlide1Detail2,
                      ),
                    ],
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  // Slide 2: Cultural Dignity & Zero Stress
                  _buildSlide(
                    context: context,
                    icon: Icons.volunteer_activism_rounded,
                    iconBg: const Color(0xFFFBECE5),
                    iconColor: AppColors.terracotta,
                    badgeText: l10n.onboardingSlide2Badge,
                    badgeColor: AppColors.terracotta,
                    badgeBg: isDark ? const Color(0xFF452216) : const Color(0xFFFBECE5),
                    title: l10n.onboardingSlide2Title,
                    description: l10n.onboardingSlide2Desc,
                    points: [
                      _SlidePoint(
                        icon: Icons.handshake_outlined,
                        title: l10n.onboardingSlide2TitlePoint1,
                        detail: l10n.onboardingSlide2Detail1,
                      ),
                      _SlidePoint(
                        icon: Icons.event_available_rounded,
                        title: l10n.planned,
                        detail: l10n.onboardingSlide2Detail2,
                      ),
                    ],
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  // Slide 3: 100% Offline, Secure & Private
                  _buildSlide(
                    context: context,
                    icon: Icons.shield_rounded,
                    iconBg: const Color(0xFFE2F5EB),
                    iconColor: AppColors.milaGreen,
                    badgeText: l10n.onboardingSlide3Badge,
                    badgeColor: const Color(0xFF0284C7),
                    badgeBg: isDark ? const Color(0xFF0C3352) : const Color(0xFFE0F2FE),
                    title: l10n.onboardingSlide3Title,
                    description: l10n.onboardingSlide3Desc,
                    points: [
                      _SlidePoint(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.onboardingSlide3TitlePoint1,
                        detail: l10n.onboardingSlide3Detail1,
                      ),
                      _SlidePoint(
                        icon: Icons.picture_as_pdf_outlined,
                        title: l10n.onboardingSlide3TitlePoint2,
                        detail: l10n.onboardingSlide3Detail2,
                      ),
                    ],
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    extraWidget: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InkWell(
                        onTap: () => context.push('/language'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.translate, size: 16, color: AppColors.terracotta),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.selectLanguage}: ${activeLanguage.nameNative}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation: Indicator Dots & CTA Button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Dots
                  Row(
                    children: List.generate(3, (index) {
                      final bool isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.terracotta
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Action Button
                  ExpressSquish(
                    onTap: _nextPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: _currentPage == 2 ? AppColors.terracotta : AppColors.deepNavy,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_currentPage == 2 ? AppColors.terracotta : AppColors.deepNavy)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == 2
                                ? l10n.onboardingGetStarted
                                : l10n.onboardingNext,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == 2
                                ? Icons.check_circle_outline
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required String title,
    required String description,
    required List<_SlidePoint> points,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    Widget? extraWidget,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Hero Icon Container with Elevation
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 18),

          // Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Slide Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Slide Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          // Highlights Card with Bullet Points
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: points.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(p.icon, size: 16, color: AppColors.terracotta),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.detail,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (extraWidget != null) extraWidget,
        ],
      ),
    );
  }
}

class _SlidePoint {
  final IconData icon;
  final String title;
  final String detail;

  const _SlidePoint({
    required this.icon,
    required this.title,
    required this.detail,
  });
}
