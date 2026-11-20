import 'package:intl/intl.dart';

/// Financial utility enforcing INTEGER PAISE currency representation.
/// ₹1.00 = 100 paise.
/// ₹1,100.00 = 110000 paise.
/// Never use floating point numbers for currency calculations or persistence.
class CurrencyUtils {
  CurrencyUtils._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Converts rupees (double or int) to integer paise without floating point inaccuracy
  static int rupeesToPaise(num rupees) {
    return (rupees * 100).round();
  }

  /// Converts integer paise to double rupees for presentation only
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }

  /// Formats integer paise into standard Indian Rupee string, e.g. 110000 -> "₹1,100"
  static String formatPaise(int paise) {
    final double rupees = paiseToRupees(paise);
    return _formatter.format(rupees);
  }

  /// Parses user text input string into integer paise
  static int? parseInputToPaise(String input) {
    final String clean = input.replaceAll('₹', '').replaceAll(',', '').trim();
    if (clean.isEmpty) return null;
    final double? rupees = double.tryParse(clean);
    if (rupees == null || rupees < 0) return null;
    return rupeesToPaise(rupees);
  }
}
