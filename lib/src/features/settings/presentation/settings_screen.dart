import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/express_squish.dart';
import '../../../app/app_providers.dart';
import '../services/backup_service.dart';

/// Screen managing application settings, language switching, theme selection, and offline backups.
/// Fully theme-adaptive with Material 3 styling and tactile feedback.
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
    final backupService = BackupService(db);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: headerBg,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryAccent))
          : ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: AppSpacing.floatingTabBottomPadding + 20,
              ),
              children: [
                // 1. Language & Display Card
                _buildSectionCard(
                  title: l10n.displayAndPreferences,
                  icon: Icons.palette_outlined,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  primaryAccent: primaryAccent,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: Color(0xFFA78BFA)),
                      title: Text(l10n.themeAndColors, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                      subtitle: Text(l10n.themeAndColorsSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: textSecondary),
                      onTap: () => context.push('/theme'),
                    ),
                    Divider(height: 1, color: cardBorder),
                    ListTile(
                      leading: Icon(Icons.translate, color: isDark ? const Color(0xFF38BDF8) : headerBg),
                      title: Text(l10n.selectLanguage, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                      subtitle: Text(l10n.selectLanguageSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: textSecondary),
                      onTap: widget.onOpenLanguageSelector,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Reports & Data Export Card
                _buildSectionCard(
                  title: l10n.reportsAndReminders,
                  icon: Icons.assignment_outlined,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  primaryAccent: primaryAccent,
                  children: [
                    ListTile(
                      leading: Icon(Icons.description_outlined, color: primaryAccent),
                      title: Text(l10n.reports, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                      subtitle: Text(l10n.reportsSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: textSecondary),
                      onTap: widget.onOpenReports,
                    ),
                    if (widget.onOpenReminders != null) ...[
                      Divider(height: 1, color: cardBorder),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.gold),
                        title: Text(l10n.reminders, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                        subtitle: Text(l10n.remindersSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right, color: textSecondary),
                        onTap: widget.onOpenReminders,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 3. Backup & Restore Card
                _buildSectionCard(
                  title: l10n.offlineBackupAndRestore,
                  icon: Icons.security,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  primaryAccent: primaryAccent,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.milaGreen),
                      title: Text(l10n.backup, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                      subtitle: Text(l10n.backupSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.file_upload_outlined, color: textSecondary),
                      onTap: () => _handleEncryptedBackup(backupService, cardBg, textPrimary, primaryAccent),
                    ),
                    Divider(height: 1, color: cardBorder),
                    ListTile(
                      leading: Icon(Icons.file_download_outlined, color: isDark ? const Color(0xFF38BDF8) : headerBg),
                      title: Text(l10n.restore, style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                      subtitle: Text(l10n.restoreSubtitle, style: TextStyle(color: textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right, color: textSecondary),
                      onTap: () => _handleRestoreBackup(backupService, cardBg, textPrimary, primaryAccent),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 4. Privacy Notice Card
                ExpressCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  radius: 16,
                  color: cardBg,
                  borderColor: cardBorder,
                  elevation: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.milaGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.offlineGuaranteed,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.privacyPolicyNotice,
                        style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    '${l10n.appName} v1.3.0 • ${l10n.appTagline}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryAccent,
    required List<Widget> children,
  }) {
    return ExpressCard(
      padding: EdgeInsets.zero,
      radius: 16,
      color: cardBg,
      borderColor: cardBorder,
      elevation: 0,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 18, color: primaryAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cardBorder),
          ...children,
        ],
      ),
    );
  }

  Future<void> _handleEncryptedBackup(BackupService service, Color cardBg, Color textPrimary, Color primaryAccent) async {
    final l10n = context.l10n;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.enterBackupPassword, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: l10n.backupPasswordHint,
            prefixIcon: const Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final backupFile = await service.createBackup(password: passwordController.text.trim());
        final path = backupFile.path;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.backupSuccess}: $path'),
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

  Future<void> _handleRestoreBackup(BackupService service, Color cardBg, Color textPrimary, Color primaryAccent) async {
    final l10n = context.l10n;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (!mounted) return;

      final passwordController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.enterRestorePassword, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: l10n.restorePasswordHint,
              prefixIcon: const Icon(Icons.lock),
            ),
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

      if (confirmed == true && passwordController.text.trim().isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          await service.restoreBackup(file, password: passwordController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.restoreSuccess),
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
  }
}
