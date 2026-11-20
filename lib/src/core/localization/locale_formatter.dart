import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware formatter for Indian currency, numbers, and dates.
/// Strictly separates integer paise storage from display presentation.
class LocaleFormatter {
  LocaleFormatter._();

  /// Format an integer paise value into localized Indian Rupee currency (e.g. ₹1,100)
  /// Always uses exact integer arithmetic for paise -> rupees conversion.
  static String formatPaise(int paise, [Locale? locale]) {
    final double rupees = paise / 100.0;
    final String localeTag = locale?.toLanguageTag() ?? 'en-IN';

    try {
      final formatter = NumberFormat.currency(
        locale: localeTag,
        symbol: '₹',
        decimalDigits: (paise % 100 == 0) ? 0 : 2,
      );
      return formatter.format(rupees);
    } catch (_) {
      // Fallback format
      if (paise % 100 == 0) {
        return '₹${(paise ~/ 100)}';
      } else {
        return '₹${rupees.toStringAsFixed(2)}';
      }
    }
  }

  /// Format a localized integer count (e.g. 1,000)
  static String formatCount(int count, [Locale? locale]) {
    final String localeTag = locale?.toLanguageTag() ?? 'en-IN';
    try {
      final formatter = NumberFormat.decimalPattern(localeTag);
      return formatter.format(count);
    } catch (_) {
      return count.toString();
    }
  }

  /// Format an ISO date string (YYYY-MM-DD) or DateTime into localized date
  static String formatDate(dynamic dateInput, [Locale? locale]) {
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

    final String localeTag = locale?.languageCode ?? 'hi';
    try {
      final formatter = DateFormat('d MMMM yyyy', localeTag);
      return formatter.format(date);
    } catch (_) {
      // Fallback: Day Month Year
      return '${date.day}-${date.month}-${date.year}';
    }
  }

  /// Format short date (e.g. 22 Nov 2026)
  static String formatShortDate(dynamic dateInput, [Locale? locale]) {
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

    final String localeTag = locale?.languageCode ?? 'hi';
    try {
      final formatter = DateFormat('d MMM yyyy', localeTag);
      return formatter.format(date);
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
