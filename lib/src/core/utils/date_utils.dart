import 'package:intl/intl.dart';

/// Date utility for Hindi Devanagari calendar formatting
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

  /// Returns today's date formatted as YYYY-MM-DD
  static String getTodayIsoString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Formats date string into authentic Hindi date string, e.g. "22 नवंबर 2026"
  static String formatHindiDate(dynamic dateInput) {
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
    final String monthName = hindiMonths[date.month - 1];
    final int year = date.year;

    return '$day $monthName $year';
  }

  /// Formats date string into readable date string
  static String formatIsoDate(dynamic dateInput) => formatHindiDate(dateInput);
}

/// Compatibility alias for screens referencing VyavahaarDateUtils
typedef VyavahaarDateUtils = AppDateUtils;
