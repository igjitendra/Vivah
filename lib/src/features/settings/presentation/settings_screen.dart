import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../app/app_providers.dart';
import '../services/backup_service.dart';

/// Settings & System Management Screen (Fully Localized, Zero Hardcoding)
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
    final l10n = context.l10n;
    final db = ref.watch(databaseProvider);
    final backupService = BackupService(db);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom: AppSpacing.floatingTabBottomPadding,
              ),
              children: [
                // 1. Language & Display Card
                _buildSectionCard(
                  title: l10n.displayAndPreferences,
                  icon: Icons.language,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined, color: Color(0xFFA78BFA)),
                      title: Text(l10n.themeAndColors, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.themeAndColorsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/theme'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.translate, color: AppColors.deepNavy),
                      title: Text(l10n.selectLanguage, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.selectLanguageSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onOpenLanguageSelector,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Reports & Data Export Card
                _buildSectionCard(
                  title: l10n.reportsAndReminders,
                  icon: Icons.assignment_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.terracotta),
                      title: Text(l10n.reports, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.reportsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onOpenReports,
                    ),
                    if (widget.onOpenReminders != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.gold),
                        title: Text(l10n.reminders, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l10n.remindersSubtitle),
                        trailing: const Icon(Icons.chevron_right),
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
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.milaGreen),
                      title: Text(l10n.backup, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.backupSubtitle),
                      trailing: const Icon(Icons.file_upload_outlined),
                      onTap: () => _handleEncryptedBackup(backupService),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined, color: AppColors.deepNavy),
                      title: Text(l10n.restore, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l10n.restoreSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleRestoreBackup(backupService),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 4. Privacy Notice Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.milaGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.offlineGuaranteed,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.privacyPolicyNotice,
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    '${l10n.appName} v1.3.0 • ${l10n.appTagline}',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 0,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.deepNavy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepNavy),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Future<void> _handleEncryptedBackup(BackupService service) async {
    final l10n = context.l10n;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.enterBackupPassword),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: l10n.backupPasswordHint,
            prefixIcon: const Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: Text(l10n.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final path = await service.exportEncryptedBackup(passwordController.text.trim());
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

  Future<void> _handleRestoreBackup(BackupService service) async {
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
          title: Text(l10n.enterRestorePassword),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: l10n.restorePasswordHint,
              prefixIcon: const Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
              child: Text(l10n.restore, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true && passwordController.text.trim().isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          await service.importEncryptedBackup(file.path, passwordController.text.trim());
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
