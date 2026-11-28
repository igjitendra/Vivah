import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/express_type.dart';
import '../../../core/theme/ui_preferences_notifier.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../domain/entities/family_profile.dart';
import '../../../shared/widgets/express_settings_kit.dart';
import '../../../shared/widgets/express_shapes.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/profile_share_actions.dart';
import '../../budget/domain/budget_models.dart';
import '../../budget/presentation/budget_providers.dart';

/// Clean Hub screen for the 5th bottom navigation tab ("More" / "अधिक").
/// Focused strictly on non-settings household tools: Family Profile,
/// Budget & Returnable Funds Planner, Reports & Exports, and Reminders,
/// with a direct header shortcut to Settings.
class MoreScreen extends ConsumerWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenReminders;
  final ValueChanged<bool> onOpenFamilyProfile;
  final VoidCallback? onOpenBudgetPlanner;

  const MoreScreen({
    super.key,
    required this.onOpenSettings,
    required this.onOpenReports,
    required this.onOpenReminders,
    required this.onOpenFamilyProfile,
    this.onOpenBudgetPlanner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;
    final familyProfile =
        ref.watch(familyProfileProvider).value ?? const FamilyProfile();
    final pendingCount = ref.watch(pendingRemindersCountProvider).value ?? 0;
    final budgetSnapshot = ref.watch(budgetDashboardProvider).asData?.value;
    final budgetStats = budgetSnapshot == null
        ? const BudgetOverviewStats()
        : BudgetCalculations.summarize(
            categories: budgetSnapshot.categories,
            expenses: budgetSnapshot.expenses,
            arrangements: budgetSnapshot.arrangements,
          );

    return CompactDensity(
      isCompact: uiPrefs.compactMode,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: isExpress
              ? null
              : Text(
                  l10n.moreTitle,
                  style: TextStyle(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          toolbarHeight: isExpress ? 54 : kToolbarHeight,
          shape: const Border(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _HeaderSettingsAction(
                  label: l10n.tabSettings,
                  tooltip: l10n.settingsTitle,
                  showLabel: isExpress,
                  semantic: semantic,
                  onTap: onOpenSettings,
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                isExpress ? 2 : 10,
                18,
                AppSpacing.floatingTabBottomPadding + 24,
              ),
              children: [
                if (isExpress) ...[
                  ExpressReveal(
                    index: 0,
                    child: ExpressHeadline(
                      title: l10n.moreTitle,
                      subtitle: l10n.moreHubSubtitle,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 1. Family Profile Identity Banner
                ExpressReveal(
                  index: 1,
                  child: _FamilyBannerCard(
                    semantic: semantic,
                    l10n: l10n,
                    profile: familyProfile,
                    isExpress: isExpress,
                    onTap: () => onOpenFamilyProfile(familyProfile.isEmpty),
                    onTapQrShare: familyProfile.isEmpty
                        ? null
                        : () => ProfileShareActions.showFamilyProfileShareSheet(
                              context,
                              familyProfile,
                            ),
                  ),
                ),

                ExpressSectionLabel(l10n.moreToolsSection),

                // 2. Primary Utility: Budget & Returnable Funds Planner
                ExpressReveal(
                  index: 2,
                  child: _FeaturedBudgetCard(
                    semantic: semantic,
                    l10n: l10n,
                    stats: budgetStats,
                    isExpress: isExpress,
                    compact: uiPrefs.compactMode,
                    onTap: onOpenBudgetPlanner ?? () => context.push('/budget'),
                  ),
                ),

                SizedBox(height: uiPrefs.compactMode ? 10 : 12),

                // 3. Analytics & Reminders Equal-Height Bento Row
                ExpressReveal(
                  index: 3,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MoreToolCard(
                            icon: Icons.insights_rounded,
                            title: l10n.reportsAndExports,
                            subtitle: l10n.isEnglish
                                ? 'Charts • PDF • CSV'
                                : 'चार्ट • PDF • CSV',
                            accentColor: semantic.warning,
                            containerColor: semantic.warningContainer,
                            semantic: semantic,
                            isExpress: isExpress,
                            onTap: onOpenReports,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MoreToolCard(
                            icon: Icons.notifications_active_rounded,
                            title: l10n.reminders,
                            subtitle: pendingCount > 0
                                ? '$pendingCount ${l10n.pending}'
                                : l10n.noPendingReminders,
                            badgeText: pendingCount > 0 ? '$pendingCount' : null,
                            accentColor: semantic.diya,
                            containerColor: semantic.diyaContainer,
                            semantic: semantic,
                            isExpress: isExpress,
                            onTap: onOpenReminders,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSettingsAction extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool showLabel;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _HeaderSettingsAction({
    required this.label,
    required this.tooltip,
    required this.showLabel,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ExpressSquish(
        scale: 0.94,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 12 : 9,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: semantic.textPrimary,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: semantic.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyBannerCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final FamilyProfile profile;
  final bool isExpress;
  final VoidCallback onTap;
  final VoidCallback? onTapQrShare;

  const _FamilyBannerCard({
    required this.semantic,
    required this.l10n,
    required this.profile,
    required this.isExpress,
    required this.onTap,
    this.onTapQrShare,
  });

  @override
  Widget build(BuildContext context) {
    final String title = profile.isEmpty
        ? l10n.setupFamilyProfile
        : (profile.familyName.trim().isNotEmpty
            ? profile.familyName.trim()
            : profile.headOfFamily.trim());
    final String subtitle = profile.isEmpty
        ? l10n.setupFamilyProfileSubtitle
        : '${profile.members.length} ${l10n.familyMembers}'
            '${profile.nativePlace.trim().isNotEmpty ? ' • ${profile.nativePlace.trim()}' : ''}';

    return ExpressSquish(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [semantic.heroStart, semantic.heroEnd],
          ),
          borderRadius: BorderRadius.circular(isExpress ? 22 : 18),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: semantic.heroHighlight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: semantic.heroHighlight.withValues(alpha: 0.42),
                ),
              ),
              child: Icon(
                Icons.home_rounded,
                color: semantic.heroHighlight,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.myFamily,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: semantic.onHeroMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: semantic.heroHighlight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: semantic.onHeroMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onTapQrShare != null) ...[
              const SizedBox(width: 6),
              Material(
                color: semantic.heroHighlight.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTapQrShare,
                  child: Tooltip(
                    message: l10n.qrSharePillLabel,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        size: 18,
                        color: semantic.heroHighlight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: semantic.heroHighlight,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedBudgetCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final BudgetOverviewStats stats;
  final bool isExpress;
  final bool compact;
  final VoidCallback onTap;

  const _FeaturedBudgetCard({
    required this.semantic,
    required this.l10n,
    required this.stats,
    required this.isExpress,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBudgetMetrics = stats.plannedBudgetPaise > 0 ||
        stats.totalPaidPaise > 0 ||
        stats.totalBorrowRemainingPaise > 0;

    return ExpressSquish(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 14 : 16),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(isExpress ? 22 : 18),
          border: Border.all(
            color: semantic.primary.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExpressBlob(
                  size: 46,
                  color: semantic.primary.withValues(alpha: isDark ? 0.22 : 0.13),
                  shape: ExpressShape.cookie,
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 22,
                    color: semantic.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.budgetPlannerTitle,
                        style: ExpressType.titleMedium(
                          color: semantic.textPrimary,
                          weight: FontWeight.w800,
                        ).copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.budgetPlannerSubtitle,
                        style: ExpressType.bodySmall(
                          color: semantic.textSecondary,
                          weight: FontWeight.w500,
                        ).copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: semantic.textSecondary,
                ),
              ],
            ),
            if (hasBudgetMetrics) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.8,
                color: semantic.cardBorder.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _BudgetStatCell(
                    label: l10n.plannedBudgetLabel,
                    value: CurrencyUtils.formatPaise(stats.plannedBudgetPaise),
                    color: semantic.textPrimary,
                    semantic: semantic,
                  ),
                  _BudgetStatDivider(semantic: semantic),
                  _BudgetStatCell(
                    label: l10n.totalPaidOutLabel,
                    value: CurrencyUtils.formatPaise(stats.totalPaidPaise),
                    color: semantic.info,
                    semantic: semantic,
                  ),
                  _BudgetStatDivider(semantic: semantic),
                  _BudgetStatCell(
                    label: l10n.returnRemainingLabel,
                    value: CurrencyUtils.formatPaise(stats.totalBorrowRemainingPaise),
                    color: stats.totalBorrowRemainingPaise > 0
                        ? semantic.warning
                        : semantic.mila,
                    semantic: semantic,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetStatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppSemanticColors semantic;

  const _BudgetStatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatDivider extends StatelessWidget {
  final AppSemanticColors semantic;

  const _BudgetStatDivider({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: semantic.cardBorder,
    );
  }
}

class _MoreToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color accentColor;
  final Color containerColor;
  final AppSemanticColors semantic;
  final bool isExpress;
  final VoidCallback onTap;

  const _MoreToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.accentColor,
    required this.containerColor,
    required this.semantic,
    required this.isExpress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(isExpress ? 22 : 18),
          border: Border.all(color: semantic.cardBorder),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExpressBlob(
                  size: 42,
                  color: containerColor,
                  shape: ExpressShape.cookie,
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: semantic.badgeAlertBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: semantic.onBadgeAlert,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: semantic.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ExpressType.titleMedium(
                    color: semantic.textPrimary,
                    weight: FontWeight.w800,
                  ).copyWith(fontSize: 14.5, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: semantic.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
