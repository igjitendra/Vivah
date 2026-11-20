import 'package:flutter/material.dart';
import 'models/language_spec.dart';

/// Central Language and Script Registry for Vyavahaar.
/// Enforces complete support for all 22 Scheduled Languages of the Eighth Schedule
/// of the Constitution of India + English fallback, with an extensible architecture
/// for regional languages and dialects.
class LanguageRegistry {
  LanguageRegistry._();

  static final LanguageRegistry instance = LanguageRegistry._();

  // Internal registry map keyed by BCP 47 tag
  final Map<String, LanguageSpec> _languages = {};

  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;

    // 1. English (Development & Fallback)
    _register(const LanguageSpec(
      languageCode: 'en',
      countryCode: 'IN',
      nameEnglish: 'English',
      nameNative: 'English',
      textDirection: TextDirection.ltr,
      primaryFontFamily: 'Roboto',
      reviewStatus: LanguageReviewStatus.approved,
    ));

    // 2. The 22 Scheduled Indian Languages (Eighth Schedule)

    // Assamese (অসমীয়া)
    _register(const LanguageSpec(
      languageCode: 'as',
      scriptCode: 'Beng',
      countryCode: 'IN',
      nameEnglish: 'Assamese',
      nameNative: 'অসমীয়া',
      primaryFontFamily: 'NotoSansBengali',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Bengali (বাংলা)
    _register(const LanguageSpec(
      languageCode: 'bn',
      scriptCode: 'Beng',
      countryCode: 'IN',
      nameEnglish: 'Bengali',
      nameNative: 'বাংলা',
      primaryFontFamily: 'NotoSansBengali',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Bodo (बड़ो)
    _register(const LanguageSpec(
      languageCode: 'brx',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Bodo',
      nameNative: 'बड़ो',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Dogri (डोगरी)
    _register(const LanguageSpec(
      languageCode: 'doi',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Dogri',
      nameNative: 'डोगरी',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Gujarati (ગુજરાતી)
    _register(const LanguageSpec(
      languageCode: 'gu',
      scriptCode: 'Gujr',
      countryCode: 'IN',
      nameEnglish: 'Gujarati',
      nameNative: 'ગુજરાતી',
      primaryFontFamily: 'NotoSansGujarati',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Hindi (हिन्दी) - Production Approved Primary Language
    _register(const LanguageSpec(
      languageCode: 'hi',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Hindi',
      nameNative: 'हिन्दी',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.approved,
      lineSpacingMultiplier: 1.15,
    ));

    // Kannada (ಕನ್ನಡ)
    _register(const LanguageSpec(
      languageCode: 'kn',
      scriptCode: 'Knda',
      countryCode: 'IN',
      nameEnglish: 'Kannada',
      nameNative: 'ಕನ್ನಡ',
      primaryFontFamily: 'NotoSansKannada',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.2,
    ));

    // Kashmiri (Perso-Arabic) (کٲشُر) - RTL
    _register(const LanguageSpec(
      languageCode: 'ks',
      scriptCode: 'Arab',
      countryCode: 'IN',
      nameEnglish: 'Kashmiri (Arabic)',
      nameNative: 'کٲشُر',
      textDirection: TextDirection.rtl,
      primaryFontFamily: 'NotoNastaliqUrdu',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.3,
    ));

    // Kashmiri (Devanagari variant)
    _register(const LanguageSpec(
      languageCode: 'ks',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Kashmiri (Devanagari)',
      nameNative: 'कॉशुर',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Konkani (कोंकणी)
    _register(const LanguageSpec(
      languageCode: 'kok',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Konkani',
      nameNative: 'कोंकणी',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Maithili (मैथिली)
    _register(const LanguageSpec(
      languageCode: 'mai',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Maithili',
      nameNative: 'मैथिली',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Malayalam (മലയാളം)
    _register(const LanguageSpec(
      languageCode: 'ml',
      scriptCode: 'Mlym',
      countryCode: 'IN',
      nameEnglish: 'Malayalam',
      nameNative: 'മലയാളം',
      primaryFontFamily: 'NotoSansMalayalam',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.2,
    ));

    // Manipuri / Meitei (Meitei Mayek) (ꯃꯩꯇꯩꯂꯣꯟ)
    _register(const LanguageSpec(
      languageCode: 'mni',
      scriptCode: 'Mtei',
      countryCode: 'IN',
      nameEnglish: 'Manipuri (Meitei Mayek)',
      nameNative: 'ꯃꯩꯇꯩꯂꯣꯟ',
      primaryFontFamily: 'NotoSansMeeteiMayek',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Manipuri (Bengali script variant)
    _register(const LanguageSpec(
      languageCode: 'mni',
      scriptCode: 'Beng',
      countryCode: 'IN',
      nameEnglish: 'Manipuri (Bengali script)',
      nameNative: 'মৈতৈলোন্',
      primaryFontFamily: 'NotoSansBengali',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Marathi (मराठी)
    _register(const LanguageSpec(
      languageCode: 'mr',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Marathi',
      nameNative: 'मराठी',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Nepali (नेपाली)
    _register(const LanguageSpec(
      languageCode: 'ne',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Nepali',
      nameNative: 'नेपाली',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Odia (ଓଡ଼ିଆ)
    _register(const LanguageSpec(
      languageCode: 'or',
      scriptCode: 'Orya',
      countryCode: 'IN',
      nameEnglish: 'Odia',
      nameNative: 'ଓଡ଼ିଆ',
      primaryFontFamily: 'NotoSansOriya',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.2,
    ));

    // Punjabi (Gurmukhi) (ਪੰਜਾਬੀ)
    _register(const LanguageSpec(
      languageCode: 'pa',
      scriptCode: 'Guru',
      countryCode: 'IN',
      nameEnglish: 'Punjabi',
      nameNative: 'ਪੰਜਾਬੀ',
      primaryFontFamily: 'NotoSansGurmukhi',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Sanskrit (संस्कृतम्)
    _register(const LanguageSpec(
      languageCode: 'sa',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Sanskrit',
      nameNative: 'संस्कृतम्',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Santali (Ol Chiki) (ᱥᱟᱱᱛᱟᱲᱤ)
    _register(const LanguageSpec(
      languageCode: 'sat',
      scriptCode: 'Olck',
      countryCode: 'IN',
      nameEnglish: 'Santali',
      nameNative: 'ᱥᱟᱱᱛᱟᱲᱤ',
      primaryFontFamily: 'NotoSansOlChiki',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Sindhi (Perso-Arabic) (سنڌي) - RTL
    _register(const LanguageSpec(
      languageCode: 'sd',
      scriptCode: 'Arab',
      countryCode: 'IN',
      nameEnglish: 'Sindhi (Arabic)',
      nameNative: 'سنڌي',
      textDirection: TextDirection.rtl,
      primaryFontFamily: 'NotoNastaliqUrdu',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.3,
    ));

    // Sindhi (Devanagari variant)
    _register(const LanguageSpec(
      languageCode: 'sd',
      scriptCode: 'Deva',
      countryCode: 'IN',
      nameEnglish: 'Sindhi (Devanagari)',
      nameNative: 'सिन्धी',
      primaryFontFamily: 'NotoSansDevanagari',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.15,
    ));

    // Tamil (தமிழ்)
    _register(const LanguageSpec(
      languageCode: 'ta',
      scriptCode: 'Taml',
      countryCode: 'IN',
      nameEnglish: 'Tamil',
      nameNative: 'தமிழ்',
      primaryFontFamily: 'NotoSansTamil',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.2,
    ));

    // Telugu (తెలుగు)
    _register(const LanguageSpec(
      languageCode: 'te',
      scriptCode: 'Telu',
      countryCode: 'IN',
      nameEnglish: 'Telugu',
      nameNative: 'తెలుగు',
      primaryFontFamily: 'NotoSansTelugu',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.2,
    ));

    // Urdu (اردو) - RTL
    _register(const LanguageSpec(
      languageCode: 'ur',
      scriptCode: 'Arab',
      countryCode: 'IN',
      nameEnglish: 'Urdu',
      nameNative: 'اردو',
      textDirection: TextDirection.rtl,
      primaryFontFamily: 'NotoNastaliqUrdu',
      isScheduledLanguage: true,
      reviewStatus: LanguageReviewStatus.draft,
      lineSpacingMultiplier: 1.35,
    ));

    _initialized = true;
  }

  void _register(LanguageSpec spec) {
    _languages[spec.bcp47Tag] = spec;
    // Also map by primary languageCode if not present
    if (!_languages.containsKey(spec.languageCode)) {
      _languages[spec.languageCode] = spec;
    }
  }

  /// Register an additional regional language or dialect dynamically (Bhojpuri, Rajasthani, Tulu, etc.)
  void registerLanguage(LanguageSpec spec) {
    ensureInitialized();
    _register(spec);
  }

  /// Return all registered languages
  List<LanguageSpec> getAllLanguages() {
    ensureInitialized();
    // Return distinct specs
    final seen = <String>{};
    final list = <LanguageSpec>[];
    for (final spec in _languages.values) {
      if (!seen.contains(spec.bcp47Tag)) {
        seen.add(spec.bcp47Tag);
        list.add(spec);
      }
    }
    return list;
  }

  /// Return all 22 scheduled Indian languages
  List<LanguageSpec> getScheduledLanguages() {
    return getAllLanguages().where((l) => l.isScheduledLanguage).toList();
  }

  /// Find language by BCP 47 tag, language code, or subtag
  LanguageSpec? getLanguage(String identifier) {
    ensureInitialized();
    if (_languages.containsKey(identifier)) {
      return _languages[identifier];
    }
    // Try matching language code part
    final langCode = identifier.split('-').first.toLowerCase();
    for (final spec in _languages.values) {
      if (spec.languageCode.toLowerCase() == langCode) {
        return spec;
      }
    }
    return null;
  }

  /// Resolve language from Flutter Locale
  LanguageSpec getLanguageByLocale(Locale locale) {
    ensureInitialized();
    final tag = locale.toLanguageTag();
    final direct = getLanguage(tag);
    if (direct != null) return direct;

    final byCode = getLanguage(locale.languageCode);
    if (byCode != null) return byCode;

    // Default to Hindi, then English
    return getLanguage('hi') ?? getLanguage('en')!;
  }

  /// Check if a locale requires Right-to-Left (RTL) text direction
  bool isRtl(Locale locale) {
    final spec = getLanguageByLocale(locale);
    return spec.isRtl;
  }

  /// Get supported Flutter locales list
  List<Locale> getSupportedLocales() {
    return getAllLanguages().map((l) => l.locale).toList();
  }
}
