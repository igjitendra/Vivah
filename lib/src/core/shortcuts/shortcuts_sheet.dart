import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/express_type.dart';
import '../../shared/widgets/express_button.dart';

/// Desktop Shortcuts Sheet modal inspired directly by InlitX/streak
class ShortcutsSheet extends StatelessWidget {
  const ShortcutsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ShortcutsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMac = Platform.isMacOS;
    final cmd = isMac ? '⌘' : 'Ctrl';

    final bg = isDark ? const Color(0xFF161A24) : Colors.white;
    final border = isDark ? const Color(0xFF2B3342) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : AppColors.deepNavy;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final shortcuts = [
      _ShortcutItem('$cmd + 1', 'होम डैशबोर्ड (Home)'),
      _ShortcutItem('$cmd + 2', 'बही-खाता (Bahi Ledger)'),
      _ShortcutItem('$cmd + 3', 'कार्यक्रम (Events)'),
      _ShortcutItem('$cmd + 4', 'लोग व रिश्तेदार (People)'),
      _ShortcutItem('$cmd + 5', 'सेटिंग्स (Settings)'),
      _ShortcutItem('$cmd + N', 'नया व्यवहार दर्ज करें (New Entry)'),
      _ShortcutItem('$cmd + F', 'खोजें (Search)'),
      _ShortcutItem('F1 / $cmd + /', 'कीबोर्ड शॉर्टकट्स गाइड (This Sheet)'),
      _ShortcutItem('Esc', 'बंद करें / पीछे जाएं (Close / Back)'),
    ];

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border, width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.keyboard_outlined,
                          size: 20,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'कीबोर्ड शॉर्टकट्स (Desktop Shortcuts)',
                        style: ExpressType.titleMedium(
                          color: textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  ExpressIconButton(
                    icon: Icons.close,
                    size: 32,
                    radius: 10,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: border),
              const SizedBox(height: 12),

              // Shortcuts List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: shortcuts.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: border.withValues(alpha: 0.5)),
                  itemBuilder: (context, index) {
                    final item = shortcuts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.description,
                              style: ExpressType.bodyMedium(
                                color: textSecondary,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF222B38) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item.keyCombination,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              ExpressButton(
                label: 'समझ गया (Done)',
                tone: ExpressTone.filled,
                expand: true,
                compact: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutItem {
  final String keyCombination;
  final String description;

  const _ShortcutItem(this.keyCombination, this.description);
}
