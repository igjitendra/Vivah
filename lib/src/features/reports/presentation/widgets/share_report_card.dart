import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../shared/widgets/express_button.dart';
import '../../data/vyavahaar_stats.dart';

/// Streak-inspired visual report summary card that renders inside Exports tab
/// and can be exported as a high-DPI PNG image via [share_plus].
class ShareReportSummaryCard extends StatefulWidget {
  final VyavahaarStats stats;
  final FamilyProfile familyProfile;
  final String periodLabel;

  const ShareReportSummaryCard({
    super.key,
    required this.stats,
    required this.familyProfile,
    required this.periodLabel,
  });

  @override
  State<ShareReportSummaryCard> createState() => _ShareReportSummaryCardState();
}

class _ShareReportSummaryCardState extends State<ShareReportSummaryCard> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _exportCardImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final filePath = p.join(
        dir.path,
        'vyavahaar_report_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      final file = File(filePath);
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      final l10n = context.l10n;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${l10n.appName} — ${widget.periodLabel}',
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorGeneric}: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final l10n = context.l10n;
    final familyTitle = widget.familyProfile.familyName.trim().isNotEmpty
        ? widget.familyProfile.familyName.trim()
        : l10n.appName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [semantic.heroStart, semantic.heroEnd],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: semantic.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: semantic.onHero.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: semantic.onHero.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        widget.periodLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: semantic.onHero,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.appName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: semantic.heroHighlight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  familyTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: semantic.heroHighlight,
                  ),
                ),
                Text(
                  '${widget.stats.totalCount} ${l10n.items} • ${widget.stats.activeDays} ${l10n.activeDaysCountLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: semantic.onHeroMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Isolated Mila & Diya boxes
                Row(
                  children: [
                    Expanded(
                      child: _CardMetricBox(
                        label: l10n.totalReceived,
                        value: CurrencyUtils.formatPaise(widget.stats.totalReceivedPaise),
                        sub: '${widget.stats.receivedCount} ${l10n.items}',
                        accent: semantic.mila,
                        semantic: semantic,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _CardMetricBox(
                        label: l10n.totalGiven,
                        value: CurrencyUtils.formatPaise(widget.stats.totalGivenPaise),
                        sub: '${widget.stats.givenCount} ${l10n.items}',
                        accent: semantic.diya,
                        semantic: semantic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Cash & Gifts Footer Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: semantic.onHero.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: semantic.onHero.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.cash}: ${CurrencyUtils.formatPaise(widget.stats.cashTotalPaise)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: semantic.onHero,
                          ),
                        ),
                      ),
                      Text(
                        '${l10n.giftsLabel}: ${widget.stats.giftItemCount} ${l10n.itemsCountSuffix}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: semantic.heroHighlight,
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
        ExpressButton(
          label: l10n.shareCardImageBtn,
          icon: Icons.image_outlined,
          expand: true,
          isLoading: _isSharing,
          onPressed: _exportCardImage,
        ),
      ],
    );
  }
}

class _CardMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color accent;
  final AppSemanticColors semantic;

  const _CardMetricBox({
    required this.label,
    required this.value,
    required this.sub,
    required this.accent,
    required this.semantic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantic.heroCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: semantic.heroCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: semantic.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10.5,
              color: semantic.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
