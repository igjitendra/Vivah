import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

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

/// Floating Pill Bottom Navigation Bar (Expanding Chip design) for Mobile
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
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomMargin = (bottomInset > 0 ? bottomInset : 12.0) + 6.0;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomMargin,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: AppRadius.roundedPill,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final bool isFocused = index == currentIndex;
              final TabItemData item = items[index];

              if (isFocused) {
                // Expanding chip active tab
                return GestureDetector(
                  onTap: () => onTabSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: AppRadius.roundedChip,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40C05A2B),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.activeIcon, size: 19, color: AppColors.surfaceWhite),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: AppColors.surfaceWhite,
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

              // Inactive compact tab
              return GestureDetector(
                onTap: () => onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Icon(
                    item.inactiveIcon,
                    size: 22,
                    color: AppColors.textSecondary,
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
