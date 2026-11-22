import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/enums/transaction_enums.dart';

/// Reusable Direction Badge (Localized: ↓ Received/मिला or ↑ Given/दिया)
/// Theme-adaptive with soft tinted pill backgrounds in both light and dark mode.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final bool isMila = direction == TransactionDirection.mila || direction == TransactionDirection.received;

    final Color bgColor = isDark
        ? (isMila ? const Color(0xFF1B3D27) : const Color(0xFF451E22))
        : (isMila ? AppColors.milaGreenSoft : AppColors.diyaRedSoft);
    final Color textColor = isMila ? AppColors.milaGreen : AppColors.diyaRed;
    final String label = isMila ? '↓ ${l10n.received}' : '↑ ${l10n.given}';

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
