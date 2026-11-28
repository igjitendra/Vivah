import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../app/app_providers.dart';

/// Fullscreen Animated Splash Screen for व्यवहार (Vyavahaar)
/// Features official brand geometry, Devanagari typography, and automatic
/// routing to either Onboarding (first launch) or Dashboard (returning user).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _checkAppStatusAndNavigate();
  }

  Future<void> _checkAppStatusAndNavigate() async {
    // Fast, responsive presentation delay (650ms) for smooth entrance
    final minDelay = Future.delayed(const Duration(milliseconds: 650));

    String? onboardingStatus;
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      onboardingStatus = await settingsRepo.getSetting('onboarding_completed');
    } catch (_) {
      onboardingStatus = null;
    }

    await minDelay;

    if (!mounted) return;

    if (onboardingStatus == 'true') {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(
        topBackground: AppColors.deepNavy,
        bottomBackground: AppColors.deepNavy,
      ),
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          // Subtle ambient radial glow behind logo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.1),
                  radius: 0.85,
                  colors: [
                    Color(0xFF2A436D), // Lighter navy aura
                    AppColors.deepNavy,
                  ],
                ),
              ),
            ),
          ),

          // Central Animated Brand Logo
          Center(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: const AppLogo(
                variant: AppLogoVariant.vertical,
                theme: AppLogoTheme.darkCanvas,
                symbolSize: 88,
                showTagline: true,
              ),
            ),
          ),

          // Bottom Offline & Trust Badge
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AF4EFE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0x33F4EFE7),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: AppColors.warmCream,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.offlineNotice,
                          style: const TextStyle(
                            color: AppColors.warmCream,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.splashLoading,
                    style: TextStyle(
                      color: AppColors.warmCream.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
