import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../domain/entities/family_profile.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../services/backup_service.dart';

/// Clean, minimal & organized Settings screen inspired directly by InlitX/streak.
/// Features structured section cards, distinct icon badges, right-aligned trailing values,
/// zero AI filler text, and a native theme mode selection modal sheet.
class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenLanguageSelector;
  final VoidCallback onOpenReports;
  final VoidCallback? onOpenReminders;

  const SettingsScreen({
    super.key,
    required this.onOpenLanguageSelector,
    required this.onOpenReports,
    this.onOpenReminders,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final db = ref.watch(databaseProvider);
    final themeState = ref.watch(themeProvider);
    final backupService = BackupService(db);
    final familyProfileAsync = ref.watch(familyProfileProvider);
    final familyProfile = familyProfileAsync.value ?? const FamilyProfile();

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                AppSpacing.floatingTabBottomPadding + 28,
              ),
              children: [
                // 1. Primary Family Profile Hero Card (हमारी पारिवारिक प्रोफ़ाइल)
                _FamilyProfileHeroCard(
                  profile: familyProfile,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  l10n: l10n,
                  onTap: () {
                    if (familyProfile.isEmpty) {
                      context.push('/family-profile/edit');
                    } else {
                      context.push('/family-profile');
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 2. Section: Family Profile (पारिवारिक प्रोफ़ाइल विवरण)
                _SectionLabel(l10n.familySection),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    _StreakRow(
                      icon: Icons.family_restroom,
                      tint: const Color(0xFFEA580C),
                      title: l10n.myFamily,
                      value: familyProfile.familyName.isNotEmpty
                          ? familyProfile.familyName
                          : l10n.setupFamilyProfile,
                      onTap: () => context.push(
                        familyProfile.isEmpty ? '/family-profile/edit' : '/family-profile',
                      ),
                    ),
                    if (familyProfile.isNotEmpty) ...[
                      _StreakDivider(cardBorder: cardBorder),
                      _StreakRow(
                        icon: Icons.group_outlined,
                        tint: const Color(0xFF10B981),
                        title: l10n.familyMembers,
                        value: '${familyProfile.members.length}',
                        onTap: () => context.push('/family-profile'),
                      ),
                    ],
                  ],
                ),

                // 3. Hero Ledger Profile Banner (Streak _ProfileHero Style)
                _StreakHeroCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  appName: l10n.appName,
                  appTagline: l10n.appTagline,
                  badgeText: l10n.offlineGuaranteed,
                ),

                // 4. Section: Appearance & Themes (दिखावट व थीम)
                _SectionLabel(l10n.appearanceSection),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    _StreakRow(
                      icon: themeState.themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : (themeState.themeMode == ThemeMode.light
                              ? Icons.light_mode_outlined
                              : Icons.brightness_auto_outlined),
                      tint: const Color(0xFFF59E0B),
                      title: l10n.themeModeLabel,
                      value: themeState.themeMode == ThemeMode.dark
                          ? l10n.darkMode
                          : (themeState.themeMode == ThemeMode.light
                              ? l10n.lightMode
                              : l10n.systemDefault),
                      onTap: () => _showThemeModeSheet(
                        context: context,
                        themeState: themeState,
                        l10n: l10n,
                        cardBg: cardBg,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        primaryAccent: primaryAccent,
                      ),
                    ),
                    _StreakDivider(cardBorder: cardBorder),
                    _StreakRow(
                      icon: Icons.palette_outlined,
                      tint: const Color(0xFFA78BFA),
                      title: l10n.themeAndColors,
                      value: l10n.themePalettes,
                      trailing: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBorder, width: 1.5),
                        ),
                      ),
                      onTap: () => context.push('/theme'),
                    ),
                  ],
                ),

                // 3. Section: General & Preferences (सामान्य व भाषा)
                _SectionLabel(l10n.preferencesSection),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    _StreakRow(
                      icon: Icons.translate,
                      tint: const Color(0xFF38BDF8),
                      title: l10n.selectLanguage,
                      value: l10n.locale.languageCode.toUpperCase(),
                      onTap: widget.onOpenLanguageSelector,
                    ),
                    _StreakDivider(cardBorder: cardBorder),
                    _StreakRow(
                      icon: Icons.currency_rupee,
                      tint: const Color(0xFF10B981),
                      title: l10n.defaultCurrency,
                      value: '₹ INR',
                    ),
                  ],
                ),

                // 4. Section: Ledger & Reports (बही-खाता व रिपोर्ट)
                _SectionLabel(l10n.reportsAndReminders),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    _StreakRow(
                      icon: Icons.description_outlined,
                      tint: const Color(0xFF6366F1),
                      title: l10n.reports,
                      value: 'PDF / CSV',
                      onTap: widget.onOpenReports,
                    ),
                    if (widget.onOpenReminders != null) ...[
                      _StreakDivider(cardBorder: cardBorder),
                      _StreakRow(
                        icon: Icons.notifications_active_outlined,
                        tint: const Color(0xFFEAB308),
                        title: l10n.reminders,
                        onTap: widget.onOpenReminders,
                      ),
                    ],
                  ],
                ),

                // 5. Section: Data Backup & Security (डेटा व सुरक्षा)
                _SectionLabel(l10n.dataSection),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    _StreakRow(
                      icon: Icons.folder_zip_outlined,
                      tint: const Color(0xFF059669),
                      title: l10n.backup,
                      value: '.zip',
                      onTap: () => _handleEncryptedBackup(backupService, cardBg, textPrimary, primaryAccent),
                    ),
                    _StreakDivider(cardBorder: cardBorder),
                    _StreakRow(
                      icon: Icons.restore_page_outlined,
                      tint: const Color(0xFF2563EB),
                      title: l10n.restore,
                      value: '.zip / .json',
                      onTap: () => _handleRestoreBackup(backupService, cardBg, textPrimary, primaryAccent),
                    ),
                  ],
                ),

                // 6. Section: Privacy & Guarantee (पूर्णतः ऑफ़लाइन)
                _SectionLabel(l10n.privacySecurity),
                _StreakCard(
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.milaGreen.withValues(alpha: isDark ? 0.20 : 0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.shield_outlined, color: AppColors.milaGreen, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.offlineGuaranteeTitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.offlineGuaranteeSubtitle,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 7. Minimal Brand Footer (InlitX/streak Signature)
                const SizedBox(height: 36),
                Column(
                  children: [
                    Text(
                      'V Y A V A H A A R',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.5,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.appTagline,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.4+5 • Build Stable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        color: textSecondary.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showThemeModeSheet({
    required BuildContext context,
    required ThemeState themeState,
    required AppLocalizations l10n,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.themeModeLabel,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                _ThemeOptionTile(
                  icon: Icons.brightness_auto,
                  title: l10n.systemDefault,
                  selected: themeState.themeMode == ThemeMode.system,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
                _ThemeOptionTile(
                  icon: Icons.light_mode_outlined,
                  title: l10n.lightMode,
                  selected: themeState.themeMode == ThemeMode.light,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                _ThemeOptionTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.darkMode,
                  selected: themeState.themeMode == ThemeMode.dark,
                  primaryAccent: primaryAccent,
                  textPrimary: textPrimary,
                  onTap: () {
                    ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _invalidateAllAfterRestore() {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(entriesListProvider);
    ref.invalidate(activePeopleListProvider);
    ref.invalidate(archivedPeopleListProvider);
    ref.invalidate(activeEventsListProvider);
    ref.invalidate(archivedEventsListProvider);
    ref.invalidate(activeFamiliesListProvider);
    ref.invalidate(familyProfileProvider);
    ref.invalidate(customEventTypesProvider);
    ref.invalidate(entryProofProvider);
    ref.invalidate(eventDetailProvider);
    ref.invalidate(personHistoryStatsProvider);
    ref.invalidate(themeProvider);
    ref.invalidate(localeProvider);
  }

  Future<void> _handleEncryptedBackup(
    BackupService service,
    Color cardBg,
    Color textPrimary,
    Color primaryAccent,
  ) async {
    final l10n = context.l10n;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.backupZipTitle,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: l10n.backupPasswordOptionalHint,
            hintMaxLines: 2,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
            icon: const Icon(Icons.folder_zip_outlined, size: 17, color: Colors.white),
            label: Text(l10n.createZipBackupBtn, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final pwd = passwordController.text.trim();
      final result = await service.createZipBackup(
        password: pwd.isNotEmpty ? pwd : null,
      );
      if (!mounted) return;

      final sizeText = ImageStorageService.formatFileSize(result.fileSizeBytes);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.milaGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.backupSuccess,
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.basename(result.file.path)} ($sizeText)',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.tabBahi}: ${result.metadata.entriesCount} • '
                '${l10n.tabEvents}: ${result.metadata.eventsCount} • '
                '${l10n.tabPeople}: ${result.metadata.peopleCount} • '
                '${l10n.photosCountLabel}: ${result.metadata.imagesCount}',
                style: TextStyle(color: textPrimary.withValues(alpha: 0.78), fontSize: 12.5),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await BackupService.shareBackup(result.file);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
              icon: const Icon(Icons.share, size: 17, color: Colors.white),
              label: Text(l10n.shareSaveZipBackup, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreBackup(
    BackupService service,
    Color cardBg,
    Color textPrimary,
    Color primaryAccent,
  ) async {
    final l10n = context.l10n;
    // Use FileType.any because many Android SAF pickers hide .zip files with FileType.custom
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final ext = p.extension(file.path).toLowerCase();
    if (ext != '.zip' && ext != '.json') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidBackupFileError), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    BackupInspection inspection;
    try {
      inspection = await service.inspectBackup(file);
    } catch (err) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $err')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          inspection.isEncrypted ? l10n.enterRestorePassword : l10n.restoreConfirmTitle,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.restoreReplaceWarning,
              style: TextStyle(color: textPrimary.withValues(alpha: 0.8), fontSize: 12.5),
            ),
            if (inspection.entriesCount > 0 ||
                inspection.eventsCount > 0 ||
                inspection.peopleCount > 0 ||
                inspection.imagesCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.tabBahi}: ${inspection.entriesCount} • '
                '${l10n.tabEvents}: ${inspection.eventsCount} • '
                '${l10n.tabPeople}: ${inspection.peopleCount} • '
                '${l10n.photosCountLabel}: ${inspection.imagesCount}',
                style: TextStyle(color: primaryAccent, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
            if (inspection.isEncrypted) ...[
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.restorePasswordHint,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
            child: Text(l10n.restore, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (inspection.isEncrypted && passwordController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final restored = await service.restoreBackup(
        file,
        password: inspection.isEncrypted ? passwordController.text.trim() : null,
      );
      _invalidateAllAfterRestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.restoreSuccess} (${l10n.tabBahi}: ${restored.entriesRestored}, ${l10n.photosCountLabel}: ${restored.imagesRestored})',
            ),
            backgroundColor: AppColors.milaGreen,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Streak Hero Card for top profile / ledger branding
class _StreakHeroCard extends StatelessWidget {
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final String appName;
  final String appTagline;
  final String badgeText;

  const _StreakHeroCard({
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.appName,
    required this.appTagline,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.terracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const AppSymbol(
              size: 28,
              pageColor: AppColors.warmCream,
              checkmarkColor: AppColors.terracotta,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appTagline,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.milaGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.milaGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Streak Section Label (uppercase, small, tracked, positioned above cards)
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 22),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: color,
        ),
      ),
    );
  }
}

/// Streak Card (rounded 20px, subtle border, anti-aliased clipping)
class _StreakCard extends StatelessWidget {
  final List<Widget> children;
  final Color cardBg;
  final Color cardBorder;

  const _StreakCard({
    required this.children,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Streak Settings Row with soft icon badge, bold title, and right-aligned trailing value
class _StreakRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _StreakRow({
    required this.icon,
    required this.tint,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          // Icon Badge with soft tint
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: tint, size: 16),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: textPrimary,
              ),
            ),
          ),

          // Trailing Value Text
          if (value != null) ...[
            const SizedBox(width: 8),
            Text(
              value!,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],

          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],

          // Subtle Chevron
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// Streak Divider (indented 62px past icon badge)
class _StreakDivider extends StatelessWidget {
  final Color cardBorder;
  const _StreakDivider({required this.cardBorder});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      endIndent: 16,
      color: cardBorder,
    );
  }
}

/// Modal Sheet Tile for Theme Mode
class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final Color primaryAccent;
  final Color textPrimary;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.primaryAccent,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? primaryAccent : textPrimary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? primaryAccent : textPrimary,
        ),
      ),
      trailing: selected ? Icon(Icons.check_circle, color: primaryAccent, size: 20) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

/// Dynamic Family Profile Hero Card at top of Settings Screen
class _FamilyProfileHeroCard extends StatelessWidget {
  final FamilyProfile profile;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _FamilyProfileHeroCard({
    required this.profile,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.photoPath.isNotEmpty && File(profile.photoPath).existsSync();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.terracotta.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.terracotta.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                image: hasPhoto
                    ? DecorationImage(
                        image: FileImage(File(profile.photoPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasPhoto
                  ? const Icon(
                      Icons.family_restroom,
                      size: 28,
                      color: AppColors.terracotta,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.isNotEmpty && profile.familyName.isNotEmpty
                              ? profile.familyName
                              : l10n.setupFamilyProfile,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isNotEmpty && profile.members.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.milaGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${profile.members.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.milaGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.isNotEmpty
                        ? (profile.headOfFamily.isNotEmpty
                            ? '${l10n.mukhiyaBadge}: ${profile.headOfFamily}'
                            : (profile.nativePlace.isNotEmpty
                                ? profile.nativePlace
                                : l10n.myFamily))
                        : l10n.setupFamilyProfileSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 22, color: textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

