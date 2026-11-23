import 'package:intl/intl.dart';

/// Date utility for multilingual calendar formatting (Hindi, English, Urdu)
/// with full live relative date tracking and reactive today-awareness.
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

  static const List<String> hindiWeekdays = [
    'सोमवार',
    'मंगलवार',
    'बुधवार',
    'गुरुवार',
    'शुक्रवार',
    'शनिवार',
    'रविवार'
  ];

  static const List<String> englishWeekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  /// Returns today's date formatted as YYYY-MM-DD in local time
  static String getTodayIsoString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Converts DateTime to ISO string YYYY-MM-DD
  static String toIsoDateString(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// Parses date input safely into a DateTime in local timezone
  static DateTime? parseToLocalDate(dynamic dateInput) {
    if (dateInput == null) return null;
    if (dateInput is DateTime) return dateInput.toLocal();
    if (dateInput is String) {
      try {
        final parsed = DateTime.parse(dateInput);
        return parsed.toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Checks if given date input matches today's local calendar day
  static bool isToday(dynamic dateInput) {
    final dt = parseToLocalDate(dateInput);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Checks if given date input matches yesterday's local calendar day
  static bool isYesterday(dynamic dateInput) {
    final dt = parseToLocalDate(dateInput);
    if (dt == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  }

  /// Returns live localized header date string with weekday, e.g. "आज • 24 नवंबर, मंगलवार"
  static String getLiveTodayHeaderString([String? localeCode]) {
    final now = DateTime.now();
    final day = now.day;
    final monthIdx = now.month - 1;
    final weekdayIdx = now.weekday - 1; // 1 = Monday, 7 = Sunday

    if (localeCode == 'en') {
      final weekday = englishWeekdays[weekdayIdx];
      final month = englishMonths[monthIdx];
      return 'Today • $day $month, $weekday';
    } else if (localeCode == 'ur') {
      final month = urduMonths[monthIdx];
      return 'آج • $day $month';
    }

    final weekday = hindiWeekdays[weekdayIdx];
    final month = hindiMonths[monthIdx];
    return 'आज • $day $month, $weekday';
  }

  /// Formats date string into authentic localized date string
  static String formatLocalizedDate(dynamic dateInput, [String? localeCode]) {
    if (dateInput == null) return '';
    DateTime date;
    if (dateInput is DateTime) {
      date = dateInput.toLocal();
    } else if (dateInput is String) {
      try {
        date = DateTime.parse(dateInput).toLocal();
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

  /// Formats date relative to today: "आज", "कल", or "24 नवंबर 2026"
  static String formatRelativeDate(dynamic dateInput, [String? localeCode]) {
    if (isToday(dateInput)) {
      if (localeCode == 'en') return 'Today';
      if (localeCode == 'ur') return 'آج';
      return 'आज';
    }
    if (isYesterday(dateInput)) {
      if (localeCode == 'en') return 'Yesterday';
      if (localeCode == 'ur') return 'कल';
      return 'कल';
    }
    return formatLocalizedDate(dateInput, localeCode);
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
