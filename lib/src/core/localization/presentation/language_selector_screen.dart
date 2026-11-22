import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../language_registry.dart';
import '../locale_notifier.dart';
import '../app_localizations.dart';
import '../../../shared/widgets/express_squish.dart';

/// Screen allowing users to switch between pure English and all 22 Eighth-Schedule Indian languages.
/// Fully theme-adaptive with search and instant reactive app re-render.
class LanguageSelectorScreen extends ConsumerStatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  ConsumerState<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends ConsumerState<LanguageSelectorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(List<String> values, String query) {
    if (query.isEmpty) return true;
    final cleanQuery = query.toLowerCase().trim();
    for (final val in values) {
      if (val.toLowerCase().contains(cleanQuery)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final allLanguages = LanguageRegistry.instance.getAllLanguages();
    final l10n = context.l10n;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final headerBg = isDark ? theme.colorScheme.surface : theme.colorScheme.secondary;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;
    final cardBorder = isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0);
    final searchBg = isDark ? const Color(0xFF161A24) : const Color(0xFFF1F5F9);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryAccent = theme.colorScheme.primary;

    final filteredLanguages = allLanguages.where((lang) {
      return _matchesQuery([
        lang.nameNative,
        lang.nameEnglish,
        lang.languageCode,
        if (lang.scriptCode != null) lang.scriptCode!,
      ], _searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          l10n.selectLanguageTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: headerBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.searchLanguageHint,
                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                  prefixIcon: Icon(Icons.search, color: textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),

          // Informational Subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            color: isDark ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
            child: Text(
              l10n.scheduledLanguagesSubtitle(allLanguages.length - 1),
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Language List
          Expanded(
            child: ListView.separated(
              itemCount: filteredLanguages.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16, color: cardBorder),
              itemBuilder: (context, index) {
                final lang = filteredLanguages[index];
                final isSelected = (currentLocale.languageCode == lang.languageCode &&
                    (lang.scriptCode == null || currentLocale.scriptCode == lang.scriptCode));

                return ListTile(
                  tileColor: isSelected ? (isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9)) : Colors.transparent,
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? primaryAccent : (isDark ? const Color(0xFF262E3D) : const Color(0xFFE2E8F0)),
                    child: Text(
                      lang.nameNative.isNotEmpty ? lang.nameNative.characters.first : lang.nameEnglish[0],
                      style: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        lang.nameNative,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? primaryAccent : textPrimary,
                        ),
                      ),
                      if (lang.isRtl) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RTL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ),
                      ],
                      if (lang.scriptCode != null && lang.scriptCode != 'Deva') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang.scriptCode!,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${lang.nameEnglish} • ${lang.bcp47Tag}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: primaryAccent)
                      : Icon(Icons.chevron_right, color: textSecondary),
                  onTap: () async {
                    await ref.read(localeProvider.notifier).setLanguage(lang);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.languageChangedTo('${lang.nameNative} (${lang.nameEnglish})')),
                          duration: const Duration(seconds: 2),
                          backgroundColor: primaryAccent,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
