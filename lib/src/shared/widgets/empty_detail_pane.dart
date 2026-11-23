import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/express_type.dart';
import 'app_logo.dart';

/// Reusable empty detail pane for desktop dual-pane (Split-View) layouts.
/// Shown on PC/wide desktop screens when no master item is currently selected.
class EmptyDetailPane extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyDetailPane({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Symbol with soft glow
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : AppColors.warmCream,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.terracotta.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: const AppSymbol(size: 52),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: ExpressType.titleMedium().copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: ExpressType.bodyMedium().copyWith(
                    color: textSecondary,
                    height: 1.45,
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }
}
