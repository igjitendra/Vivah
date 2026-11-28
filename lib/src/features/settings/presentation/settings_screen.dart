import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../app/app_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_notifier.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/express_type.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../core/theme/ui_preferences_notifier.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/family_profile.dart';
import '../../../shared/widgets/express_button.dart';
import '../../../shared/widgets/express_settings_kit.dart';
import '../../../shared/widgets/express_shapes.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../shared/widgets/profile_share_actions.dart';
import '../services/backup_service.dart';
import 'settings_subpages.dart';
import 'widgets/app_style_picker.dart';

/// Organized Settings Hub adapted directly from InlitX/streak architecture.
/// Features a top Family Profile Hero with Edit + QR pills, App Style selector,
/// 4 clean category hubs with dedicated sub-pages (and 2x2 Bento grid on wide viewports),
/// Express / Classic style switching, and full ZIP + photo backup/restore.
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
  void _pushSubPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _openFamilyShare(FamilyProfile profile) {
    final l10n = context.l10n;
    if (profile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.setupFamilyFirstHint)),
      );
      context.push('/family-profile/edit');
      return;
    }
    ProfileShareActions.showFamilyProfileShareSheet(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final uiPrefs = ref.watch(uiPreferencesProvider);
    final isExpress = uiPrefs.isExpressStyle;
    final familyProfile =
        ref.watch(familyProfileProvider).value ?? const FamilyProfile();
    final wideGrid = !isPhone(context) && isExpress;

    final canPop = Navigator.of(context).canPop();

    return CompactDensity(
      isCompact: uiPrefs.compactMode,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: isExpress
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 54,
                leadingWidth: canPop ? 66 : null,
                shape: const Border(),
                leading: canPop
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Center(
                          child: ExpressIconButton(
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      )
                    : null,
              )
            : AppBar(
                title: Text(
                  l10n.settingsTitle,
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
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                18,
                isExpress ? 2 : 12,
                18,
                AppSpacing.floatingTabBottomPadding + 28,
              ),
              children: [
                if (isExpress) ...[
                  ExpressReveal(
                    index: 0,
                    child: ExpressHeadline(
                      title: l10n.settingsTitle,
                      subtitle: l10n.settingsHubSubtitle,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                ExpressReveal(
                  index: 1,
                  child: _SettingsProfileHero(
                    profile: familyProfile,
                    isExpress: isExpress,
                    onTapCard: () => context.push(
                      familyProfile.isEmpty
                          ? '/family-profile/edit'
                          : '/family-profile',
                    ),
                    onTapEdit: () => context.push('/family-profile/edit'),
                    onTapQrShare: () => _openFamilyShare(familyProfile),
                  ),
                ),
                SizedBox(height: uiPrefs.compactMode ? 12 : 16),
                ExpressReveal(
                  index: 2,
                  child: SettingsAdaptiveGroup(
                    isExpress: isExpress,
                    children: [
                      SettingsAdaptiveRow(
                        isExpress: isExpress,
                        icon: Icons.style_outlined,
                        tint: semantic.primary,
                        title: l10n.appStyleTitle,
                        value: isExpress
                            ? l10n.styleExpressTitle
                            : l10n.styleClassicTitle,
                        onTap: () => showAppStylePickerSheet(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: uiPrefs.compactMode ? 14 : 20),
                if (wideGrid) ...[
                  ExpressReveal(
                    index: 3,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ExpressBentoTile(
                              icon: Icons.palette_outlined,
                              tint: semantic.primary,
                              title: l10n.appearanceSection,
                              subtitle: l10n.appearanceSubtitle,
                              onTap: () =>
                                  _pushSubPage(const AppearanceSettingsPage()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ExpressBentoTile(
                              icon: Icons.tune_rounded,
                              tint: semantic.info,
                              title: l10n.preferencesSection,
                              subtitle: l10n.preferencesSubtitle,
                              onTap: () => _pushSubPage(
                                PreferencesSettingsPage(
                                  onOpenLanguageSelector:
                                      widget.onOpenLanguageSelector,
                                  onOpenReports: widget.onOpenReports,
                                  onOpenReminders: widget.onOpenReminders,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ExpressReveal(
                    index: 4,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ExpressBentoTile(
                              icon: Icons.folder_zip_outlined,
                              tint: semantic.mila,
                              title: l10n.dataSection,
                              subtitle: l10n.dataBackupSubtitle,
                              onTap: () => _pushSubPage(
                                DataBackupSettingsPage(
                                  onCreateZipBackup: _runEncryptedBackupFlow,
                                  onRestoreBackup: _runRestoreBackupFlow,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ExpressBentoTile(
                              icon: Icons.info_outline_rounded,
                              tint: semantic.warning,
                              title: l10n.aboutAppTitle,
                              subtitle: l10n.aboutAppSubtitle,
                              onTap: () =>
                                  _pushSubPage(const AboutVyavahaarPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ExpressReveal(
                    index: 3,
                    child: SettingsAdaptiveGroup(
                      isExpress: isExpress,
                      children: [
                        SettingsAdaptiveRow(
                          isExpress: isExpress,
                          icon: Icons.palette_outlined,
                          tint: semantic.primary,
                          title: l10n.appearanceSection,
                          subtitle: l10n.appearanceSubtitle,
                          onTap: () =>
                              _pushSubPage(const AppearanceSettingsPage()),
                        ),
                        SettingsAdaptiveRow(
                          isExpress: isExpress,
                          icon: Icons.tune_rounded,
                          tint: semantic.info,
                          title: l10n.preferencesSection,
                          subtitle: l10n.preferencesSubtitle,
                          onTap: () => _pushSubPage(
                            PreferencesSettingsPage(
                              onOpenLanguageSelector:
                                  widget.onOpenLanguageSelector,
                              onOpenReports: widget.onOpenReports,
                              onOpenReminders: widget.onOpenReminders,
                            ),
                          ),
                        ),
                        SettingsAdaptiveRow(
                          isExpress: isExpress,
                          icon: Icons.folder_zip_outlined,
                          tint: semantic.mila,
                          title: l10n.dataSection,
                          subtitle: l10n.dataBackupSubtitle,
                          onTap: () => _pushSubPage(
                            DataBackupSettingsPage(
                              onCreateZipBackup: _runEncryptedBackupFlow,
                              onRestoreBackup: _runRestoreBackupFlow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: uiPrefs.compactMode ? 12 : 18),
                  ExpressReveal(
                    index: 4,
                    child: SettingsAdaptiveGroup(
                      isExpress: isExpress,
                      children: [
                        SettingsAdaptiveRow(
                          isExpress: isExpress,
                          icon: Icons.info_outline_rounded,
                          tint: semantic.warning,
                          title: l10n.aboutAppTitle,
                          subtitle: l10n.aboutAppSubtitle,
                          onTap: () => _pushSubPage(const AboutVyavahaarPage()),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 36),
                ExpressReveal(
                  index: 5,
                  child: _SettingsBrandFooter(
                    isExpress: isExpress,
                    semantic: semantic,
                    tagline: l10n.appTagline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    ref.invalidate(uiPreferencesProvider);
    ref.invalidate(localeProvider);
  }

  Future<T> _withProgressOverlay<T>(
    BuildContext activeContext,
    Future<T> Function() action,
  ) async {
    final semantic = AppSemanticColors.of(activeContext);
    var dialogOpen = true;
    showDialog<void>(
      context: activeContext,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: semantic.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: semantic.cardBorder),
            ),
            child: CircularProgressIndicator(color: semantic.primary),
          ),
        ),
      ),
    ).whenComplete(() => dialogOpen = false);

    try {
      return await action();
    } finally {
      if (dialogOpen && activeContext.mounted) {
        Navigator.of(activeContext, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _runEncryptedBackupFlow() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final service = BackupService(ref.read(databaseProvider));

    final passwordController = TextEditingController();
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: semantic.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            l10n.backupZipTitle,
            style: TextStyle(
              color: semantic.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(color: semantic.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.backupPasswordOptionalHint,
              hintMaxLines: 2,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.onVibrant,
              ),
              icon: const Icon(Icons.folder_zip_outlined, size: 17),
              label: Text(l10n.createZipBackupBtn),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final pwd = passwordController.text.trim();
      final result = await _withProgressOverlay(
        context,
        () => service.createZipBackup(password: pwd.isNotEmpty ? pwd : null),
      );
      if (!mounted) return;

      final sizeText = ImageStorageService.formatFileSize(result.fileSizeBytes);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: semantic.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: semantic.mila),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.backupSuccess,
                  style: TextStyle(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                style: TextStyle(
                  color: semantic.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.tabBahi}: ${result.metadata.entriesCount} • '
                '${l10n.tabEvents}: ${result.metadata.eventsCount} • '
                '${l10n.tabPeople}: ${result.metadata.peopleCount} • '
                '${l10n.photosCountLabel}: ${result.metadata.imagesCount}',
                style: TextStyle(
                  color: semantic.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await BackupService.shareBackup(result.file);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.onVibrant,
              ),
              icon: const Icon(Icons.share_rounded, size: 17),
              label: Text(l10n.shareSaveZipBackup),
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
      passwordController.dispose();
    }
  }

  Future<void> _runRestoreBackupFlow() async {
    if (!mounted) return;
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final service = BackupService(ref.read(databaseProvider));

    // Use FileType.any because many Android SAF pickers hide .zip files with FileType.custom.
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final ext = p.extension(file.path).toLowerCase();
    if (ext != '.zip' && ext != '.json') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidBackupFileError),
            backgroundColor: semantic.diya,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    BackupInspection inspection;
    try {
      inspection = await _withProgressOverlay(
        context,
        () => service.inspectBackup(file),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorGeneric}: $err')),
        );
      }
      return;
    }

    if (!mounted) return;
    final passwordController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: semantic.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            inspection.isEncrypted
                ? l10n.enterRestorePassword
                : l10n.restoreConfirmTitle,
            style: TextStyle(
              color: semantic.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.restoreReplaceWarning,
                style: TextStyle(
                  color: semantic.textSecondary,
                  fontSize: 12.5,
                ),
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
                  style: TextStyle(
                    color: semantic.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              if (inspection.isEncrypted) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: semantic.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.restorePasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: semantic.primary,
                foregroundColor: semantic.onVibrant,
              ),
              child: Text(l10n.restore),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
      final enteredPwd = passwordController.text.trim();
      if (inspection.isEncrypted && enteredPwd.isEmpty) return;

      final restored = await _withProgressOverlay(
        context,
        () => service.restoreBackup(
          file,
          password: inspection.isEncrypted ? enteredPwd : null,
        ),
      );
      _invalidateAllAfterRestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.restoreSuccess} (${l10n.tabBahi}: ${restored.entriesRestored}, ${l10n.photosCountLabel}: ${restored.imagesRestored})',
            ),
            backgroundColor: semantic.mila,
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
      passwordController.dispose();
    }
  }
}

/// Family Profile Hero adapted from Streak's `_ProfileHero` (Express & Classic variants).
class _SettingsProfileHero extends StatelessWidget {
  final FamilyProfile profile;
  final bool isExpress;
  final VoidCallback onTapCard;
  final VoidCallback onTapEdit;
  final VoidCallback onTapQrShare;

  const _SettingsProfileHero({
    required this.profile,
    required this.isExpress,
    required this.onTapCard,
    required this.onTapEdit,
    required this.onTapQrShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto =
        profile.photoPath.isNotEmpty && File(profile.photoPath).existsSync();
    final titleText = profile.isNotEmpty && profile.familyName.isNotEmpty
        ? profile.familyName
        : l10n.setupFamilyProfile;
    final subText = profile.isNotEmpty
        ? (profile.headOfFamily.isNotEmpty
            ? '${l10n.mukhiyaBadge}: ${profile.headOfFamily}'
            : (profile.nativePlace.isNotEmpty
                ? profile.nativePlace
                : l10n.myFamily))
        : l10n.setupFamilyProfileSubtitle;

    final avatar = GestureDetector(
      onTap: onTapEdit,
      child: SizedBox(
        width: isExpress ? 72 : 80,
        height: isExpress ? 72 : 80,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: semantic.primary.withValues(alpha: isDark ? 0.22 : 0.12),
            shape: ExpressBorder(
              shape: isExpress ? ExpressShape.cookie : ExpressShape.circle,
              side: BorderSide(
                color: semantic.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            image: hasPhoto
                ? DecorationImage(
                    image: FileImage(File(profile.photoPath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: !hasPhoto
              ? Icon(
                  Icons.family_restroom_rounded,
                  size: isExpress ? 32 : 36,
                  color: semantic.primary,
                )
              : null,
        ),
      ),
    );

    final pills = Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: isExpress ? WrapAlignment.start : WrapAlignment.center,
      children: [
        _HeroActionPill(
          icon: profile.isEmpty ? Icons.add_rounded : Icons.edit_outlined,
          label: profile.isEmpty ? l10n.setupFamilyProfile : l10n.editProfile,
          background: semantic.primary.withValues(alpha: isDark ? 0.20 : 0.12),
          foreground: semantic.primary,
          onTap: onTapEdit,
        ),
        _HeroActionPill(
          icon: Icons.qr_code_2_rounded,
          label: l10n.qrSharePillLabel,
          background: semantic.mila.withValues(alpha: isDark ? 0.20 : 0.12),
          foreground: semantic.mila,
          onTap: onTapQrShare,
        ),
      ],
    );

    if (!isExpress) {
      return Column(
        children: [
          avatar,
          const SizedBox(height: 12),
          Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ExpressType.headlineSmall(
              color: semantic.textPrimary,
              weight: FontWeight.w800,
            ).copyWith(fontSize: 21),
          ),
          const SizedBox(height: 3),
          Text(
            subText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ExpressType.bodySmall(
              color: semantic.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          pills,
        ],
      );
    }

    return ExpressSquish(
      onTap: onTapCard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: semantic.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ExpressType.headlineSmall(
                            color: semantic.textPrimary,
                            weight: FontWeight.w800,
                          ).copyWith(
                            fontSize: 21,
                            height: 1.15,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (profile.isNotEmpty && profile.members.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: semantic.milaContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: semantic.milaBorder),
                          ),
                          child: Text(
                            '${profile.members.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: semantic.mila,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.bodySmall(
                      color: semantic.textSecondary,
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  pills,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _HeroActionPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: ExpressType.labelMedium(
                  color: foreground,
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBrandFooter extends StatelessWidget {
  final bool isExpress;
  final AppSemanticColors semantic;
  final String tagline;

  const _SettingsBrandFooter({
    required this.isExpress,
    required this.semantic,
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isExpress) ...[
          ExpressBlob(
            size: 52,
            color: semantic.primary.withValues(alpha: 0.14),
            shape: ExpressShape.flower,
            child: Icon(
              Icons.menu_book_rounded,
              size: 21,
              color: semantic.primary,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          'V Y A V A H A A R',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.4,
            color: semantic.textSecondary.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: semantic.textSecondary.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          kVyavahaarAppVersion,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: semantic.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
