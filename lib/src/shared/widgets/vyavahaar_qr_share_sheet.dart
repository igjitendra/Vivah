import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../widgets/express_button.dart';

/// Reusable modal bottom sheet rendering a high-contrast offline QR card
/// (used for Family Profiles, Relatives, or custom Vyavahaar identity cards).
class VyavahaarQrShareSheet extends StatefulWidget {
  final String sheetTitle;
  final String badgeLabel;
  final String cardTitle;
  final List<String> heroSubtitles;
  final String qrData;
  final String? bodyDetail;
  final String? footerSummary;
  final String shareCaption;
  final String fileNamePrefix;
  final String? hintText;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;

  const VyavahaarQrShareSheet({
    super.key,
    required this.sheetTitle,
    required this.badgeLabel,
    required this.cardTitle,
    this.heroSubtitles = const [],
    required this.qrData,
    this.bodyDetail,
    this.footerSummary,
    required this.shareCaption,
    required this.fileNamePrefix,
    this.hintText,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
  });

  static Future<void> show(
    BuildContext context, {
    required String sheetTitle,
    required String badgeLabel,
    required String cardTitle,
    List<String> heroSubtitles = const [],
    required String qrData,
    String? bodyDetail,
    String? footerSummary,
    required String shareCaption,
    required String fileNamePrefix,
    String? hintText,
    String? secondaryActionLabel,
    IconData? secondaryActionIcon,
    VoidCallback? onSecondaryAction,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VyavahaarQrShareSheet(
        sheetTitle: sheetTitle,
        badgeLabel: badgeLabel,
        cardTitle: cardTitle,
        heroSubtitles: heroSubtitles,
        qrData: qrData,
        bodyDetail: bodyDetail,
        footerSummary: footerSummary,
        shareCaption: shareCaption,
        fileNamePrefix: fileNamePrefix,
        hintText: hintText,
        secondaryActionLabel: secondaryActionLabel,
        secondaryActionIcon: secondaryActionIcon,
        onSecondaryAction: onSecondaryAction,
      ),
    );
  }

  @override
  State<VyavahaarQrShareSheet> createState() => _VyavahaarQrShareSheetState();
}

class _VyavahaarQrShareSheetState extends State<VyavahaarQrShareSheet> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareQrCardImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary =
          _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final safeName = widget.cardTitle
          .replaceAll(RegExp(r'[^\p{L}\p{N}_-]+', unicode: true), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final filePath = p.join(
        tempDir.path,
        '${widget.fileNamePrefix}_${safeName.isEmpty ? 'card' : safeName}.png',
      );
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.shareCaption.trim(),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: semantic.cardBorder, width: 1)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: semantic.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: semantic.primary, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    widget.sheetTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: semantic.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: semantic.textSecondary),
                  tooltip: l10n.close,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            RepaintBoundary(
              key: _cardBoundaryKey,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: semantic.cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: semantic.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [semantic.heroStart, semantic.heroEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: semantic.onHero.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: semantic.onHero.withValues(alpha: 0.24)),
                            ),
                            child: Text(
                              widget.badgeLabel,
                              style: TextStyle(
                                color: semantic.onHero,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.cardTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: semantic.heroHighlight,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          if (widget.heroSubtitles.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.heroSubtitles.join(' • '),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: semantic.onHeroMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: semantic.cardBorder, width: 1),
                            ),
                            child: QrImageView(
                              data: widget.qrData,
                              version: QrVersions.auto,
                              size: 210,
                              gapless: true,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          if (widget.bodyDetail != null && widget.bodyDetail!.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.bodyDetail!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: semantic.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (widget.footerSummary != null && widget.footerSummary!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.footerSummary!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: semantic.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            l10n.appName,
                            style: TextStyle(
                              color: semantic.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: semantic.infoContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: semantic.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: semantic.info, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.hintText ?? l10n.qrShareProfileHint,
                      style: TextStyle(
                        color: semantic.textPrimary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (widget.onSecondaryAction != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onSecondaryAction,
                      icon: Icon(widget.secondaryActionIcon ?? Icons.share_outlined, size: 17),
                      label: Text(
                        widget.secondaryActionLabel ?? l10n.shareTextCardLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        side: BorderSide(color: semantic.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: 2,
                  child: ExpressButton(
                    label: l10n.shareQrCard,
                    icon: Icons.share_rounded,
                    isLoading: _isSharing,
                    onPressed: _shareQrCardImage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
