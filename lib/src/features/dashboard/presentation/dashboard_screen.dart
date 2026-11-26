import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/shortcuts/shortcuts_sheet.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/express_squish.dart';

/// Theme-adaptive Hero & Bento Dashboard for व्यवहार (Vyavahaar).
/// Derives 100% of colors from [AppSemanticColors] and [ThemeData] with zero hardcoded color literals.
class DashboardScreen extends ConsumerWidget {
  final DashboardSummary summary;
  final VoidCallback onNewEntry;
  final VoidCallback? onNewEntryReceived;
  final VoidCallback? onNewEntryGiven;
  final VoidCallback onNewEvent;
  final VoidCallback onNewPerson;
  final VoidCallback onOpenSettings;
  final ValueChanged<String>? onOpenEventDetails;
  final VoidCallback? onViewAllEntries;
  final VoidCallback? onViewAllEvents;
  final VoidCallback? onViewAllPeople;
  final ValueChanged<String>? onOpenEntryDetails;
  final VoidCallback? onFilterMila;
  final VoidCallback? onFilterDiya;
  final VoidCallback? onOpenReminders;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenFamilyProfile;
  final VoidCallback? onSetupFamilyProfile;

  const DashboardScreen({
    super.key,
    required this.summary,
    required this.onNewEntry,
    this.onNewEntryReceived,
    this.onNewEntryGiven,
    required this.onNewEvent,
    required this.onNewPerson,
    required this.onOpenSettings,
    this.onOpenEventDetails,
    this.onViewAllEntries,
    this.onViewAllEvents,
    this.onViewAllPeople,
    this.onOpenEntryDetails,
    this.onFilterMila,
    this.onFilterDiya,
    this.onOpenReminders,
    this.onOpenReports,
    this.onOpenFamilyProfile,
    this.onSetupFamilyProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final db = ref.watch(databaseProvider);

    ref.watch(liveDateProvider);
    final entriesAsync = ref.watch(entriesListProvider(null));
    final eventsAsync = ref.watch(activeEventsListProvider);
    final familyProfileAsync = ref.watch(familyProfileProvider);
    final familyProfile = familyProfileAsync.value ?? const FamilyProfile();

    // Single-pass breakdown for Cash vs Estimated Gift Value from recorded entries.
    final _SplitTotals splitTotals = _computeSplitTotals(entriesAsync.value ?? const []);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<List<ReminderRow>>(
        stream: db.remindersDao.watchAllReminders(),
        builder: (context, reminderSnapshot) {
          final allReminders = reminderSnapshot.data ?? const <ReminderRow>[];
          final pendingReminders = allReminders.where((r) => !r.isCompleted).toList()
            ..sort((a, b) => a.reminderDate.compareTo(b.reminderDate));

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Rich Theme-Adaptive Hero Banner + Overlapping Family Profile Card
              SliverToBoxAdapter(
                child: _HeroFamilyHeader(
                  semantic: semantic,
                  l10n: l10n,
                  familyProfile: familyProfile,
                  pendingReminderCount: pendingReminders.length,
                  onOpenReminders: onOpenReminders ?? onOpenSettings,
                  onOpenSettings: onOpenSettings,
                  onFamilyTap: familyProfile.isEmpty
                      ? (onSetupFamilyProfile ?? onOpenSettings)
                      : (onOpenFamilyProfile ?? onOpenSettings),
                ),
              ),

              // 2. Main Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.floatingTabBottomPadding,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // A. Two Hero Financial Overview Cards (Mila vs Diya)
                    Row(
                      children: [
                        Expanded(
                          child: _FinancialMetricCard(
                            label: l10n.received,
                            amount: CurrencyUtils.formatPaise(summary.totalMilaPaise),
                            footerLabel: l10n.recordedSoFar,
                            icon: Icons.arrow_downward_rounded,
                            accentColor: semantic.mila,
                            containerColor: semantic.milaContainer,
                            badgeBgColor: semantic.milaBadgeBg,
                            borderColor: semantic.milaBorder,
                            onVibrantColor: semantic.onVibrant,
                            cardBgColor: semantic.cardBg,
                            textPrimaryColor: semantic.textPrimary,
                            shadowColor: semantic.shadow,
                            isPositiveTrend: true,
                            onTap: onFilterMila ?? onViewAllEntries,
                            onQuickAdd: onNewEntryReceived ?? onNewEntry,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FinancialMetricCard(
                            label: l10n.given,
                            amount: CurrencyUtils.formatPaise(summary.totalDiyaPaise),
                            footerLabel: l10n.recordedSoFar,
                            icon: Icons.arrow_upward_rounded,
                            accentColor: semantic.diya,
                            containerColor: semantic.diyaContainer,
                            badgeBgColor: semantic.diyaBadgeBg,
                            borderColor: semantic.diyaBorder,
                            onVibrantColor: semantic.onVibrant,
                            cardBgColor: semantic.cardBg,
                            textPrimaryColor: semantic.textPrimary,
                            shadowColor: semantic.shadow,
                            isPositiveTrend: false,
                            onTap: onFilterDiya ?? onViewAllEntries,
                            onQuickAdd: onNewEntryGiven ?? onNewEntry,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // B. Compact Split Cards: Gifts & Cash
                    Row(
                      children: [
                        Expanded(
                          child: _SplitBreakdownCard(
                            icon: Icons.card_giftcard_rounded,
                            label: l10n.giftsLabel,
                            value: splitTotals.giftsPaise > 0
                                ? CurrencyUtils.formatPaise(splitTotals.giftsPaise)
                                : (splitTotals.giftItemCount > 0
                                    ? '${splitTotals.giftItemCount} ${l10n.itemsCountSuffix}'
                                    : CurrencyUtils.formatPaise(0)),
                            accentColor: semantic.giftAccent,
                            containerColor: semantic.giftContainer,
                            semantic: semantic,
                            onTap: onViewAllEntries,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SplitBreakdownCard(
                            icon: Icons.payments_rounded,
                            label: l10n.cash,
                            value: CurrencyUtils.formatPaise(splitTotals.cashPaise),
                            accentColor: semantic.cashAccent,
                            containerColor: semantic.cashContainer,
                            semantic: semantic,
                            onTap: onViewAllEntries,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // C. Quick Actions Card (त्वरित कार्य)
                    _ThemedSectionCard(
                      semantic: semantic,
                      icon: Icons.bolt_rounded,
                      title: l10n.quickActions,
                      actionLabel: l10n.viewAll,
                      onActionTap: () => ShortcutsSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _QuickActionTile(
                                icon: Icons.post_add_rounded,
                                label: l10n.quickActionEntry,
                                iconColor: semantic.mila,
                                tileBg: semantic.milaContainer,
                                borderColor: semantic.milaBorder,
                                textColor: semantic.textPrimary,
                                onTap: onNewEntry,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _QuickActionTile(
                                icon: Icons.calendar_month_rounded,
                                label: l10n.quickActionEvent,
                                iconColor: semantic.diya,
                                tileBg: semantic.diyaContainer,
                                borderColor: semantic.diyaBorder,
                                textColor: semantic.textPrimary,
                                onTap: onNewEvent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _QuickActionTile(
                                icon: Icons.groups_rounded,
                                label: l10n.tabPeople,
                                iconColor: semantic.info,
                                tileBg: semantic.infoContainer,
                                borderColor: semantic.info.withValues(alpha: 0.28),
                                textColor: semantic.textPrimary,
                                onTap: onViewAllPeople ?? onNewPerson,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _QuickActionTile(
                                icon: Icons.picture_as_pdf_rounded,
                                label: l10n.reports,
                                iconColor: semantic.warning,
                                tileBg: semantic.warningContainer,
                                borderColor: semantic.warning.withValues(alpha: 0.28),
                                textColor: semantic.textPrimary,
                                onTap: onOpenReports ?? onOpenSettings,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _QuickActionTile(
                                icon: Icons.lock_rounded,
                                label: l10n.backupShort,
                                iconColor: semantic.secondary,
                                tileBg: semantic.cardSubtleBg,
                                borderColor: semantic.cardBorder,
                                textColor: semantic.textPrimary,
                                onTap: onOpenSettings,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // D. Side-by-Side Bento Cards: Upcoming Events & Upcoming Reminders
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final eventsCard = _UpcomingEventsCard(
                          semantic: semantic,
                          l10n: l10n,
                          eventsAsync: eventsAsync,
                          onViewAll: onViewAllEvents,
                          onOpenEvent: onOpenEventDetails,
                          onNewEvent: onNewEvent,
                        );
                        final remindersCard = _UpcomingRemindersCard(
                          semantic: semantic,
                          l10n: l10n,
                          pendingReminders: pendingReminders,
                          onViewAll: onOpenReminders ?? onOpenSettings,
                        );

                        if (constraints.maxWidth < 330) {
                          return Column(
                            children: [
                              eventsCard,
                              const SizedBox(height: AppSpacing.sm),
                              remindersCard,
                            ],
                          );
                        }

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: eventsCard),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: remindersCard),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // E. Recent Transactions Card (हाल के व्यवहार)
                    _RecentTransactionsCard(
                      semantic: semantic,
                      l10n: l10n,
                      entriesAsync: entriesAsync,
                      onViewAll: onViewAllEntries,
                      onOpenEntryDetails: onOpenEntryDetails,
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static _SplitTotals _computeSplitTotals(List<TransactionEntry> entries) {
    int cashPaise = 0;
    int giftsPaise = 0;
    int giftItemCount = 0;

    for (final entry in entries) {
      if (entry.status != TransactionStatus.recorded || entry.archivedAt != null) {
        continue;
      }
      cashPaise += entry.cashAmountPaise;
      for (final item in entry.items) {
        giftItemCount++;
        giftsPaise += item.estimatedValuePaise ?? 0;
      }
    }

    return _SplitTotals(
      cashPaise: cashPaise,
      giftsPaise: giftsPaise,
      giftItemCount: giftItemCount,
    );
  }
}

class _SplitTotals {
  final int cashPaise;
  final int giftsPaise;
  final int giftItemCount;

  const _SplitTotals({
    required this.cashPaise,
    required this.giftsPaise,
    required this.giftItemCount,
  });
}

/// Top gradient hero header with decorative leaf flourishes and overlapping Family Profile card.
class _HeroFamilyHeader extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final FamilyProfile familyProfile;
  final int pendingReminderCount;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenSettings;
  final VoidCallback onFamilyTap;

  const _HeroFamilyHeader({
    required this.semantic,
    required this.l10n,
    required this.familyProfile,
    required this.pendingReminderCount,
    required this.onOpenReminders,
    required this.onOpenSettings,
    required this.onFamilyTap,
  });

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final String localeCode = l10n.locale.languageCode;
    final String todayShort = AppDateUtils.getLiveTodayHeaderString(localeCode);

    final String familyTitle = familyProfile.isEmpty
        ? l10n.setupFamilyProfile
        : (familyProfile.familyName.trim().isNotEmpty
            ? familyProfile.familyName.trim()
            : familyProfile.headOfFamily.trim());

    final String familySubtitle;
    if (familyProfile.isEmpty) {
      familySubtitle = l10n.setupFamilyProfileSubtitle;
    } else if (familyProfile.nativePlace.trim().isNotEmpty) {
      familySubtitle = familyProfile.nativePlace.trim();
    } else if (familyProfile.currentCity.trim().isNotEmpty) {
      familySubtitle = familyProfile.currentCity.trim();
    } else if (familyProfile.headOfFamily.trim().isNotEmpty) {
      familySubtitle = familyProfile.headOfFamily.trim();
    } else {
      familySubtitle = todayShort;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hero dark gradient backdrop extending down under the top half of the family card
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 38,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [semantic.heroStart, semantic.heroEnd],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: CustomPaint(
                painter: _HeroOrnamentPainter(
                  accentColor: semantic.heroHighlight,
                ),
              ),
            ),
          ),
        ),

        // Foreground content column
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            topPadding + 10,
            AppSpacing.md,
            4,
          ),
          child: Column(
            children: [
              // Top Brand + Notification & Settings row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          semantic.heroHighlight.withValues(alpha: 0.22),
                          semantic.heroStart,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: semantic.heroHighlight.withValues(alpha: 0.60),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: semantic.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AppSymbol(
                      size: 28,
                      pageColor: semantic.heroHighlight,
                      checkmarkColor: semantic.primary,
                      accentColor: semantic.heroHighlight,
                      useAssetFallback: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: semantic.heroHighlight,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.appTagline,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: semantic.onHeroMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell with live pending reminder badge
                  ExpressSquish(
                    scale: 0.90,
                    onTap: onOpenReminders,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: semantic.onHero.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: semantic.onHero.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: semantic.onHero,
                            size: 21,
                          ),
                        ),
                        if (pendingReminderCount > 0)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              decoration: BoxDecoration(
                                color: semantic.badgeAlertBg,
                                shape: pendingReminderCount < 10
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: pendingReminderCount < 10
                                    ? null
                                    : BorderRadius.circular(10),
                                border: Border.all(
                                  color: semantic.heroStart,
                                  width: 1.4,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pendingReminderCount > 99 ? '99+' : '$pendingReminderCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: semantic.onBadgeAlert,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Settings Button
                  ExpressSquish(
                    scale: 0.90,
                    onTap: onOpenSettings,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: semantic.onHero.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: semantic.onHero.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        color: semantic.onHero,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Overlapping Floating Family Banner Card
              ExpressSquish(
                scale: 0.98,
                onTap: onFamilyTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: semantic.heroCardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: semantic.heroCardBorder,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: semantic.shadow,
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // Left: Home icon + Family Name + Location
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: semantic.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.home_rounded,
                            color: semantic.textPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.myFamily,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: semantic.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                familyTitle,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: semantic.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                familySubtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: semantic.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Vertical Divider
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: semantic.heroCardBorder,
                        ),

                        // Right: Member Count + View CTA Pill
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 22,
                                color: semantic.textPrimary.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.familyMembersShort,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: semantic.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${familyProfile.members.length}',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: semantic.textPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: semantic.cardBg,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: semantic.heroCardBorder),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                familyProfile.isEmpty
                                                    ? l10n.setupShort
                                                    : l10n.viewShort,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: semantic.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 11,
                                                color: semantic.textPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hero Financial Metric Card (Mila & Diya) with vibrant icon badge, rising chart accent, and footer strip.
class _FinancialMetricCard extends StatelessWidget {
  final String label;
  final String amount;
  final String footerLabel;
  final IconData icon;
  final Color accentColor;
  final Color containerColor;
  final Color badgeBgColor;
  final Color borderColor;
  final Color onVibrantColor;
  final Color cardBgColor;
  final Color textPrimaryColor;
  final Color shadowColor;
  final bool isPositiveTrend;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;

  const _FinancialMetricCard({
    required this.label,
    required this.amount,
    required this.footerLabel,
    required this.icon,
    required this.accentColor,
    required this.containerColor,
    required this.badgeBgColor,
    required this.borderColor,
    required this.onVibrantColor,
    required this.cardBgColor,
    required this.textPrimaryColor,
    required this.shadowColor,
    required this.isPositiveTrend,
    this.onTap,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cardBgColor, containerColor],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.15),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 18, color: onVibrantColor),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onQuickAdd != null)
                        GestureDetector(
                          onTap: onQuickAdd,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 15,
                              color: accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: textPrimaryColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        height: 18,
                        child: CustomPaint(
                          painter: _MiniTrendBarsPainter(
                            color: accentColor,
                            ascending: isPositiveTrend,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom subtle tinted strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: badgeBgColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      footerLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimaryColor.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact split breakdown card for Gifts vs Cash totals.
class _SplitBreakdownCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color containerColor;
  final AppSemanticColors semantic;
  final VoidCallback? onTap;

  const _SplitBreakdownCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.containerColor,
    required this.semantic,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [containerColor, semantic.cardBg],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: semantic.cardBorder),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: semantic.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: semantic.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: semantic.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared card container with theme-adaptive dark header strip and clean surface body.
class _ThemedSectionCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget child;
  final bool compactHeader;

  const _ThemedSectionCard({
    required this.semantic,
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    required this.child,
    this.compactHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: semantic.cardBorder),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compactHeader ? 10 : 14,
              vertical: compactHeader ? 8 : 9.5,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [semantic.heroStart, semantic.heroEnd],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: compactHeader ? 15 : 17,
                  color: semantic.heroHighlight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: compactHeader ? 12.5 : 14,
                      fontWeight: FontWeight.w800,
                      color: semantic.onHero,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actionLabel != null && onActionTap != null)
                  GestureDetector(
                    onTap: onActionTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel!,
                            style: TextStyle(
                              fontSize: compactHeader ? 10.5 : 11.5,
                              fontWeight: FontWeight.w700,
                              color: semantic.heroHighlight,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: compactHeader ? 11 : 13,
                            color: semantic.heroHighlight,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color tileBg;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.tileBg,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.93,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: borderColor, width: 0.9),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final AsyncValue<List<Event>> eventsAsync;
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onOpenEvent;
  final VoidCallback onNewEvent;

  const _UpcomingEventsCard({
    required this.semantic,
    required this.l10n,
    required this.eventsAsync,
    this.onViewAll,
    this.onOpenEvent,
    required this.onNewEvent,
  });

  @override
  Widget build(BuildContext context) {
    final String localeCode = l10n.locale.languageCode;
    final DateTime now = DateTime.now();
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    final allEvents = eventsAsync.value ?? const <Event>[];
    final upcoming = allEvents.where((e) {
      if (e.isArchived) return false;
      if (e.status == EventStatus.cancelled || e.status == EventStatus.completed) {
        return false;
      }
      final dt = AppDateUtils.parseToLocalDate(e.eventDate);
      if (dt == null) return false;
      final eventDay = DateTime(dt.year, dt.month, dt.day);
      return !eventDay.isBefore(todayMidnight);
    }).toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final topEvents = upcoming.take(2).toList();

    return _ThemedSectionCard(
      semantic: semantic,
      icon: Icons.calendar_today_rounded,
      title: l10n.upcomingEvents,
      actionLabel: l10n.viewShort,
      onActionTap: onViewAll,
      compactHeader: true,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: topEvents.isEmpty
            ? InkWell(
                onTap: onNewEvent,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 22,
                        color: semantic.textSecondary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.noUpcomingEvents,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: semantic.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ ${l10n.addShort}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: semantic.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < topEvents.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 12,
                        thickness: 0.8,
                        color: semantic.cardBorder.withValues(alpha: 0.7),
                      ),
                    _UpcomingEventRow(
                      event: topEvents[i],
                      todayMidnight: todayMidnight,
                      localeCode: localeCode,
                      semantic: semantic,
                      l10n: l10n,
                      isFirst: i == 0,
                      onTap: () => onOpenEvent?.call(topEvents[i].id),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _UpcomingEventRow extends StatelessWidget {
  final Event event;
  final DateTime todayMidnight;
  final String localeCode;
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final bool isFirst;
  final VoidCallback onTap;

  const _UpcomingEventRow({
    required this.event,
    required this.todayMidnight,
    required this.localeCode,
    required this.semantic,
    required this.l10n,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = AppDateUtils.parseToLocalDate(event.eventDate);
    final int daysLeft = dt != null
        ? DateTime(dt.year, dt.month, dt.day).difference(todayMidnight).inDays
        : 0;
    final Color highlightColor = isFirst ? semantic.diya : semantic.info;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFirst ? semantic.warningContainer : semantic.infoContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isFirst ? Icons.celebration_rounded : Icons.cake_rounded,
              size: 15,
              color: isFirst ? semantic.warning : semantic.info,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: semantic.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppDateUtils.formatLocalizedDate(event.eventDate, localeCode)} • ${l10n.daysLeftLabel(daysLeft)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: highlightColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRemindersCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final List<ReminderRow> pendingReminders;
  final VoidCallback onViewAll;

  const _UpcomingRemindersCard({
    required this.semantic,
    required this.l10n,
    required this.pendingReminders,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final String localeCode = l10n.locale.languageCode;
    final topReminders = pendingReminders.take(2).toList();
    final DateTime now = DateTime.now();
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    return _ThemedSectionCard(
      semantic: semantic,
      icon: Icons.notifications_active_rounded,
      title: l10n.upcomingReminders,
      actionLabel: l10n.viewShort,
      onActionTap: onViewAll,
      compactHeader: true,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: topReminders.isEmpty
            ? InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: semantic.textSecondary.withValues(alpha: 0.55),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.noPendingReminders,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: semantic.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+ ${l10n.addShort}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: semantic.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < topReminders.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 12,
                        thickness: 0.8,
                        color: semantic.cardBorder.withValues(alpha: 0.7),
                      ),
                    _UpcomingReminderRow(
                      reminder: topReminders[i],
                      todayMidnight: todayMidnight,
                      localeCode: localeCode,
                      semantic: semantic,
                      onTap: onViewAll,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _UpcomingReminderRow extends StatelessWidget {
  final ReminderRow reminder;
  final DateTime todayMidnight;
  final String localeCode;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _UpcomingReminderRow({
    required this.reminder,
    required this.todayMidnight,
    required this.localeCode,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dt = AppDateUtils.parseToLocalDate(reminder.reminderDate);
    final Color dotColor;
    if (dt != null) {
      final remDay = DateTime(dt.year, dt.month, dt.day);
      final diff = remDay.difference(todayMidnight).inDays;
      if (diff < 0) {
        dotColor = semantic.diya;
      } else if (diff <= 3) {
        dotColor = semantic.warning;
      } else {
        dotColor = semantic.info;
      }
    } else {
      dotColor = semantic.warning;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: semantic.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  AppDateUtils.formatLocalizedDate(reminder.reminderDate, localeCode),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: semantic.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final AsyncValue<List<TransactionEntry>> entriesAsync;
  final VoidCallback? onViewAll;
  final ValueChanged<String>? onOpenEntryDetails;

  const _RecentTransactionsCard({
    required this.semantic,
    required this.l10n,
    required this.entriesAsync,
    this.onViewAll,
    this.onOpenEntryDetails,
  });

  @override
  Widget build(BuildContext context) {
    final String localeCode = l10n.locale.languageCode;

    return _ThemedSectionCard(
      semantic: semantic,
      icon: Icons.history_rounded,
      title: l10n.recentTransactions,
      actionLabel: l10n.viewAll,
      onActionTap: onViewAll,
      child: entriesAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: semantic.primary),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            '${l10n.errorGeneric}: $err',
            style: TextStyle(fontSize: 12, color: semantic.diya),
          ),
        ),
        data: (entries) {
          final recentEntries = entries
              .where((e) => e.status == TransactionStatus.recorded && e.archivedAt == null)
              .take(4)
              .toList();

          if (recentEntries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 30,
                    color: semantic.textSecondary.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noEntriesYet,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: semantic.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              for (int i = 0; i < recentEntries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 14,
                    endIndent: 14,
                    color: semantic.cardBorder.withValues(alpha: 0.7),
                  ),
                _RecentTransactionRow(
                  entry: recentEntries[i],
                  localeCode: localeCode,
                  semantic: semantic,
                  l10n: l10n,
                  onTap: () => onOpenEntryDetails?.call(recentEntries[i].id),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  final TransactionEntry entry;
  final String localeCode;
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _RecentTransactionRow({
    required this.entry,
    required this.localeCode,
    required this.semantic,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMila = entry.direction == TransactionDirection.received ||
        entry.direction == TransactionDirection.mila;
    final Color dirColor = isMila ? semantic.mila : semantic.diya;
    final Color dirContainer = isMila ? semantic.milaContainer : semantic.diyaContainer;
    final String dirLabel = isMila ? l10n.received : l10n.given;
    final String personTitle = entry.personName ?? l10n.unknownPerson;
    final String subtitleDate = AppDateUtils.formatRelativeDate(entry.transactionDate, localeCode);
    final String typeText = entry.items.isNotEmpty && entry.cashAmountPaise == 0
        ? '${entry.items.length} ${l10n.itemsCountSuffix}'
        : '${l10n.cash} ${CurrencyUtils.formatPaise(entry.cashAmountPaise)}';

    return ExpressSquish(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Direction Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: dirContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dirColor.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Text(
                dirLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: dirColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Person Avatar Badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: semantic.cardSubtleBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: semantic.cardBorder),
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: semantic.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 10),

            // Description & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.eventTitle != null && entry.eventTitle!.isNotEmpty
                        ? '$personTitle (${entry.eventTitle!})'
                        : personTitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: semantic.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitleDate • $typeText',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: semantic.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount + Chevron
            Text(
              CurrencyUtils.formatPaise(entry.cashAmountPaise),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: dirColor,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: semantic.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative corner radial glow & vector leaf curves painted strictly with theme colors.
class _HeroOrnamentPainter extends CustomPainter {
  final Color accentColor;

  const _HeroOrnamentPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Soft top-right ambient circle
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.25),
      size.height * 0.55,
      glowPaint,
    );

    final leafPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Subtle botanical stem on top-left corner
    final leftStem = Path()
      ..moveTo(-4, size.height * 0.45)
      ..quadraticBezierTo(18, size.height * 0.25, 28, 8);
    canvas.drawPath(leftStem, leafPaint);

    // Subtle botanical stem on bottom-right corner
    final rightStem = Path()
      ..moveTo(size.width + 4, size.height * 0.30)
      ..quadraticBezierTo(size.width - 20, size.height * 0.48, size.width - 28, size.height * 0.72);
    canvas.drawPath(rightStem, leafPaint);

    final leafFill = Paint()
      ..color = accentColor.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    // Small decorative leaves along left stem
    canvas.drawOval(
      Rect.fromCenter(center: Offset(10, size.height * 0.24), width: 10, height: 5),
      leafFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(18, size.height * 0.15), width: 9, height: 4.5),
      leafFill,
    );

    // Small decorative leaves along right stem
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width - 14, size.height * 0.46), width: 11, height: 5),
      leafFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width - 22, size.height * 0.58), width: 9, height: 4.5),
      leafFill,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroOrnamentPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

/// Mini 3-bar trend chart icon rendered cleanly with theme accent color.
class _MiniTrendBarsPainter extends CustomPainter {
  final Color color;
  final bool ascending;

  const _MiniTrendBarsPainter({
    required this.color,
    required this.ascending,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    const double barW = 4.5;
    final double gap = (size.width - barW * 3) / 2;
    final List<double> heights = ascending ? [0.42, 0.68, 0.95] : [0.50, 0.72, 0.90];

    for (int i = 0; i < 3; i++) {
      final double h = size.height * heights[i];
      final double x = i * (barW + gap);
      final double y = size.height - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(1.5),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTrendBarsPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.ascending != ascending;
  }
}
