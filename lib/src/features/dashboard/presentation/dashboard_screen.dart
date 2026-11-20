import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/entities.dart';

/// Redesigned Home Screen for व्यवहार (Vyavahaar) in Flutter
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
    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: Column(
        children: [
          // A. Compact Deep Navy Header
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 10,
              bottom: AppSpacing.lg,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.deepNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.surfaceWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined, color: AppColors.warmCream),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x1FFFFFFF),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Content ScrollView
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.floatingTabBottomPadding,
              ),
              children: [
                // B. Financial Summary (Mila vs Diya Strictly Separated)
                Row(
                  children: [
                    // Card 1: Kul Mila
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: AppColors.milaGreenSoft,
                          borderRadius: AppRadius.roundedCard,
                          border: Border.all(color: const Color(0x33209B68)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD1F2E0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_downward, size: 14, color: AppColors.milaGreen),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  AppStrings.totalMila,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.milaGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                            const Text(
                              AppStrings.receivedAmount,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Card 2: Kul Diya
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: AppColors.diyaRedSoft,
                          borderRadius: AppRadius.roundedCard,
                          border: Border.all(color: const Color(0x33DC2626)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFBD5D2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_upward, size: 14, color: AppColors.diyaRed),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  AppStrings.totalDiya,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.diyaRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
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
                            const Text(
                              AppStrings.givenAmount,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // C. Overview Statistics (Unified Single-Bar Layout)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppRadius.roundedCard,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      _StatColumn(
                        icon: Icons.calendar_today_outlined,
                        label: AppStrings.tabEvents,
                        value: '${summary.totalEvents}',
                      ),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _StatColumn(
                        icon: Icons.people_outline,
                        label: AppStrings.tabPeople,
                        value: '${summary.totalPeople}',
                      ),
                      Container(width: 1, height: 32, color: AppColors.divider),
                      _StatColumn(
                        icon: Icons.book_outlined,
                        label: AppStrings.tabBahi,
                        value: '${summary.totalEntries}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // D. Current / Recent Event
                const Text(
                  AppStrings.recentEvent,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (summary.recentEventTitle != null)
                  InkWell(
                    onTap: () {
                      if (summary.recentEventId != null) {
                        onOpenEventDetails?.call(summary.recentEventId!);
                      }
                    },
                    borderRadius: AppRadius.roundedCard,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: AppRadius.roundedCard,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEEE8),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.celebration_outlined, color: AppColors.terracotta, size: 22),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.recentEventTitle!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (summary.recentEventDate != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    AppDateUtils.formatHindiDate(summary.recentEventDate),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: AppRadius.roundedCard,
                      border: Border.all(color: AppColors.borderLight, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          AppStrings.noRecentEvent,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // E. Quick Actions
                const Text(
                  AppStrings.quickActions,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Primary Terracotta Action
                InkWell(
                  onTap: onNewEntry,
                  borderRadius: AppRadius.roundedCard,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md + 2),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: AppRadius.roundedCard,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x38C05A2B),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.surfaceWhite, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                AppStrings.newEntry,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.surfaceWhite,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                AppStrings.newEntrySubtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xD9FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: AppColors.surfaceWhite, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Secondary Action 1: New Event
                _ActionTile(
                  icon: Icons.calendar_today_outlined,
                  title: AppStrings.newEvent,
                  subtitle: AppStrings.newEventSubtitle,
                  onTap: onNewEvent,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Secondary Action 2: New Person
                _ActionTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: AppStrings.newPerson,
                  subtitle: AppStrings.newPersonSubtitle,
                  onTap: onNewPerson,
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
  final String label;
  final String value;

  const _StatColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF1F8),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.deepNavy, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
