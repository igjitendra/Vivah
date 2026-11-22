import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../widgets/express_squish.dart';

class TabItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String routePath;

  const TabItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.routePath,
  });
}

/// Floating Pill Bottom Navigation Bar with tactile spring physics (InlitX/streak inspired)
class FloatingPillTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<TabItemData> items;

  const FloatingPillTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomMargin = (bottomInset > 0 ? bottomInset : 12.0) + 6.0;

    final barBg = isDark ? const Color(0xFF161A24) : Colors.white;
    final barBorder = isDark ? const Color(0xFF262C3D) : const Color(0xFFE2E8F0);
    final activeBg = theme.colorScheme.primary;
    final activeFg = theme.colorScheme.onPrimary;
    final inactiveFg = isDark ? const Color(0xFF8895AA) : const Color(0xFF64748B);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomMargin,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: barBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: barBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black45 : const Color(0x1E0F172A),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final bool isFocused = index == currentIndex;
              final TabItemData item = items[index];

              if (isFocused) {
                // Expanding active chip with spring squish
                return ExpressSquish(
                  scale: 0.94,
                  onTap: () => onTabSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: activeBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: activeBg.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.activeIcon, size: 19, color: activeFg),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: activeFg,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Inactive tab with spring squish
              return ExpressSquish(
                scale: 0.90,
                onTap: () => onTabSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Icon(
                    item.inactiveIcon,
                    size: 22,
                    color: inactiveFg,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
