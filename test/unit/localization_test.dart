import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/localization/language_registry.dart';
import 'package:vyavahaar/src/core/localization/locale_formatter.dart';
import 'package:vyavahaar/src/core/localization/models/language_spec.dart';
import 'package:vyavahaar/src/core/localization/unicode_search_utils.dart';

void main() {
  group('Multilingual Localization Architecture Tests (Step 2.5)', () {
    final registry = LanguageRegistry.instance;

    test('Registry contains all 22 Scheduled Indian Languages + English', () {
      final scheduled = registry.getScheduledLanguages();
      final distinctScheduledCodes = scheduled.map((s) => s.languageCode.split('-').first).toSet();
      expect(distinctScheduledCodes.length, equals(22));
      expect(scheduled.length, equals(25));

      final all = registry.getAllLanguages();
      // 22 scheduled + English = 23 primary language entries
      expect(all.length >= 23, isTrue);

      final english = registry.getLanguage('en');
      expect(english, isNotNull);
      expect(english!.nameEnglish, equals('English'));
      expect(english.reviewStatus, equals(LanguageReviewStatus.approved));

      final hindi = registry.getLanguage('hi');
      expect(hindi, isNotNull);
      expect(hindi!.nameNative, equals('हिन्दी'));
      expect(hindi.isScheduledLanguage, isTrue);
      expect(hindi.reviewStatus, equals(LanguageReviewStatus.approved));
    });

    test('RTL is correctly identified for Urdu, Kashmiri, and Sindhi Arabic', () {
      final urdu = registry.getLanguage('ur');
      expect(urdu, isNotNull);
      expect(urdu!.isRtl, isTrue);
      expect(urdu.textDirection, equals(TextDirection.rtl));

      final kashmiriArabic = registry.getLanguage('ks-Arab-IN');
      expect(kashmiriArabic, isNotNull);
      expect(kashmiriArabic!.isRtl, isTrue);

      final sindhiArabic = registry.getLanguage('sd-Arab-IN');
      expect(sindhiArabic, isNotNull);
      expect(sindhiArabic!.isRtl, isTrue);

      final tamil = registry.getLanguage('ta');
      expect(tamil!.isRtl, isFalse);
    });

    test('Extensible language registry supports dynamic registration of regional languages', () {
      const bhojpuri = LanguageSpec(
        languageCode: 'bho',
        scriptCode: 'Deva',
        countryCode: 'IN',
        nameEnglish: 'Bhojpuri',
        nameNative: 'भोजपुरी',
        primaryFontFamily: 'NotoSansDevanagari',
        reviewStatus: LanguageReviewStatus.draft,
      );

      registry.registerLanguage(bhojpuri);
      final retrieved = registry.getLanguage('bho-Deva-IN');
      expect(retrieved, isNotNull);
      expect(retrieved!.nameNative, equals('भोजपुरी'));
    });

    test('LocaleFormatter formats integer paise without floating point issues', () {
      final formatted1100 = LocaleFormatter.formatPaise(110000);
      expect(formatted1100.contains('1,100') || formatted1100.contains('1100'), isTrue);
      expect(formatted1100.contains('₹'), isTrue);

      final formattedZero = LocaleFormatter.formatPaise(0);
      expect(formattedZero.contains('0'), isTrue);
    });

    test('UnicodeSearchUtils matches across diverse Indian scripts', () {
      // Devanagari Hindi
      expect(UnicodeSearchUtils.matches('रामकिशोर शर्मा', 'राम'), isTrue);
      expect(UnicodeSearchUtils.matches('रामकिशोर शर्मा', 'वर्मा'), isFalse);

      // Bengali
      expect(UnicodeSearchUtils.matches('সৌম্য বন্দ্যোপাধ্যায়', 'সৌম্য'), isTrue);

      // Tamil
      expect(UnicodeSearchUtils.matches('முருகன் கணேசன்', 'முருகன்'), isTrue);

      // Urdu
      expect(UnicodeSearchUtils.matches('محمد رضوان', 'رضوان'), isTrue);

      // Gurmukhi Punjabi
      expect(UnicodeSearchUtils.matches('ਹਰਪ੍ਰੀਤ ਸਿੰਘ', 'ਹਰਪ੍ਰੀਤ'), isTrue);
    });
  });
}
