import 'package:intl/intl.dart';

/// Date utility for multilingual calendar formatting (Hindi, English, Urdu)
class AppDateUtils {
  AppDateUtils._();

  static const List<String> hindiMonths = [
    'जनवरी',
    'फ़रवरी',
    'मार्च',
    'अप्रैल',
    'मई',
    'जून',
    'जुलाई',
    'अगस्त',
    'सितंबर',
    'अक्टूबर',
    'नवंबर',
    'दिसंबर'
  ];

  static const List<String> englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static const List<String> urduMonths = [
    'جنوری',
    'فروری',
    'مارچ',
    'اپریل',
    'مئی',
    'جون',
    'جولائی',
    'اگست',
    'ستمبر',
    'اکتوبر',
    'نومبر',
    'دسمبر'
  ];

  /// Returns today's date formatted as YYYY-MM-DD
  static String getTodayIsoString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Formats date string into authentic localized date string
  static String formatLocalizedDate(dynamic dateInput, [String? localeCode]) {
    if (dateInput == null) return '';
    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput;
    } else if (dateInput is String) {
      try {
        date = DateTime.parse(dateInput);
      } catch (_) {
        return dateInput;
      }
    } else {
      return '';
    }

    final int day = date.day;
    final int monthIndex = date.month - 1;
    final int year = date.year;

    if (localeCode == 'en') {
      return '$day ${englishMonths[monthIndex]} $year';
    } else if (localeCode == 'ur') {
      return '$day ${urduMonths[monthIndex]} $year';
    }
    return '$day ${hindiMonths[monthIndex]} $year';
  }

  /// Formats date string into authentic Hindi date string, e.g. "22 नवंबर 2026"
  static String formatHindiDate(dynamic dateInput) {
    return formatLocalizedDate(dateInput, 'hi');
  }

  /// Formats date string into readable date string respecting locale
  static String formatIsoDate(dynamic dateInput, [String? localeCode]) =>
      formatLocalizedDate(dateInput, localeCode);
}

/// Compatibility alias for screens referencing VyavahaarDateUtils
typedef VyavahaarDateUtils = AppDateUtils;

