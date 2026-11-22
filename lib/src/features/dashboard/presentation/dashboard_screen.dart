import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/app_logo.dart';

/// Modern Material 3 Card-Based Dashboard for व्यवहार (Vyavahaar)
/// Fully theme-adaptive (Light / Dark & Color Palettes) with tactile ExpressSquish feedback.
class DashboardScreen extends StatelessWidget {
  final DashboardSummary summary;
  final VoidCallback onNewEntry;
  final VoidCallback onNewEvent;
  final VoidCallback onNewPerson;
  final VoidCallback onOpenSettings;
  final ValueChanged<String>? onOpenEventDetails;

  const DashboardScreen({
    super.key,
    required this.summary,
    required this.onNewEntry,
    required this.onNewEvent,
    required this.onNewPerson,
    required this.onOpenSettings,
    this.onOpenEventDetails,
  });

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // A. Premium Material 3 Header
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 12,
              bottom: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black38 : const Color(0x2A0F172A),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.appTagline,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                ExpressSquish(
                  scale: 0.90,
                  onTap: onOpenSettings,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.floatingTabBottomPadding,
              ),
              children: [
                // B. Financial Summary Cards (Mila vs Diya - Material 3 Elevated)
                Row(
                  children: [
                    // Card 1: Total Received (कुल मिला)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF132A1C) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.milaGreen.withValues(alpha: isDark ? 0.45 : 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : const Color(0x0C15803D),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C3D2A) : AppColors.milaGreenSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.milaGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.arrow_downward, size: 14, color: AppColors.milaGreen),
                                ),
                                const SizedBox(width: 8),
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
                            const SizedBox(height: 10),
                            Text(
                              CurrencyUtils.formatPaise(summary.totalMilaPaise),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.milaGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C3D2A) : AppColors.milaGreenSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.received,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.milaGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Card 2: Total Given (कुल दिया)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2E1517) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.diyaRed.withValues(alpha: isDark ? 0.45 : 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : const Color(0x0CB91C1C),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF421D20) : AppColors.diyaRedSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.diyaRed.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.arrow_upward, size: 14, color: AppColors.diyaRed),
                                ),
                                const SizedBox(width: 8),
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
                            const SizedBox(height: 10),
                            Text(
                              CurrencyUtils.formatPaise(summary.totalDiyaPaise),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.diyaRed,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF421D20) : AppColors.diyaRedSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.given,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.diyaRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // C. Overview Statistics Strip (Material 3 Card)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black12 : const Color(0x08000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                      ),
                      Container(width: 1, height: 36, color: cardBorder),
                      _StatColumn(
                        icon: Icons.people_outline,
                        iconColor: isDark ? const Color(0xFF93C5FD) : theme.colorScheme.secondary,
                        label: l10n.tabPeople,
                        value: '${summary.totalPeople}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      Container(width: 1, height: 36, color: cardBorder),
                      _StatColumn(
                        icon: Icons.receipt_long_outlined,
                        iconColor: primaryAccent,
                        label: l10n.tabBahi,
                        value: '${summary.totalEntries}',
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // D. Recent Event Showcase Card
                Text(
                  l10n.recentEvent,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (summary.recentEventTitle != null)
                  ExpressCard(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    radius: 18,
                    color: cardBg,
                    borderColor: cardBorder,
                    elevation: 1,
                    onTap: () {
                      if (summary.recentEventId != null) {
                        onOpenEventDetails?.call(summary.recentEventId!);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.celebration, color: primaryAccent, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.recentEventTitle!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              if (summary.recentEventDate != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 12, color: textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      AppDateUtils.formatIsoDate(summary.recentEventDate, l10n.locale.languageCode),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right, color: textSecondary, size: 18),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_available_outlined, size: 36, color: textSecondary.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noRecentEvent,
                            style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // E. Quick Actions Section
                Text(
                  l10n.quickActions,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Primary Quick Action: Record New Transaction
                ExpressSquish(
                  scale: 0.97,
                  onTap: onNewEntry,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md + 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_card, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.newTransaction,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.newEntrySubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Secondary Actions Row: New Event & New Person
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.calendar_month_outlined,
                        iconColor: primaryAccent,
                        title: l10n.newEvent,
                        subtitle: l10n.newEventSubtitle,
                        onTap: onNewEvent,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.person_add_outlined,
                        iconColor: primaryAccent,
                        title: l10n.newPerson,
                        subtitle: l10n.newPersonSubtitle,
                        onTap: onNewPerson,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
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

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
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
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ExpressCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      radius: 16,
      color: cardBg,
      borderColor: cardBorder,
      elevation: 0,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
