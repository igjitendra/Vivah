import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../app/app_providers.dart';

/// Proof image section widget for EntryDetailScreen.
/// Shows proof photo + caption; allows add/replace/delete.
class ProofImageSection extends ConsumerStatefulWidget {
  final String entryId;

  const ProofImageSection({super.key, required this.entryId});

  @override
  ConsumerState<ProofImageSection> createState() => _ProofImageSectionState();
}

class _ProofImageSectionState extends ConsumerState<ProofImageSection> {
  bool _isLoading = false;

  Future<void> _pickImage(BuildContext context, AppLocalizations l10n) async {
    // Show source picker bottom sheet
    final source = await _showSourcePicker(context, l10n);
    if (source == null) return;

    setState(() => _isLoading = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final sourcePath = result.files.first.path;
      if (sourcePath == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Show caption dialog
      final caption = await _showCaptionDialog(context, l10n);

      // Copy to permanent local storage
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (!attachmentsDir.existsSync()) {
        attachmentsDir.createSync(recursive: true);
      }

      final ext = p.extension(sourcePath);
      final fileName =
          'proof_${widget.entryId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(attachmentsDir.path, fileName);
      await File(sourcePath).copy(destPath);

      // Save to database
      final attachmentsDao = ref.read(appDatabaseProvider).attachmentsDao;
      await attachmentsDao.setProof(
        id: 'att_${DateTime.now().millisecondsSinceEpoch}',
        entryId: widget.entryId,
        localPath: destPath,
        note: caption != null && caption.isNotEmpty ? caption : null,
      );

      // Refresh
      ref.invalidate(entryProofProvider(widget.entryId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.proofImageError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showSourcePicker(
      BuildContext context, AppLocalizations l10n) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.cancel),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCaptionDialog(
      BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.proofImageCaption),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.proofImageCaptionHint,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.skip),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProof(
      BuildContext context, AppLocalizations l10n, String localPath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProof),
        content: Text(l10n.deleteProofConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Delete file and DB record
    final attachmentsDao = ref.read(appDatabaseProvider).attachmentsDao;
    await attachmentsDao.deleteProofForEntry(widget.entryId);
    try {
      await File(localPath).delete();
    } catch (_) {}
    ref.invalidate(entryProofProvider(widget.entryId));
  }

  void _openFullScreen(BuildContext context, String localPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(imagePath: localPath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final proofAsync = ref.watch(entryProofProvider(widget.entryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? const Color(0xFF1A2035) : const Color(0xFFFAF8F4);
    final cardBorder =
        isDark ? const Color(0xFF2A3348) : const Color(0xFFE2DDD6);
    final textSecondary =
        isDark ? const Color(0xFF8899AA) : AppColors.mutedText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 20, color: AppColors.terracotta),
              const SizedBox(width: 8),
              Text(
                l10n.proofImageTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            proofAsync.when(
              data: (proof) {
                if (proof == null) {
                  // No proof yet — show add button
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.terracotta,
                      side: BorderSide(
                          color: AppColors.terracotta.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.addProofImage),
                    onPressed: () => _pickImage(context, l10n),
                  );
                }

                // Has proof — show thumbnail
                final file = File(proof.localPath);
                final fileExists = file.existsSync();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: fileExists
                          ? () => _openFullScreen(context, proof.localPath)
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: fileExists
                            ? Image.file(
                                file,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A3348)
                                      : const Color(0xFFE8E4DD),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      color: textSecondary),
                                ),
                              ),
                      ),
                    ),
                    if (proof.note != null && proof.note!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.label_outline,
                              size: 14, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              proof.note!,
                              style: TextStyle(
                                  color: textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.terracotta,
                              side: BorderSide(
                                  color: AppColors.terracotta
                                      .withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: Text(l10n.replaceProof),
                            onPressed: () => _pickImage(context, l10n),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(l10n.delete),
                          onPressed: () =>
                              _deleteProof(context, l10n, proof.localPath),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// Full-screen image viewer with pinch-to-zoom
class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
