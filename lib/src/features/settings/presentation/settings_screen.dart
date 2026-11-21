import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../app/app_providers.dart';
import '../services/backup_service.dart';

/// Settings & System Management Screen
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
    final db = ref.watch(databaseProvider);
    final backupService = BackupService(db);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'सेटिंग्स (Settings)',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
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
                  title: 'भाषा और प्राथमिकताएं',
                  icon: Icons.language,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.translate, color: AppColors.deepNavy),
                      title: const Text('भाषा बदलें / Select Language', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('22 भारतीय भाषाएं समर्थित'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onOpenLanguageSelector,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Reports & Data Export Card
                _buildSectionCard(
                  title: 'रिपोर्ट्स और अनुस्मारक',
                  icon: Icons.assignment_outlined,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.terracotta),
                      title: const Text('PDF और CSV रिपोर्ट्स', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('बही-खाता, कार्यक्रम और व्यक्तिवार प्रिंट'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: widget.onOpenReports,
                    ),
                    if (widget.onOpenReminders != null) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: AppColors.gold),
                        title: const Text('अनुस्मारक (Reminders)', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('आगामी व्यवहार और आयोजनों की सूची'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: widget.onOpenReminders,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // 3. Backup & Restore Card
                _buildSectionCard(
                  title: 'ऑफ़लाइन बैकअप और पुनर्स्थापना',
                  icon: Icons.security,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppColors.milaGreen),
                      title: const Text('एन्क्रिप्टेड बैकअप बनाएं', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('पासवर्ड सुरक्षित (AES-256-GCM)'),
                      trailing: const Icon(Icons.file_upload_outlined),
                      onTap: () => _handleEncryptedBackup(backupService),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined, color: AppColors.deepNavy),
                      title: const Text('बैकअप से डेटा पुनर्स्थापित करें', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('सुरक्षित रोलबैक के साथ बैकअप फ़ाइल चुनें'),
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
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.milaGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '100% ऑफ़लाइन और निजी',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepNavy),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'व्यवहार आपके पारिवारिक रिकॉर्ड्स को किसी भी बाहरी सर्वर या क्लाउड पर नहीं भेजता। आपका सारा डेटा केवल आपके डिवाइस में सुरक्षित रहता है।',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                const Center(
                  child: Text(
                    'व्यवहार v1.3.0 • रिश्तों का हिसाब, हमेशा याद।',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
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
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('बैकअप पासवर्ड दर्ज करें'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'पासवर्ड (कम से कम 6 अक्षर)',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करें')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: const Text('बैकअप बनाएं', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final file = await service.createBackup(password: passwordController.text.trim());
        await BackupService.shareBackup(file);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('त्रुटि: $err')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestoreBackup(BackupService service) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final passwordController = TextEditingController();

      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('बैकअप पुनर्स्थापित करें'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('यदि बैकअप पासवर्ड-सुरक्षित है, तो कृपया पासवर्ड दर्ज करें:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'पासवर्ड (यदि आवश्यक हो)',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('रद्द करें')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.milaGreen),
              child: const Text('पुनर्स्थापित करें', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (proceed == true) {
        setState(() => _isLoading = true);
        try {
          await service.restoreBackup(file, password: passwordController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('डेटा सफलतापूर्वक पुनर्स्थापित हो गया!'), backgroundColor: AppColors.milaGreen),
            );
          }
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('त्रुटि: $err')));
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }
}
