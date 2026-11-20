import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../domain/enums/transaction_enums.dart';

/// Reusable Direction Badge (↓ मिला or ↑ दिया)
class DirectionBadge extends StatelessWidget {
  final TransactionDirection direction;
  final bool isSmall;

  const DirectionBadge({
    super.key,
    required this.direction,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMila = direction == TransactionDirection.mila;
    final Color bgColor = isMila ? AppColors.milaGreenSoft : AppColors.diyaRedSoft;
    final Color textColor = isMila ? AppColors.milaGreen : AppColors.diyaRed;
    final String label = isMila ? '↓ मिला' : '↑ दिया';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: isSmall ? 2.0 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
