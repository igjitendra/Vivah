import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/event_qr_service.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../shared/widgets/express_button.dart';

/// Modal bottom sheet displaying a shareable, 100%-offline QR invitation card for an [Event].
class EventQrSheet extends StatefulWidget {
  final Event event;
  final FamilyProfile? familyProfile;

  const EventQrSheet({
    super.key,
    required this.event,
    this.familyProfile,
  });

  /// Shows the QR invitation sheet for [event].
  static Future<void> show(
    BuildContext context,
    Event event, {
    FamilyProfile? familyProfile,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventQrSheet(
        event: event,
        familyProfile: familyProfile,
      ),
    );
  }

  @override
  State<EventQrSheet> createState() => _EventQrSheetState();
}

class _EventQrSheetState extends State<EventQrSheet> {
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
      final safeName = widget.event.title.replaceAll(RegExp(r'[^a-zA-Z0-9\u0900-\u097F_-]'), '_');
      final filePath = p.join(
        tempDir.path,
        'vyavahaar_qr_${safeName.isEmpty ? 'event' : safeName}.png',
      );
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      final l10n = context.l10n;
      final dateLabel = AppDateUtils.formatLocalizedDate(
        widget.event.eventDate,
        l10n.locale.languageCode,
      );
      final shareCaption = StringBuffer()
        ..writeln('${widget.event.title} — $dateLabel')
        ..writeln(
          widget.event.venue != null && widget.event.venue!.trim().isNotEmpty
              ? '${widget.event.venue}'
              : '',
        )
        ..writeln(l10n.qrShareHint);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareCaption.toString().trim(),
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

    final qrData = EventQrService.encodeEvent(
      widget.event,
      familyProfile: widget.familyProfile,
    );
    final hostDisplay = EventQrService.resolveHostDisplayName(
      widget.event,
      widget.familyProfile,
    );
    final formattedDate = AppDateUtils.formatLocalizedDate(
      widget.event.eventDate,
      l10n.locale.languageCode,
    );
    final locationParts = [
      if (widget.event.venue != null && widget.event.venue!.trim().isNotEmpty)
        widget.event.venue!.trim(),
      if (widget.event.villageCity != null && widget.event.villageCity!.trim().isNotEmpty)
        widget.event.villageCity!.trim(),
    ];

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
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: semantic.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title Row
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: semantic.primary, size: 24),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.eventQrTitle,
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

            // RepaintBoundary Invitation Card for crisp high-DPI PNG sharing
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
                    // Hero Banner Header inside card
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
                              border: Border.all(
                                color: semantic.onHero.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Text(
                              l10n.eventTypeLabel(
                                widget.event.eventType,
                                customCategory: widget.event.category,
                              ),
                              style: TextStyle(
                                color: semantic.onHero,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.event.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: semantic.heroHighlight,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_rounded, size: 14, color: semantic.onHeroMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: semantic.onHeroMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (locationParts.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: semantic.onHeroMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      locationParts.join(', '),
                                      style: TextStyle(
                                        color: semantic.onHeroMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // High-contrast QR Matrix Box
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              // White quiet-zone is required optically for reliable QR scanning across themes
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: semantic.cardBorder, width: 1),
                            ),
                            child: QrImageView(
                              data: qrData,
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
                          if (hostDisplay != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${l10n.hostNameLabel}: $hostDisplay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: semantic.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (widget.event.functions.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.event.functions.map((f) => f.title).take(4).join(' • '),
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

            // Instruction Note
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
                      l10n.qrShareHint,
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

            // Share & Close Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: semantic.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.close),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
