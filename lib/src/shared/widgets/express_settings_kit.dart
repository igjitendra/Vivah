import 'package:flutter/material.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/express_type.dart';
import '../../core/utils/responsive.dart';
import 'express_button.dart';
import 'express_shapes.dart';
import 'express_squish.dart';

/// Controls whether settings rows use compact vertical rhythm and hide inline subtitles.
class CompactDensity extends InheritedWidget {
  final bool isCompact;

  const CompactDensity({
    super.key,
    required this.isCompact,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CompactDensity>()?.isCompact ?? false;

  @override
  bool updateShouldNotify(CompactDensity oldWidget) =>
      oldWidget.isCompact != isCompact;
}

/// Provides asymmetric outer (22px) / inner (6px) slot radii inside [ExpressGroup].
class ExpressSlotRadius extends InheritedWidget {
  final BorderRadius radius;

  const ExpressSlotRadius({
    super.key,
    required this.radius,
    required super.child,
  });

  static BorderRadius of(BuildContext context, BorderRadius fallback) =>
      context.dependOnInheritedWidgetOfExactType<ExpressSlotRadius>()?.radius ??
      fallback;

  @override
  bool updateShouldNotify(ExpressSlotRadius oldWidget) =>
      oldWidget.radius != radius;
}

/// Staggered spring entrance animation adapted from InlitX/streak ExpressReveal.
/// Automatically disables itself when MediaQuery.disableAnimations is true.
class ExpressReveal extends StatefulWidget {
  final int index;
  final double rise;
  final Widget child;

  const ExpressReveal({
    super.key,
    this.index = 0,
    this.rise = 16,
    required this.child,
  });

  @override
  State<ExpressReveal> createState() => _ExpressRevealState();
}

class _ExpressRevealState extends State<ExpressReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Express.normal,
  );
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
      return;
    }
    Future.delayed(
      Duration(milliseconds: 40 * widget.index.clamp(0, 8)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final settle = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.rise * (1 - settle)),
            child: Transform.scale(
              scale: 0.97 + 0.03 * settle,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Large display headline header matching Streak's ExpressHeadline.
class ExpressHeadline extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ExpressHeadline({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ExpressType.headlineLarge(
            color: semantic.textPrimary,
            weight: FontWeight.w800,
          ).copyWith(letterSpacing: -0.5),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: ExpressType.bodyMedium(
              color: semantic.textSecondary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tracked uppercase section header label above grouped cards.
class ExpressSectionLabel extends StatelessWidget {
  final String text;

  const ExpressSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 20),
      child: Text(
        text.toUpperCase(),
        style: ExpressType.labelSmall(
          color: semantic.textSecondary,
          weight: FontWeight.w800,
        ).copyWith(letterSpacing: 1.15),
      ),
    );
  }
}

/// Segmented vertical card group with 22px outer edge radius, 6px inner joint radius, and 3px gaps.
class ExpressGroup extends StatelessWidget {
  final List<Widget> children;

  const ExpressGroup({super.key, required this.children});

  static const double edgeRadius = 22.0;
  static const double jointRadius = 6.0;
  static const double groupGap = 3.0;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    const edge = Radius.circular(edgeRadius);
    const joint = Radius.circular(jointRadius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == children.length - 1 ? 0 : groupGap,
            ),
            child: ExpressSlotRadius(
              radius: BorderRadius.only(
                topLeft: i == 0 ? edge : joint,
                topRight: i == 0 ? edge : joint,
                bottomLeft: i == children.length - 1 ? edge : joint,
                bottomRight: i == children.length - 1 ? edge : joint,
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

/// Tactile Streak-style row inside or outside an [ExpressGroup].
class ExpressTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final Color? tint;
  final VoidCallback? onTap;
  final bool dense;
  final bool showChevron;
  final Widget? badge;

  const ExpressTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.tint,
    this.onTap,
    this.dense = false,
    this.showChevron = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = tint ?? semantic.primary;
    final radius = ExpressSlotRadius.of(context, BorderRadius.circular(20));
    final compact = dense || CompactDensity.of(context);
    final effectiveSubtitle = compact ? null : subtitle;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: radius,
        border: Border.all(color: semantic.cardBorder, width: 1.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 12 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 40,
            height: compact ? 34 : 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: compact ? 17 : 19, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ExpressType.titleMedium(
                          color: semantic.textPrimary,
                          weight: FontWeight.w700,
                        ).copyWith(fontSize: 15.5, letterSpacing: -0.2),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      badge!,
                    ],
                  ],
                ),
                if (effectiveSubtitle != null && effectiveSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    effectiveSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.bodySmall(
                      color: semantic.textSecondary,
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 12.5, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (value != null && value!.isNotEmpty) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: ExpressType.labelLarge(
                  color: accent,
                  weight: FontWeight.w700,
                ).copyWith(fontSize: 13.5),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null && showChevron && trailing == null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: semantic.textSecondary.withValues(alpha: 0.65),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return cardContent;
    return ExpressSquish(onTap: onTap, child: cardContent);
  }
}

/// Morphing pill switch adapted directly from Streak's ExpressSwitch.
class ExpressSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? tint;

  const ExpressSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final accent = tint ?? semantic.primary;

    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: Express.quick,
          curve: Express.settle,
          width: 54,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 3.5),
          decoration: BoxDecoration(
            color: value
                ? accent
                : semantic.textSecondary.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedAlign(
            duration: Express.normal,
            curve: Express.bouncy,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: Express.normal,
              curve: Express.bouncy,
              width: value ? 25 : 20,
              height: value ? 25 : 20,
              decoration: ShapeDecoration(
                color: value ? semantic.onVibrant : semantic.cardBg,
                shape: ExpressBorder(
                  shape: value
                      ? ExpressShape.cookie.copyWith(rotation: 0.35)
                      : ExpressShape.circle,
                ),
              ),
              child: value
                  ? Icon(Icons.check_rounded, size: 14, color: accent)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Express toggle row wrapping [ExpressTile] and [ExpressSwitch], with optional Info modal on row tap.
class ExpressToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? tint;

  const ExpressToggleTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      tint: tint,
      showChevron: false,
      onTap: () => onChanged(!value),
      trailing: ExpressSwitch(
        value: value,
        onChanged: onChanged,
        tint: tint,
      ),
    );
  }
}

/// 2x2 Bento Grid category card for tablets / wider viewports matching Streak's `_SectionTile`.
class ExpressBentoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? tint;
  final VoidCallback onTap;

  const ExpressBentoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = tint ?? semantic.primary;

    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          color: semantic.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: semantic.cardBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: semantic.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpressBlob(
              size: 46,
              color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
              shape: ExpressShape.cookie,
              child: Icon(icon, size: 22, color: accent),
            ),
            const Spacer(),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ExpressType.titleMedium(
                color: semantic.textPrimary,
                weight: FontWeight.w800,
              ).copyWith(fontSize: 17, height: 1.15),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ExpressType.bodySmall(
                color: semantic.textSecondary,
                weight: FontWeight.w500,
              ).copyWith(fontSize: 12.5, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable Streak-style scaffold for Settings sub-pages (Express or Classic presentation).
class SettingsSubPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;
  final bool isExpressStyle;
  final bool isCompact;
  final double bottomPadding;

  const SettingsSubPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.actions = const [],
    required this.isExpressStyle,
    required this.isCompact,
    this.bottomPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final theme = Theme.of(context);

    return CompactDensity(
      isCompact: isCompact,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: isExpressStyle
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: 58,
                leadingWidth: 66,
                shape: const Border(),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Center(
                    child: ExpressIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                actions: [
                  ...actions,
                  const SizedBox(width: 8),
                ],
              )
            : AppBar(
                title: Text(
                  title,
                  style: TextStyle(
                    color: semantic.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                actions: actions,
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(18, isExpressStyle ? 2 : 8, 18, bottomPadding),
              children: [
                if (isExpressStyle) ...[
                  ExpressHeadline(title: title, subtitle: subtitle),
                  const SizedBox(height: 18),
                ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                    child: Text(
                      subtitle!,
                      style: ExpressType.bodySmall(
                        color: semantic.textSecondary,
                        weight: FontWeight.w500,
                      ).copyWith(fontSize: 13),
                    ),
                  ),
                ],
                for (var i = 0; i < children.length; i++)
                  ExpressReveal(index: i, child: children[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Classic white bordered container used when [SettingsVisualStyle.classic] is active.
class ClassicCard extends StatelessWidget {
  final List<Widget> children;

  const ClassicCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: semantic.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: semantic.cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: semantic.shadow,
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

/// Classic row with soft square 9px badge & trailing value / chevron.
class ClassicRow extends StatelessWidget {
  final IconData icon;
  final Color? tint;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ClassicRow({
    super.key,
    required this.icon,
    this.tint,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = tint ?? semantic.primary;
    final compact = CompactDensity.of(context);
    final effectiveSubtitle = compact ? null : subtitle;

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 11 : 13.5,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ExpressType.titleMedium(
                    color: semantic.textPrimary,
                    weight: FontWeight.w600,
                  ).copyWith(fontSize: 15.5, letterSpacing: -0.2),
                ),
                if (effectiveSubtitle != null && effectiveSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    effectiveSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ExpressType.bodySmall(
                      color: semantic.textSecondary,
                    ).copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (value != null && value!.isNotEmpty) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: semantic.textSecondary,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null && trailing == null) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: semantic.textSecondary.withValues(alpha: 0.6),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Indented divider inside [ClassicCard].
class ClassicDivider extends StatelessWidget {
  const ClassicDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 62,
      endIndent: 16,
      color: semantic.cardBorder,
    );
  }
}

/// Opens a clean Streak-style modal option sheet.
Future<void> showStreakOptionSheet<T>({
  required BuildContext context,
  required String title,
  String? note,
  required List<({T value, String label, String? subtitle, IconData icon})> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  final semantic = AppSemanticColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: ExpressType.titleLarge(
                color: semantic.textPrimary,
                weight: FontWeight.w800,
              ).copyWith(fontSize: 19),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: ExpressType.bodySmall(
                  color: semantic.textSecondary,
                ).copyWith(fontSize: 13.5, height: 1.4),
              ),
            ],
            const SizedBox(height: 14),
            for (final opt in options) ...[
              _StreakSheetOptionTile(
                icon: opt.icon,
                label: opt.label,
                subtitle: opt.subtitle,
                isSelected: opt.value == selected,
                semantic: semantic,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  onSelected(opt.value);
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    ),
  );
}

class _StreakSheetOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final AppSemanticColors semantic;
  final VoidCallback onTap;

  const _StreakSheetOptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = semantic.primary;
    return ExpressSquish(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : semantic.cardSubtleBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.55) : semantic.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? accent : semantic.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ExpressType.titleMedium(
                      color: isSelected ? accent : semantic.textPrimary,
                      weight: FontWeight.w700,
                    ).copyWith(fontSize: 15),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: ExpressType.bodySmall(
                        color: semantic.textSecondary,
                      ).copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Streak-style info modal explaining a read-only setting or invariant rule cleanly.
Future<void> showStreakInfoSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String description,
  String? badgeValue,
  Color? tint,
}) {
  final semantic = AppSemanticColors.of(context);
  final accent = tint ?? semantic.primary;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: semantic.cardBg,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: phoneWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetCtx) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExpressBlob(
                  size: 42,
                  color: accent.withValues(alpha: 0.15),
                  shape: ExpressShape.cookie,
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: ExpressType.titleLarge(
                      color: semantic.textPrimary,
                      weight: FontWeight.w800,
                    ).copyWith(fontSize: 18.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: ExpressType.bodyMedium(
                color: semantic.textSecondary,
              ).copyWith(fontSize: 14, height: 1.5),
            ),
            if (badgeValue != null && badgeValue.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: semantic.cardSubtleBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: semantic.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 17, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        badgeValue,
                        style: ExpressType.titleSmall(
                          color: semantic.textPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
