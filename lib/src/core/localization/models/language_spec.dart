import 'package:flutter/material.dart';

/// Review and translation readiness status of a language
enum LanguageReviewStatus {
  notStarted('Not Started', 'अप्रकाशित'),
  draft('Draft / Machine Translated', 'प्रारूप'),
  nativeReviewPending('Native Review Pending', 'पुनरीक्षण लंबित'),
  nativeReviewed('Native Reviewed', 'समीक्षित'),
  approved('Approved & Released', 'अनुमोदित');

  final String labelEnglish;
  final String labelHindi;
  const LanguageReviewStatus(this.labelEnglish, this.labelHindi);
}

/// Comprehensive specification for an Indian or fallback language.
/// Distinguishes language, script, region, text direction, and font family.
class LanguageSpec {
  final String languageCode; // ISO 639-1 / 639-2 / 639-3 (e.g. 'hi', 'ur', 'sat', 'brx')
  final String? scriptCode; // ISO 15924 (e.g. 'Deva', 'Arab', 'Beng', 'Olck', 'Mtei')
  final String? countryCode; // ISO 3166-1 alpha-2 (e.g. 'IN')
  final String nameEnglish; // e.g. 'Hindi', 'Santali'
  final String nameNative; // e.g. 'हिन्दी', 'ᱥᱟᱱᱛᱟᱲᱤ'
  final TextDirection textDirection; // TextDirection.ltr or TextDirection.rtl
  final String primaryFontFamily; // e.g. 'NotoSansDevanagari', 'NotoNastaliqUrdu'
  final List<String> fallbackFontFamilies;
  final bool isScheduledLanguage; // 8th Schedule of the Constitution of India
  final LanguageReviewStatus reviewStatus;
  final double lineSpacingMultiplier; // For complex scripts with tall matras

  const LanguageSpec({
    required this.languageCode,
    this.scriptCode,
    this.countryCode = 'IN',
    required this.nameEnglish,
    required this.nameNative,
    this.textDirection = TextDirection.ltr,
    required this.primaryFontFamily,
    this.fallbackFontFamilies = const [],
    this.isScheduledLanguage = false,
    this.reviewStatus = LanguageReviewStatus.draft,
    this.lineSpacingMultiplier = 1.0,
  });

  /// BCP 47 Language Tag
  String get bcp47Tag {
    final parts = [languageCode];
    if (scriptCode != null && scriptCode!.isNotEmpty) {
      parts.add(scriptCode!);
    }
    if (countryCode != null && countryCode!.isNotEmpty) {
      parts.add(countryCode!);
    }
    return parts.join('-');
  }

  /// Construct Flutter Locale
  Locale get locale {
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }

  bool get isRtl => textDirection == TextDirection.rtl;

  @override
  String toString() => '$nameEnglish ($nameNative) [$bcp47Tag]';
}
