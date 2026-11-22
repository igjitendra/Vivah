import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/theme_palette.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../../shared/widgets/express_squish.dart';

/// Pixel-perfect Theme Gallery matching user specification with
/// Auto/Light/Dark mode toggle, 8 Light Themes, and 17 Dark Themes.
class ThemeGalleryScreen extends ConsumerWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isCurrentDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    final bgColor = isCurrentDark ? const Color(0xFF0C0E14) : const Color(0xFFF8FAFC);
    final cardBg = isCurrentDark ? const Color(0xFF141722) : Colors.white;
    final surfaceBorder = isCurrentDark ? const Color(0xFF232838) : const Color(0xFFE2E8F0);
    final textTitleColor = isCurrentDark ? Colors.white : const Color(0xFF0F172A);
    final textMutedColor = isCurrentDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const purpleAccent = Color(0xFF8B5CF6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textTitleColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.themeGalleryTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textTitleColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.themeGallerySubtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textMutedColor,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ExpressSquish(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // COLOR THEME SELECTOR (Auto / Light / Dark)
            // ==========================================
            Text(
              l10n.colorTheme,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textTitleColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: l10n.colorThemeAuto,
                      icon: Icons.brightness_auto,
                      isSelected: themeState.themeMode == ThemeMode.system,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                      isDark: isCurrentDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildModeTab(
                      label: l10n.colorThemeLight,
                      icon: Icons.light_mode_outlined,
                      isSelected: themeState.themeMode == ThemeMode.light,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                      isDark: isCurrentDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildModeTab(
                      label: l10n.colorThemeDark,
                      icon: Icons.dark_mode_outlined,
                      isSelected: themeState.themeMode == ThemeMode.dark,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                      isDark: isCurrentDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ==========================================
            // LIGHT THEME GALLERY SECTION
            // ==========================================
            Text(
              l10n.lightThemeSection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textTitleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.lightThemeDescription,
              style: TextStyle(
                fontSize: 12,
                color: textMutedColor,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              itemCount: ThemePalette.lightPalettes.length,
              itemBuilder: (context, index) {
                final palette = ThemePalette.lightPalettes[index];
                final isSelected = themeState.lightPalette.id == palette.id;
                final isStar = palette.id == 'porcelain';
                return _buildPaletteCard(
                  palette: palette,
                  isSelected: isSelected,
                  isStar: isStar,
                  isDarkUi: isCurrentDark,
                  onTap: () => ref.read(themeProvider.notifier).setLightPalette(palette),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ==========================================
            // DARK THEME GALLERY SECTION
            // ==========================================
            Text(
              l10n.darkThemeSection,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textTitleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.darkThemeDescription,
              style: TextStyle(
                fontSize: 12,
                color: textMutedColor,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              itemCount: ThemePalette.darkPalettes.length,
              itemBuilder: (context, index) {
                final palette = ThemePalette.darkPalettes[index];
                final isSelected = themeState.darkPalette.id == palette.id;
                final isStar = palette.id == 'midnight_aurora';
                return _buildPaletteCard(
                  palette: palette,
                  isSelected: isSelected,
                  isStar: isStar,
                  isDarkUi: isCurrentDark,
                  onTap: () => ref.read(themeProvider.notifier).setDarkPalette(palette),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bottom note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrentDark ? const Color(0xFF141722) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.palette, size: 20, color: purpleAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.isEnglish
                          ? 'Personalize your Vyavahaar ledger with curated themes. Settings are saved permanently.'
                          : 'व्यवहार बही-खाते को अपने मनपसंद रंग व थीम में सजाएं। यह चयन हमेशा सुरक्षित रहेगा।',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMutedColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const purpleAccent = Color(0xFF8B5CF6);

    return ExpressSquish(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF26203D) : const Color(0xFFEDE9FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: purpleAccent, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? purpleAccent
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF6D28D9))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteCard({
    required ThemePalette palette,
    required bool isSelected,
    required bool isStar,
    required bool isDarkUi,
    required VoidCallback onTap,
  }) {
    const purpleAccent = Color(0xFF8B5CF6);

    return ExpressSquish(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkUi ? const Color(0xFF141722) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? purpleAccent
                : (isDarkUi ? const Color(0xFF222634) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: purpleAccent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inner Miniature Screen Preview
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: palette.cardBorder.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 5,
                        width: 32,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Spacer(),
                      if (isStar)
                        Container(
                          width: 13,
                          height: 13,
                          decoration: const BoxDecoration(
                            color: purpleAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 9,
                            color: Colors.white,
                          ),
                        )
                      else
                        Container(
                          height: 5,
                          width: 14,
                          decoration: BoxDecoration(
                            color: palette.cardBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    height: 3.5,
                    width: 20,
                    decoration: BoxDecoration(
                      color: palette.secondary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: palette.previewSwatches.take(5).map((color) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 3.5),
                        child: Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Theme Name & Selection indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    palette.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isDarkUi ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: purpleAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
