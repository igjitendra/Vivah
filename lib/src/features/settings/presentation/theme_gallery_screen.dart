import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/theme_palette.dart';
import '../../../core/theme/theme_notifier.dart';

/// Screen allowing users to select Theme Mode (Auto, Light, Dark)
/// and choose from curated Light & Dark theme color palettes.
class ThemeGalleryScreen extends ConsumerWidget {
  const ThemeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isCurrentDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: isCurrentDark ? const Color(0xFF0F172A) : AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isCurrentDark ? Colors.white : AppColors.deepNavy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.themeGalleryTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            Text(
              l10n.themeGallerySubtitle,
              style: TextStyle(
                fontSize: 12,
                color: isCurrentDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.done,
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCurrentDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrentDark ? const Color(0xFF334155) : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      context,
                      label: l10n.colorThemeAuto,
                      icon: Icons.brightness_auto,
                      isSelected: themeState.themeMode == ThemeMode.system,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system),
                      isDarkUi: isCurrentDark,
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      context,
                      label: l10n.colorThemeLight,
                      icon: Icons.light_mode_outlined,
                      isSelected: themeState.themeMode == ThemeMode.light,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.light),
                      isDarkUi: isCurrentDark,
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      context,
                      label: l10n.colorThemeDark,
                      icon: Icons.dark_mode_outlined,
                      isSelected: themeState.themeMode == ThemeMode.dark,
                      onTap: () => ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark),
                      isDarkUi: isCurrentDark,
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
                fontWeight: FontWeight.bold,
                color: isCurrentDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            Text(
              l10n.lightThemeDescription,
              style: TextStyle(
                fontSize: 12,
                color: isCurrentDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
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
                childAspectRatio: 1.35,
              ),
              itemCount: ThemePalette.lightPalettes.length,
              itemBuilder: (context, index) {
                final palette = ThemePalette.lightPalettes[index];
                final isSelected = themeState.lightPalette.id == palette.id;
                return _buildPaletteCard(
                  palette: palette,
                  isSelected: isSelected,
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
                fontWeight: FontWeight.bold,
                color: isCurrentDark ? Colors.white : AppColors.deepNavy,
              ),
            ),
            Text(
              l10n.darkThemeDescription,
              style: TextStyle(
                fontSize: 12,
                color: isCurrentDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
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
                childAspectRatio: 1.35,
              ),
              itemCount: ThemePalette.darkPalettes.length,
              itemBuilder: (context, index) {
                final palette = ThemePalette.darkPalettes[index];
                final isSelected = themeState.darkPalette.id == palette.id;
                return _buildPaletteCard(
                  palette: palette,
                  isSelected: isSelected,
                  onTap: () => ref.read(themeProvider.notifier).setDarkPalette(palette),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkUi,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkUi ? const Color(0xFF334155) : const Color(0xFFEDE9FE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFFA78BFA), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFFA78BFA)
                  : (isDarkUi ? const Color(0xFF94A3B8) : AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDarkUi ? Colors.white : AppColors.deepNavy)
                    : (isDarkUi ? const Color(0xFF94A3B8) : AppColors.textSecondary),
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFA78BFA) : palette.cardBorder,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini UI Mockup inside card
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 6,
                        width: 14,
                        decoration: BoxDecoration(
                          color: palette.cardBorder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        height: 4,
                        width: 20,
                        decoration: BoxDecoration(
                          color: palette.secondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Color swatch dots
                  Row(
                    children: palette.previewSwatches.map((color) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 8,
                          height: 8,
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
            // Card Footer: Palette Name and Checkmark
            Row(
              children: [
                Expanded(
                  child: Text(
                    palette.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFFA78BFA),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
