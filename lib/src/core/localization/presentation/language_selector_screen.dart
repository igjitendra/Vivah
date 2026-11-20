import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../language_registry.dart';
import '../locale_notifier.dart';
import '../models/language_spec.dart';
import '../unicode_search_utils.dart';

/// Language Selection Screen
/// Allows user to choose their preferred Indian language with native typography.
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

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final allLanguages = LanguageRegistry.instance.getAllLanguages();

    final filteredLanguages = allLanguages.where((lang) {
      if (_searchQuery.isEmpty) return true;
      return UnicodeSearchUtils.matchesAny([
        lang.nameNative,
        lang.nameEnglish,
        lang.languageCode,
        lang.scriptCode,
      ], _searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        title: const Text(
          'भाषा चुनें / Select Language',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'भाषा खोजें / Search language...',
                prefixIcon: const Icon(Icons.search, color: AppColors.mutedText),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.mutedText),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.warmCream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Informational Subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            color: AppColors.warmCream,
            child: Text(
              'संविधान की 8वीं अनुसूची की सभी 22 भारतीय भाषाएं (${allLanguages.length - 1} + English)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Language List
          Expanded(
            child: ListView.separated(
              itemCount: filteredLanguages.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final lang = filteredLanguages[index];
                final isSelected = (currentLocale.languageCode == lang.languageCode &&
                    (lang.scriptCode == null || currentLocale.scriptCode == lang.scriptCode));

                return ListTile(
                  tileColor: isSelected ? AppColors.white : Colors.transparent,
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppColors.terracotta : AppColors.cardBorder,
                    child: Text(
                      lang.nameNative.isNotEmpty ? lang.nameNative.characters.first : lang.nameEnglish[0],
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.deepNavy,
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
                          fontSize: 17,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.terracotta : AppColors.textPrimary,
                        ),
                      ),
                      if (lang.isRtl) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RTL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      if (lang.scriptCode != null && lang.scriptCode != 'Deva') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lang.scriptCode!,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${lang.nameEnglish} • ${lang.bcp47Tag}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.terracotta)
                      : const Icon(Icons.chevron_right, color: AppColors.cardBorder),
                  onTap: () async {
                    await ref.read(localeProvider.notifier).setLanguage(lang);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('भाषा बदली गई: ${lang.nameNative} (${lang.nameEnglish})'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppColors.deepNavy,
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
