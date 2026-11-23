import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('formats ISO date string into Devanagari Hindi date', () {
      final formatted = AppDateUtils.formatHindiDate('2026-11-22');
      expect(formatted, equals('22 नवंबर 2026'));
    });

    test('formats DateTime instance into Hindi date', () {
      final dt = DateTime(2026, 2, 18);
      final formatted = AppDateUtils.formatHindiDate(dt);
      expect(formatted, equals('18 फ़रवरी 2026'));
    });

    test('correctly maps all 12 Hindi month names', () {
      final expectedMonths = [
        '15 जनवरी 2026',
        '15 फ़रवरी 2026',
        '15 मार्च 2026',
        '15 अप्रैल 2026',
        '15 मई 2026',
        '15 जून 2026',
        '15 जुलाई 2026',
        '15 अगस्त 2026',
        '15 सितंबर 2026',
        '15 अक्टूबर 2026',
        '15 नवंबर 2026',
        '15 दिसंबर 2026',
      ];

      for (int m = 1; m <= 12; m++) {
        final dt = DateTime(2026, m, 15);
        expect(AppDateUtils.formatHindiDate(dt), equals(expectedMonths[m - 1]));
      }
    });

    test('handles null safely', () {
      expect(AppDateUtils.formatHindiDate(null), equals(''));
    });

    test('handles invalid string safely without throwing', () {
      expect(AppDateUtils.formatHindiDate('not-a-date'), equals('not-a-date'));
    });

    test('getTodayIsoString returns valid YYYY-MM-DD pattern', () {
      final today = AppDateUtils.getTodayIsoString();
      final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      expect(regex.hasMatch(today), isTrue);
    });

    test('isToday correctly identifies today', () {
      final now = DateTime.now();
      expect(AppDateUtils.isToday(now), isTrue);
      expect(AppDateUtils.isToday(AppDateUtils.getTodayIsoString()), isTrue);
      expect(AppDateUtils.isToday(now.subtract(const Duration(days: 1))), isFalse);
    });

    test('isYesterday correctly identifies yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(AppDateUtils.isYesterday(yesterday), isTrue);
      expect(AppDateUtils.isYesterday(DateTime.now()), isFalse);
    });

    test('formatRelativeDate returns authentic localized labels', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      expect(AppDateUtils.formatRelativeDate(today, 'hi'), equals('आज'));
      expect(AppDateUtils.formatRelativeDate(yesterday, 'hi'), equals('कल'));
      expect(AppDateUtils.formatRelativeDate(today, 'en'), equals('Today'));
      expect(AppDateUtils.formatRelativeDate(yesterday, 'en'), equals('Yesterday'));
    });
  });
}
