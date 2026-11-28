import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/express_type.dart';
import '../../../../core/theme/ui_preferences_notifier.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/express_settings_kit.dart';
import '../../../../shared/widgets/express_squish.dart';

/// Opens Streak-inspired visual App Style picker (Express vs Classic).
Future<void> showAppStylePickerSheet(BuildContext context) {
  final semantic = AppSemanticColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => const SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: _AppStylePickerSheetBody(),
      ),
    ),
  );
}

class _AppStylePickerSheetBody extends ConsumerWidget {
  const _AppStylePickerSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final semantic = AppSemanticColors.of(context);
    final uiPrefs = ref.watch(uiPreferencesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.appStyleTitle,
          style: ExpressType.headlineSmall(
            color: semantic.textPrimary,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appStyleSubtitle,
          style: ExpressType.bodySmall(
            color: semantic.textSecondary,
          ).copyWith(fontSize: 13),
        ),
        const SizedBox(height: 20),
        AppStylePreviewRow(
          selected: uiPrefs.style,
          onSelect: (style) =>
              ref.read(uiPreferencesProvider.notifier).setStyle(style),
        ),
        const SizedBox(height: 20),
        AppStyleLegendList(
          selected: uiPrefs.style,
          onSelect: (style) =>
              ref.read(uiPreferencesProvider.notifier).setStyle(style),
        ),
      ],
    );
  }
}

/// Side-by-side miniature phone wireframes for Express vs Classic styles.
class AppStylePreviewRow extends StatelessWidget {
  final SettingsVisualStyle selected;
  final ValueChanged<SettingsVisualStyle> onSelect;

  const AppStylePreviewRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: _StylePreviewCard(
            label: l10n.styleClassicTitle,
            isSelected: selected == SettingsVisualStyle.classic,
            preview: const _ClassicMiniPreview(),
            onTap: () => onSelect(SettingsVisualStyle.classic),
          ),
        ),
        const SizedBox(width: 22),
        SizedBox(
          width: 112,
          child: _StylePreviewCard(
            label: l10n.styleExpressTitle,
            isSelected: selected == SettingsVisualStyle.express,
            preview: const _ExpressMiniPreview(),
            onTap: () => onSelect(SettingsVisualStyle.express),
          ),
        ),
      ],
    );
  }
}

class _StylePreviewCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Widget preview;
  final VoidCallback onTap;

  const _StylePreviewCard({
    required this.label,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final accent = semantic.primary;

    return ExpressSquish(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 0.64,
            child: AnimatedScale(
              scale: isSelected ? 1.0 : 0.94,
              duration: Express.quick,
              curve: Express.bouncy,
              child: AnimatedContainer(
                duration: Express.fast,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accent : semantic.cardBorder,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: semantic.cardSubtleBg),
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1.0 : 0.72,
                      duration: Express.fast,
                      child: preview,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ExpressType.titleMedium(
              color: isSelected ? accent : semantic.textSecondary,
              weight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: Express.quick,
            curve: Express.settle,
            height: 4,
            width: isSelected ? 26 : 0,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive description cards below miniature phone wireframes.
class AppStyleLegendList extends StatelessWidget {
  final SettingsVisualStyle selected;
  final ValueChanged<SettingsVisualStyle> onSelect;

  const AppStyleLegendList({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = [
      (
        style: SettingsVisualStyle.express,
        title: l10n.styleExpressTitle,
        desc: l10n.styleExpressDesc,
      ),
      (
        style: SettingsVisualStyle.classic,
        title: l10n.styleClassicTitle,
        desc: l10n.styleClassicDesc,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _LegendItem(
            title: entries[i].title,
            description: entries[i].desc,
            selected: selected == entries[i].style,
            onTap: () => onSelect(entries[i].style),
          ),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _LegendItem({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final accent = semantic.primary;

    return ExpressSquish(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Express.fast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.11)
              : semantic.cardSubtleBg,
          borderRadius: BorderRadius.circular(selected ? 20 : 15),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.55)
                : semantic.cardBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ExpressType.titleMedium(
                      color: selected ? accent : semantic.textPrimary,
                      weight: FontWeight.w800,
                    ).copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: ExpressType.bodySmall(
                      color: semantic.textSecondary,
                    ).copyWith(fontSize: 12.5, height: 1.38),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedScale(
              scale: selected ? 1.0 : 0.0,
              duration: Express.quick,
              curve: Express.bouncy,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: semantic.onVibrant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _miniBlock(double w, double h, Color color, {double radius = 2}) =>
    Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

class _ClassicMiniPreview extends StatelessWidget {
  const _ClassicMiniPreview();

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final accent = semantic.primary;
    final tint = accent.withValues(alpha: 0.22);
    final text = semantic.textSecondary.withValues(alpha: 0.55);
    final faint = semantic.textSecondary.withValues(alpha: 0.28);

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 86;
        Widget row() => Padding(
              padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 4.5 * s),
              child: Row(
                children: [
                  _miniBlock(10 * s, 10 * s, tint, radius: 3 * s),
                  SizedBox(width: 4 * s),
                  _miniBlock(26 * s, 3 * s, text, radius: 2 * s),
                  const Spacer(),
                  _miniBlock(10 * s, 3 * s, faint, radius: 2 * s),
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(5 * s, 8 * s, 5 * s, 6 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _miniBlock(24 * s, 24 * s, tint, radius: 12 * s)),
              SizedBox(height: 4 * s),
              Center(child: _miniBlock(32 * s, 4 * s, text, radius: 2 * s)),
              SizedBox(height: 8 * s),
              Container(
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(7 * s),
                ),
                child: Column(
                  children: [
                    row(),
                    Container(height: 0.8, color: faint),
                    row(),
                    Container(height: 0.8, color: faint),
                    row(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpressMiniPreview extends StatelessWidget {
  const _ExpressMiniPreview();

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final accent = semantic.primary;
    final tint = accent.withValues(alpha: 0.22);
    final text = semantic.textSecondary.withValues(alpha: 0.55);
    final faint = semantic.textSecondary.withValues(alpha: 0.28);

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = constraints.maxWidth / 86;

        Widget row(double topR, double bottomR) => Container(
              height: 16 * s,
              padding: EdgeInsets.symmetric(horizontal: 4.5 * s),
              decoration: BoxDecoration(
                color: semantic.cardBg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(topR * s),
                  bottom: Radius.circular(bottomR * s),
                ),
              ),
              child: Row(
                children: [
                  _miniBlock(10 * s, 10 * s, tint, radius: 5 * s),
                  SizedBox(width: 4 * s),
                  _miniBlock(22 * s, 3 * s, text, radius: 2 * s),
                  const Spacer(),
                  _miniBlock(12 * s, 7 * s, accent, radius: 3.5 * s),
                ],
              ),
            );

        return Padding(
          padding: EdgeInsets.fromLTRB(5 * s, 7 * s, 5 * s, 5 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _miniBlock(28 * s, 6 * s, semantic.textPrimary.withValues(alpha: 0.72), radius: 3 * s),
              SizedBox(height: 6 * s),
              Container(
                height: 24 * s,
                padding: EdgeInsets.symmetric(horizontal: 5 * s),
                decoration: BoxDecoration(
                  color: semantic.cardBg,
                  borderRadius: BorderRadius.circular(9 * s),
                ),
                child: Row(
                  children: [
                    _miniBlock(14 * s, 14 * s, tint, radius: 5 * s),
                    SizedBox(width: 5 * s),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _miniBlock(26 * s, 3.5 * s, text, radius: 2 * s),
                        SizedBox(height: 3 * s),
                        _miniBlock(18 * s, 5 * s, accent, radius: 2.5 * s),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 6 * s),
              row(7, 2),
              SizedBox(height: 1.5 * s),
              row(2, 2),
              SizedBox(height: 1.5 * s),
              row(2, 7),
              const Spacer(),
              Center(
                child: Container(
                  width: 44 * s,
                  height: 11 * s,
                  padding: EdgeInsets.symmetric(horizontal: 2 * s),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(5.5 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniBlock(16 * s, 7 * s, accent, radius: 3.5 * s),
                      _miniBlock(4 * s, 4 * s, faint, radius: 2 * s),
                      _miniBlock(4 * s, 4 * s, faint, radius: 2 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
