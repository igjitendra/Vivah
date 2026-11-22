import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/express_type.dart';
import '../../core/utils/responsive.dart';
import '../widgets/app_logo.dart';
import '../widgets/express_squish.dart';
import 'floating_pill_tab_bar.dart';

/// Desktop & Tablet Navigation Rail directly adapted from InlitX/streak (ExpressNavRail).
/// Features mouse hover states, squircle morphing active indicators, and responsive widths.
class ExpressNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final List<TabItemData> items;
  final VoidCallback? onOpenShortcuts;

  const ExpressNavRail({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.items,
    this.onOpenShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final compact = isCompactRail(context);

    final bg = isDark ? const Color(0xFF131722) : const Color(0xFFFAF7F2);
    final border = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);

    return Container(
      width: compact ? 80.0 : 230.0,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border, width: 1)),
      ),
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: 18,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Brand Lockup
              if (compact)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const AppSymbol(size: 26),
                  ),
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.deepNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const AppSymbol(size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'व्यवहार',
                            style: ExpressType.titleLarge(
                              color: isDark ? Colors.white : AppColors.deepNavy,
                              weight: FontWeight.w900,
                            ).copyWith(fontSize: 18, letterSpacing: 0.5),
                          ),
                          Text(
                            'रिश्तों का हिसाब',
                            style: ExpressType.bodySmall(
                              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            ).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // 2. Navigation Items
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ExpressRailPill(
                    item: items[i],
                    selected: i == currentIndex,
                    compact: compact,
                    onTap: () => onSelect(i),
                  ),
                ),

              const Spacer(),

              // 3. Desktop Shortcuts / Help Button
              if (onOpenShortcuts != null)
                Tooltip(
                  message: 'Keyboard Shortcuts (F1)',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onOpenShortcuts,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2634) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_outlined,
                              size: 16,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Shortcuts (F1)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpressRailPill extends StatefulWidget {
  final TabItemData item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ExpressRailPill({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_ExpressRailPill> createState() => _ExpressRailPillState();
}

class _ExpressRailPillState extends State<_ExpressRailPill> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = widget.selected;
    final compact = widget.compact;

    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final unselectedFg = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final bg = selected
        ? primary
        : (_hover
            ? primary.withValues(alpha: isDark ? 0.20 : 0.10)
            : Colors.transparent);

    final fg = selected
        ? onPrimary
        : (_hover
            ? (isDark ? Colors.white : AppColors.deepNavy)
            : unselectedFg);

    return Semantics(
      button: true,
      selected: selected,
      label: widget.item.label,
      child: Tooltip(
        message: compact ? widget.item.label : '',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _down ? 0.95 : (_hover && !selected ? 1.02 : 1.0),
              duration: _down ? Express.fast : Express.quick,
              curve: _down ? Express.settle : Express.bouncy,
              child: AnimatedContainer(
                duration: Express.quick,
                curve: Express.settle,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(selected ? 16 : 12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? widget.item.activeIcon : widget.item.inactiveIcon,
                      size: 20,
                      color: fg,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: ExpressType.labelLarge(
                            color: fg,
                            weight: selected ? FontWeight.w800 : FontWeight.w600,
                          ).copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
