import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/enums/transaction_enums.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/app_logo.dart';

/// Modern, Minimal & Tactile Dashboard for व्यवहार (Vyavahaar)
/// Inspired by InlitX/streak: clean typography, spring physics, zero AI filler text.
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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final double topPadding = MediaQuery.of(context).padding.top;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    ref.watch(liveDateProvider); // Live date reactivity ticker
    final entriesAsync = ref.watch(entriesListProvider(null));

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // 1. Sleek & Confident Header (Zero Slogans / Filler)
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              bottom: AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black38 : const Color(0x1F0F172A),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const AppSymbol(
                        size: 22,
                        pageColor: AppColors.warmCream,
                        checkmarkColor: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Live Date Capsule Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80), // Live pulse green dot
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppDateUtils.getLiveTodayHeaderString(l10n.locale.languageCode),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExpressSquish(
                      scale: 0.90,
                      onTap: onOpenSettings,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.floatingTabBottomPadding,
              ),
              children: [
                // A. Financial Overview: Mila vs Diya (Hero Cards with Spring Touch)
                Row(
                  children: [
                    // Card 1: Total Received (कुल मिला)
                    Expanded(
                      child: ExpressSquish(
                        scale: 0.96,
                        onTap: onFilterMila ?? onViewAllEntries,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF132A1C) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.milaGreen.withValues(alpha: isDark ? 0.45 : 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : const Color(0x0C15803D),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1C3D2A) : AppColors.milaGreenSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_downward, size: 13, color: AppColors.milaGreen),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.totalReceived,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.milaGreen,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyUtils.formatPaise(summary.totalMilaPaise),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.milaGreen,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // Card 2: Total Given (कुल दिया)
                    Expanded(
                      child: ExpressSquish(
                        scale: 0.96,
                        onTap: onFilterDiya ?? onViewAllEntries,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E1517) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.diyaRed.withValues(alpha: isDark ? 0.45 : 0.25),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black26 : const Color(0x0CB91C1C),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF421D20) : AppColors.diyaRedSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_upward, size: 13, color: AppColors.diyaRed),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.totalGiven,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.diyaRed,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyUtils.formatPaise(summary.totalDiyaPaise),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.diyaRed,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // B. Stats Capsule Strip (Interactive Shortcuts)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      _StatColumn(
                        icon: Icons.celebration_outlined,
                        iconColor: AppColors.gold,
                        label: l10n.tabEvents,
                        value: '${summary.totalEvents}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: onViewAllEvents,
                      ),
                      Container(width: 1, height: 28, color: cardBorder),
                      _StatColumn(
                        icon: Icons.people_outline,
                        iconColor: isDark ? const Color(0xFF93C5FD) : theme.colorScheme.secondary,
                        label: l10n.tabPeople,
                        value: '${summary.totalPeople}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: onViewAllPeople,
                      ),
                      Container(width: 1, height: 28, color: cardBorder),
                      _StatColumn(
                        icon: Icons.receipt_long_outlined,
                        iconColor: primaryAccent,
                        label: l10n.tabBahi,
                        value: '${summary.totalEntries}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onTap: onViewAllEntries,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // C. Action Buttons: Dedicated + मिला (Received) and + दिया (Given) Buttons
                Row(
                  children: [
                    Expanded(
                      child: ExpressButton(
                        label: l10n.recordMilaShort,
                        icon: Icons.south_west_rounded,
                        tint: AppColors.milaGreen,
                        expand: true,
                        onPressed: onNewEntryReceived ?? onNewEntry,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ExpressButton(
                        label: l10n.recordDiyaShort,
                        icon: Icons.north_east_rounded,
                        tint: AppColors.diyaRed,
                        expand: true,
                        onPressed: onNewEntryGiven ?? onNewEntry,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionChip(
                        icon: Icons.celebration_outlined,
                        label: l10n.newEvent,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textPrimary,
                        iconColor: primaryAccent,
                        onTap: onNewEvent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _QuickActionChip(
                        icon: Icons.person_add_outlined,
                        label: l10n.newPerson,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textColor: textPrimary,
                        iconColor: primaryAccent,
                        onTap: onNewPerson,
                      ),
                    ),
                  ],
                ),

                // D. Recent Event Showcase (Only Rendered if an Event Exists)
                if (summary.recentEventTitle != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ExpressCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    radius: 14,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 0,
                    onTap: () {
                      if (summary.recentEventId != null) {
                        onOpenEventDetails?.call(summary.recentEventId!);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.celebration, color: primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.recentEventTitle!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (summary.recentEventDate != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  AppDateUtils.formatIsoDate(summary.recentEventDate, l10n.locale.languageCode),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: textSecondary, size: 18),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

                // E. Recent Transactions Section (Real Ledger Peek)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.transactions,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAllEntries,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.viewAll,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryAccent,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 16, color: primaryAccent),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Transactions List Feed
                entriesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      '${l10n.errorGeneric}: $err',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                  data: (entries) {
                    final recentEntries = entries
                        .where((e) => e.status == TransactionStatus.recorded && e.archivedAt == null)
                        .take(4)
                        .toList();

                    if (recentEntries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 32, color: textSecondary.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text(
                                l10n.noEntriesYet,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: recentEntries.map((entry) {
                        final isMila = entry.direction == TransactionDirection.received ||
                            entry.direction == TransactionDirection.mila;
                        final amountColor = isMila ? AppColors.milaGreen : AppColors.diyaRed;
                        final prefix = isMila ? '+' : '-';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: ExpressSquish(
                            scale: 0.98,
                            onTap: () => onOpenEntryDetails?.call(entry.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isMila
                                          ? (isDark ? const Color(0xFF1B3D28) : AppColors.milaGreenSoft)
                                          : (isDark ? const Color(0xFF421D20) : AppColors.diyaRedSoft),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isMila ? Icons.arrow_downward : Icons.arrow_upward,
                                      size: 14,
                                      color: amountColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.personName ?? l10n.unknownPerson,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (entry.eventTitle != null && entry.eventTitle!.isNotEmpty) ...[
                                              Flexible(
                                                child: Text(
                                                  entry.eventTitle!,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: primaryAccent,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text('•', style: TextStyle(fontSize: 10, color: textSecondary)),
                                              const SizedBox(width: 4),
                                            ],
                                            Text(
                                              AppDateUtils.formatRelativeDate(entry.transactionDate, l10n.locale.languageCode),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: AppDateUtils.isToday(entry.transactionDate) ? FontWeight.bold : FontWeight.normal,
                                                color: AppDateUtils.isToday(entry.transactionDate) ? primaryAccent : textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$prefix${CurrencyUtils.formatPaise(entry.cashAmountPaise)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: amountColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ExpressSquish(
        scale: 0.95,
        onTap: onTap,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cardBg;
  final Color cardBorder;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.cardBg,
    required this.cardBorder,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
