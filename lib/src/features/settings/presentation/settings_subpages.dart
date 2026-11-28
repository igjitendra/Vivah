import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_notifier.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/shortcuts/shortcuts_sheet.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/express_type.dart';
import '../../../../core/theme/theme_notifier.dart';
import '../../../../core/theme/ui_preferences_notifier.dart';
import '../../../../data/database/app_database.dart';
import '../../../../domain/entities/family_profile.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/express_settings_kit.dart';
import '../../../../shared/widgets/express_shapes.dart';
import '../../../../shared/widgets/express_squish.dart';
import '../../../../shared/widgets/profile_share_actions.dart';
import '../services/backup_service.dart';
import 'widgets/app_style_picker.dart';

const String kVyavahaarAppVersion = 'v1.0.14+15';

/// Renders either a segmented [ExpressGroup] or a divider-separated [ClassicCard].
class SettingsAdaptiveGroup extends StatelessWidget {
  final bool isExpress;
  final List<Widget> children;

  const SettingsAdaptiveGroup({
    super.key,
    required this.isExpress,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpress) return ExpressGroup(children: children);
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const ClassicDivider());
      spaced.add(children[i]);
    }
    return ClassicCard(children: spaced);
  }
}

/// Renders either an [ExpressTile] or a [ClassicRow] consistently.
class SettingsAdaptiveRow extends StatelessWidget {
  final bool isExpress;
  final IconData icon;
  final Color? tint;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsAdaptiveRow({
    super.key,
    required this.isExpress,
    required this.icon,
    this.tint,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpress) {
      return ExpressTile(
        icon: icon,
        tint: tint,
        title: title,
        subtitle: subtitle,
        value: value,
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ClassicRow(
      icon: icon,
      tint: tint,
      title: title,
      subtitle: subtitle,
      value: value,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// Renders an adaptive toggle row backed by Streak's morphing [ExpressSwitch].
class SettingsAdaptiveToggleRow extends StatelessWidget {
  final bool isExpress;
  final IconData icon;
  final Color? tint;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsAdaptiveToggleRow({
    super.key,
    required this.isExpress,
    required this.icon,
    this.tint,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpress) {
      return ExpressToggleTile(
        icon: icon,
        tint: tint,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
      );
    }
    return ClassicRow(
      icon: icon,
      tint: tint,
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: ExpressSwitch(
        value: value,
        onChanged: onChanged,
        tint: tint,
      ),
    );
  }
}

/// Sub-page 1: Appearance (Theme Mode, 25 Palettes, App Style, Animations, Compact View).
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;

    final activePalette =
        isDark ? themeState.darkPalette : themeState.lightPalette;
    final paletteLabel = l10n.isEnglish ? activePalette.name : activePalette.nameHindi;
    final modeLabel = switch (themeState.themeMode) {
      ThemeMode.light => l10n.lightMode,
      ThemeMode.dark => l10n.darkMode,
      ThemeMode.system => l10n.systemDefault,
    };

    return SettingsSubPageScaffold(
      title: l10n.appearanceSection,
      subtitle: l10n.appearanceSubtitle,
      isExpressStyle: isExpress,
      isCompact: uiPrefs.compactMode,
      children: [
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: themeState.themeMode == ThemeMode.dark
                  ? Icons.dark_mode_outlined
                  : (themeState.themeMode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.brightness_auto_outlined),
              tint: semantic.warning,
              title: l10n.themeModeLabel,
              subtitle: l10n.themeGallerySubtitle,
              value: modeLabel,
              onTap: () => showStreakOptionSheet<ThemeMode>(
                context: context,
                title: l10n.themeModeLabel,
                options: [
                  (
                    value: ThemeMode.system,
                    label: l10n.systemDefault,
                    subtitle: l10n.colorThemeAuto,
                    icon: Icons.brightness_auto_outlined,
                  ),
                  (
                    value: ThemeMode.light,
                    label: l10n.lightMode,
                    subtitle: l10n.colorThemeLight,
                    icon: Icons.light_mode_outlined,
                  ),
                  (
                    value: ThemeMode.dark,
                    label: l10n.darkMode,
                    subtitle: l10n.colorThemeDark,
                    icon: Icons.dark_mode_outlined,
                  ),
                ],
                selected: themeState.themeMode,
                onSelected: (mode) =>
                    ref.read(themeProvider.notifier).setThemeMode(mode),
              ),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.palette_outlined,
              tint: semantic.primary,
              title: l10n.themeAndColors,
              subtitle: l10n.themeAndColorsSubtitle,
              value: paletteLabel,
              trailing: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: semantic.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: semantic.cardBorder, width: 1.5),
                ),
              ),
              onTap: () => context.push('/theme'),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.style_outlined,
              tint: semantic.info,
              title: l10n.appStyleTitle,
              subtitle: l10n.appStyleSubtitle,
              value: isExpress ? l10n.styleExpressTitle : l10n.styleClassicTitle,
              onTap: () => showAppStylePickerSheet(context),
            ),
          ],
        ),
        ExpressSectionLabel(l10n.displayAndMotionSection),
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveToggleRow(
              isExpress: isExpress,
              icon: Icons.auto_awesome_outlined,
              tint: semantic.mila,
              title: l10n.animationsLabel,
              subtitle: l10n.animationsSubtitle,
              value: uiPrefs.animationsEnabled,
              onChanged: (v) =>
                  ref.read(uiPreferencesProvider.notifier).setAnimationsEnabled(v),
            ),
            SettingsAdaptiveToggleRow(
              isExpress: isExpress,
              icon: Icons.compress_rounded,
              tint: semantic.secondary,
              title: l10n.compactModeLabel,
              subtitle: l10n.compactModeSubtitle,
              value: uiPrefs.compactMode,
              onChanged: (v) =>
                  ref.read(uiPreferencesProvider.notifier).setCompactMode(v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sub-page 2: Preferences & Ledger (Language, Currency, Shortcuts, Reports, Reminders, Family, QR).
class PreferencesSettingsPage extends ConsumerWidget {
  final VoidCallback onOpenLanguageSelector;
  final VoidCallback onOpenReports;
  final VoidCallback? onOpenReminders;

  const PreferencesSettingsPage({
    super.key,
    required this.onOpenLanguageSelector,
    required this.onOpenReports,
    this.onOpenReminders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;
    final langSpec = ref.watch(currentLanguageSpecProvider);
    final familyProfile =
        ref.watch(familyProfileProvider).value ?? const FamilyProfile();
    final db = ref.watch(databaseProvider);

    return SettingsSubPageScaffold(
      title: l10n.preferencesSection,
      subtitle: l10n.preferencesSubtitle,
      isExpressStyle: isExpress,
      isCompact: uiPrefs.compactMode,
      children: [
        ExpressSectionLabel(l10n.generalCategory),
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.translate_rounded,
              tint: semantic.info,
              title: l10n.selectLanguage,
              value: langSpec.nameNative,
              onTap: onOpenLanguageSelector,
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.currency_rupee_rounded,
              tint: semantic.mila,
              title: l10n.defaultCurrency,
              value: '₹ INR',
              onTap: () => showStreakInfoSheet(
                context: context,
                icon: Icons.currency_rupee_rounded,
                title: l10n.defaultCurrency,
                description: l10n.currencyInfoSubtitle,
                badgeValue: l10n.currencyName,
                tint: semantic.mila,
              ),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.bolt_rounded,
              tint: semantic.warning,
              title: l10n.keyboardShortcuts,
              subtitle: l10n.desktopShortcutsHint,
              onTap: () => ShortcutsSheet.show(context),
            ),
          ],
        ),
        ExpressSectionLabel(l10n.ledgerAndFeaturesSection),
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.insights_rounded,
              tint: semantic.primary,
              title: l10n.reportsAndExports,
              value: 'PDF / CSV',
              onTap: onOpenReports,
            ),
            if (onOpenReminders != null)
              StreamBuilder<List<ReminderRow>>(
                stream: db.remindersDao.watchAllReminders(),
                builder: (context, snapshot) {
                  final pending = (snapshot.data ?? const <ReminderRow>[])
                      .where((r) => !r.isCompleted)
                      .length;
                  return SettingsAdaptiveRow(
                    isExpress: isExpress,
                    icon: Icons.notifications_active_outlined,
                    tint: semantic.diya,
                    title: l10n.reminders,
                    subtitle: l10n.remindersSubtitle,
                    value: pending > 0 ? '$pending ${l10n.pending}' : null,
                    onTap: onOpenReminders,
                  );
                },
              ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.family_restroom_rounded,
              tint: semantic.cashAccent,
              title: l10n.familyProfile,
              value: familyProfile.isNotEmpty
                  ? '${familyProfile.members.length} ${l10n.membersCount}'
                  : l10n.setupFamilyProfile,
              onTap: () => context.push(
                familyProfile.isEmpty ? '/family-profile/edit' : '/family-profile',
              ),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.qr_code_scanner_rounded,
              tint: semantic.giftAccent,
              title: l10n.scanVyavahaarQr,
              onTap: () => context.push('/scan-event'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sub-page 3: Data, Storage & Offline Privacy.
class DataBackupSettingsPage extends ConsumerStatefulWidget {
  final Future<void> Function() onCreateZipBackup;
  final Future<void> Function() onRestoreBackup;

  const DataBackupSettingsPage({
    super.key,
    required this.onCreateZipBackup,
    required this.onRestoreBackup,
  });

  @override
  ConsumerState<DataBackupSettingsPage> createState() =>
      _DataBackupSettingsPageState();
}

class _DataBackupSettingsPageState
    extends ConsumerState<DataBackupSettingsPage> {
  late Future<StorageOverviewStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _reloadStats();
  }

  void _reloadStats() {
    final db = ref.read(databaseProvider);
    _statsFuture = BackupService(db).getStorageOverview();
  }

  Future<void> _handleBackupTap() async {
    await widget.onCreateZipBackup();
    if (mounted) setState(_reloadStats);
  }

  Future<void> _handleRestoreTap() async {
    await widget.onRestoreBackup();
    if (mounted) setState(_reloadStats);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;

    return SettingsSubPageScaffold(
      title: l10n.dataSection,
      subtitle: l10n.dataBackupSubtitle,
      isExpressStyle: isExpress,
      isCompact: uiPrefs.compactMode,
      children: [
        _StorageOverviewCard(
          statsFuture: _statsFuture,
          onRefresh: () => setState(_reloadStats),
          isExpress: isExpress,
        ),
        const SizedBox(height: 16),
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.folder_zip_outlined,
              tint: semantic.mila,
              title: l10n.backup,
              subtitle: l10n.backupZipHint,
              value: '.zip',
              onTap: _handleBackupTap,
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.restore_page_outlined,
              tint: semantic.info,
              title: l10n.restore,
              subtitle: l10n.restoreZipHint,
              value: '.zip / .json',
              onTap: _handleRestoreTap,
            ),
          ],
        ),
        ExpressSectionLabel(l10n.privacySecurity),
        ExpressSquish(
          onTap: () => showStreakInfoSheet(
            context: context,
            icon: Icons.verified_user_outlined,
            title: l10n.offlineGuaranteeTitle,
            description: l10n.offlineGuaranteeSubtitle,
            badgeValue: 'AES-256-GCM • PBKDF2 600k',
            tint: semantic.mila,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: semantic.milaContainer,
              borderRadius: BorderRadius.circular(isExpress ? 22 : 18),
              border: Border.all(color: semantic.milaBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpressBlob(
                  size: 40,
                  color: semantic.milaBadgeBg,
                  shape: ExpressShape.cookie,
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: semantic.mila,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.offlineGuaranteeTitle,
                        style: ExpressType.titleMedium(
                          color: semantic.textPrimary,
                          weight: FontWeight.w800,
                        ).copyWith(fontSize: 15.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.offlineGuaranteeSubtitle,
                        style: ExpressType.bodySmall(
                          color: semantic.textSecondary,
                        ).copyWith(fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StorageOverviewCard extends StatelessWidget {
  final Future<StorageOverviewStats> statsFuture;
  final VoidCallback onRefresh;
  final bool isExpress;

  const _StorageOverviewCard({
    required this.statsFuture,
    required this.onRefresh,
    required this.isExpress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(isExpress ? 24 : 20),
        border: Border.all(color: semantic.cardBorder),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FutureBuilder<StorageOverviewStats>(
        future: statsFuture,
        builder: (context, snapshot) {
          final stats = snapshot.data ?? const StorageOverviewStats();
          final loading = snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final sizeStr =
              ImageStorageService.formatFileSize(stats.photosTotalBytes);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExpressBlob(
                    size: 36,
                    color: semantic.infoContainer,
                    shape: ExpressShape.cookie,
                    child: Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 18,
                      color: semantic.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.storageOverviewTitle,
                          style: ExpressType.titleMedium(
                            color: semantic.textPrimary,
                            weight: FontWeight.w800,
                          ).copyWith(fontSize: 15),
                        ),
                        Text(
                          '${l10n.storagePhotosSizeLabel}: ${stats.photosCount} • $sizeStr',
                          style: ExpressType.bodySmall(
                            color: semantic.textSecondary,
                          ).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 19,
                      color: semantic.textSecondary,
                    ),
                    tooltip: l10n.storageOverviewTitle,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                LinearProgressIndicator(
                  color: semantic.primary,
                  backgroundColor: semantic.cardSubtleBg,
                  minHeight: 3,
                )
              else
                Row(
                  children: [
                    _MiniMetricCell(
                      value: '${stats.entriesCount}',
                      label: l10n.tabBahi,
                      tint: semantic.primary,
                      semantic: semantic,
                    ),
                    _MiniMetricDivider(semantic: semantic),
                    _MiniMetricCell(
                      value: '${stats.eventsCount}',
                      label: l10n.tabEvents,
                      tint: semantic.info,
                      semantic: semantic,
                    ),
                    _MiniMetricDivider(semantic: semantic),
                    _MiniMetricCell(
                      value: '${stats.peopleCount}',
                      label: l10n.tabPeople,
                      tint: semantic.secondary,
                      semantic: semantic,
                    ),
                    _MiniMetricDivider(semantic: semantic),
                    _MiniMetricCell(
                      value: '${stats.photosCount}',
                      label: l10n.photosCountLabel,
                      tint: semantic.mila,
                      semantic: semantic,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniMetricCell extends StatelessWidget {
  final String value;
  final String label;
  final Color tint;
  final AppSemanticColors semantic;

  const _MiniMetricCell({
    required this.value,
    required this.label,
    required this.tint,
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
              style: ExpressType.titleLarge(
                color: tint,
                weight: FontWeight.w800,
              ).copyWith(fontSize: 19, height: 1.1),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ExpressType.labelSmall(
              color: semantic.textSecondary,
              weight: FontWeight.w700,
            ).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricDivider extends StatelessWidget {
  final AppSemanticColors semantic;

  const _MiniMetricDivider({required this.semantic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: semantic.cardBorder,
    );
  }
}

/// Sub-page 4: About Vyavahaar inspired by Streak's AboutPage.
class AboutVyavahaarPage extends ConsumerWidget {
  const AboutVyavahaarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;
    final familyProfile =
        ref.watch(familyProfileProvider).value ?? const FamilyProfile();

    return SettingsSubPageScaffold(
      title: l10n.aboutAppTitle,
      subtitle: l10n.aboutAppSubtitle,
      isExpressStyle: isExpress,
      isCompact: uiPrefs.compactMode,
      children: [
        const SizedBox(height: 6),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: semantic.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: semantic.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: semantic.primary.withValues(alpha: 0.28),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/brand/vyavahaar-icon-512.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: AppSymbol(
                    size: 48,
                    pageColor: semantic.secondary,
                    checkmarkColor: semantic.primary,
                    accentColor: semantic.primary,
                    useAssetFallback: false,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            l10n.appName,
            style: ExpressType.displaySmall(
              color: semantic.textPrimary,
            ).copyWith(fontWeight: FontWeight.w900, fontSize: 32),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            l10n.appTagline,
            textAlign: TextAlign.center,
            style: ExpressType.bodyLarge(
              color: semantic.textSecondary,
              weight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: semantic.cardBg,
            borderRadius: BorderRadius.circular(isExpress ? 24 : 20),
            border: Border.all(color: semantic.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExpressBlob(
                    size: 36,
                    color: semantic.milaContainer,
                    shape: ExpressShape.flower,
                    child: Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: semantic.mila,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.aboutPhilosophyTitle,
                      style: ExpressType.titleMedium(
                        color: semantic.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.aboutPhilosophyBody,
                style: ExpressType.bodyMedium(
                  color: semantic.textSecondary,
                ).copyWith(height: 1.55, fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SettingsAdaptiveGroup(
          isExpress: isExpress,
          children: [
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.auto_stories_outlined,
              tint: semantic.primary,
              title: l10n.onboardingAppTour,
              subtitle: l10n.onboardingTourSubtitle,
              onTap: () => context.push('/onboarding?fromSettings=true'),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.qr_code_2_rounded,
              tint: semantic.mila,
              title: l10n.shareFamilyProfile,
              onTap: () {
                if (familyProfile.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.setupFamilyFirstHint)),
                  );
                  context.push('/family-profile/edit');
                } else {
                  ProfileShareActions.showFamilyProfileShareSheet(
                    context,
                    familyProfile,
                  );
                }
              },
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.bolt_rounded,
              tint: semantic.warning,
              title: l10n.keyboardShortcuts,
              subtitle: l10n.desktopShortcutsHint,
              onTap: () => ShortcutsSheet.show(context),
            ),
            SettingsAdaptiveRow(
              isExpress: isExpress,
              icon: Icons.verified_outlined,
              tint: semantic.info,
              title: l10n.appVersion,
              value: kVyavahaarAppVersion,
              onTap: () => showStreakInfoSheet(
                context: context,
                icon: Icons.verified_outlined,
                title: '${l10n.appName} $kVyavahaarAppVersion',
                description: l10n.offlineGuaranteeSubtitle,
                badgeValue: l10n.offlineGuaranteed,
                tint: semantic.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Column(
          children: [
            ExpressBlob(
              size: 48,
              color: semantic.primary.withValues(alpha: 0.14),
              shape: ExpressShape.flower,
              child: Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: semantic.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'V Y A V A H A A R  $kVyavahaarAppVersion',
              style: ExpressType.labelSmall(
                color: semantic.textSecondary.withValues(alpha: 0.72),
                weight: FontWeight.w800,
              ).copyWith(letterSpacing: 2.2),
            ),
          ],
        ),
      ],
    );
  }
}
