import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/shortcuts/shortcuts_sheet.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/family_profile.dart';
import '../../../shared/widgets/express_squish.dart';

/// Hub screen for the 5th bottom navigation tab ("More" / "अधिक").
/// Uses [AppSemanticColors] exclusively with zero hardcoded color literals.
class MoreScreen extends ConsumerWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenLanguageSelector;
  final VoidCallback onOpenThemeGallery;
  final ValueChanged<bool> onOpenFamilyProfile;
  final VoidCallback onOpenOnboarding;

  const MoreScreen({
    super.key,
    required this.onOpenSettings,
    required this.onOpenReports,
    required this.onOpenReminders,
    required this.onOpenLanguageSelector,
    required this.onOpenThemeGallery,
    required this.onOpenFamilyProfile,
    required this.onOpenOnboarding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final db = ref.watch(databaseProvider);
    final familyProfile = ref.watch(familyProfileProvider).value ?? const FamilyProfile();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.moreTitle),
        backgroundColor: semantic.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ExpressSquish(
              scale: 0.92,
              onTap: onOpenSettings,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: 19,
                  color: semantic.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ReminderRow>>(
        stream: db.remindersDao.watchAllReminders(),
        builder: (context, reminderSnapshot) {
          final pendingCount = (reminderSnapshot.data ?? const <ReminderRow>[])
              .where((r) => !r.isCompleted)
              .length;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.floatingTabBottomPadding + 16,
            ),
            children: [
              // 1. Family Profile Banner Card
              _FamilyBannerCard(
                semantic: semantic,
                l10n: l10n,
                profile: familyProfile,
                onTap: () => onOpenFamilyProfile(familyProfile.isEmpty),
              ),

              const SizedBox(height: AppSpacing.md),

              // 2. Quick Utility Bento Grid (Reports, Reminders, Themes, Language)
              Row(
                children: [
                  Expanded(
                    child: _MoreGridTile(
                      icon: Icons.picture_as_pdf_rounded,
                      title: l10n.reportsAndExports,
                      subtitle: 'PDF / CSV',
                      accentColor: semantic.warning,
                      containerColor: semantic.warningContainer,
                      semantic: semantic,
                      onTap: onOpenReports,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MoreGridTile(
                      icon: Icons.notifications_active_rounded,
                      title: l10n.reminders,
                      subtitle: pendingCount > 0 ? '$pendingCount ${l10n.pending}' : l10n.viewShort,
                      badgeText: pendingCount > 0 ? '$pendingCount' : null,
                      accentColor: semantic.diya,
                      containerColor: semantic.diyaContainer,
                      semantic: semantic,
                      onTap: onOpenReminders,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _MoreGridTile(
                      icon: Icons.palette_rounded,
                      title: l10n.appearanceAndThemes,
                      subtitle: l10n.themePalettes,
                      accentColor: semantic.primary,
                      containerColor: semantic.heroCardBg,
                      semantic: semantic,
                      onTap: onOpenThemeGallery,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MoreGridTile(
                      icon: Icons.translate_rounded,
                      title: l10n.selectLanguage,
                      subtitle: l10n.locale.languageCode.toUpperCase(),
                      accentColor: semantic.info,
                      containerColor: semantic.infoContainer,
                      semantic: semantic,
                      onTap: onOpenLanguageSelector,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. System, Backup & Settings Card
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: semantic.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: semantic.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _MoreListTile(
                      icon: Icons.settings_outlined,
                      iconColor: semantic.secondary,
                      iconBg: semantic.cardSubtleBg,
                      title: l10n.settingsTitle,
                      subtitle: '${l10n.backupAndRestore} • AES-256',
                      semantic: semantic,
                      onTap: onOpenSettings,
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 62,
                      color: semantic.cardBorder.withValues(alpha: 0.7),
                    ),
                    _MoreListTile(
                      icon: Icons.auto_stories_outlined,
                      iconColor: semantic.mila,
                      iconBg: semantic.milaContainer,
                      title: l10n.onboardingAppTour,
                      subtitle: l10n.onboardingTourSubtitle,
                      semantic: semantic,
                      onTap: onOpenOnboarding,
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 62,
                      color: semantic.cardBorder.withValues(alpha: 0.7),
                    ),
                    _MoreListTile(
                      icon: Icons.bolt_rounded,
                      iconColor: semantic.warning,
                      iconBg: semantic.warningContainer,
                      title: l10n.keyboardShortcuts,
                      subtitle: l10n.desktopShortcutsHint,
                      semantic: semantic,
                      onTap: () => ShortcutsSheet.show(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 4. Offline Privacy Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: semantic.milaContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: semantic.milaBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: semantic.milaBadgeBg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: semantic.mila,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.offlineGuaranteeTitle,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: semantic.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.offlineGuaranteeSubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: semantic.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyBannerCard extends StatelessWidget {
  final AppSemanticColors semantic;
  final AppLocalizations l10n;
  final FamilyProfile profile;
  final VoidCallback onTap;

  const _FamilyBannerCard({
    required this.semantic,
    required this.l10n,
    required this.profile,
    required this.onTap,
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
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [semantic.heroStart, semantic.heroEnd],
          ),
          borderRadius: BorderRadius.circular(18),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: semantic.heroHighlight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: semantic.heroHighlight.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.home_rounded,
                color: semantic.heroHighlight,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: semantic.heroHighlight,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreGridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color accentColor;
  final Color containerColor;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _MoreGridTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.accentColor,
    required this.containerColor,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.96,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: accentColor),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: semantic.badgeAlertBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 10.5,
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
            const SizedBox(height: 10),
            Text(
              title,
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
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: semantic.textSecondary,
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

class _MoreListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _MoreListTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressSquish(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: semantic.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: semantic.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: semantic.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
