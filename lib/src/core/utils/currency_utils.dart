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

  /// Formats integer paise into standard Indian Rupee string (alias for formatPaise)
  static String formatPaiseToRupees(int paise) => formatPaise(paise);

  /// Converts rupee integer amount into traditional Indian Words format
  /// e.g. 1100 -> "ग्यारह सौ रुपये मात्र" / "One Thousand One Hundred Rupees Only"
  static String formatRupeesInWords(int rupees, {String lang = 'hi'}) {
    if (rupees <= 0) return '';
    if (lang == 'en') {
      return '${_numToWordsEn(rupees)} Rupees Only';
    } else {
      return '${_numToWordsHi(rupees)} रुपये मात्र';
    }
  }

  static String _numToWordsHi(int n) {
    if (n == 0) return 'शून्य';
    const ones = {
      1: 'एक', 2: 'दो', 3: 'तीन', 4: 'चार', 5: 'पाँच',
      6: 'छह', 7: 'सात', 8: 'आठ', 9: 'नौ', 10: 'दस',
      11: 'ग्यारह', 12: 'बारह', 13: 'तेरह', 14: 'चौदह', 15: 'पंद्रह',
      16: 'सोलह', 17: 'सत्रह', 18: 'अठारह', 19: 'उन्नीस', 20: 'बीस',
      21: 'इक्कीस', 25: 'पच्चीस', 51: 'इक्यावन', 101: 'एक सौ एक',
      251: 'दो सौ इक्यावन', 501: 'पाँच सौ एक', 1100: 'ग्यारह सौ',
      2100: 'इक्कीस सौ', 3100: 'इकतीस सौ', 5100: 'इक्यावन सौ',
      11000: 'ग्यारह हज़ार', 21000: 'इक्कीस हज़ार', 51000: 'इक्यावन हज़ार',
    };
    if (ones.containsKey(n)) return ones[n]!;

    String result = '';
    if (n >= 10000000) {
      result += '${_numToWordsHi(n ~/ 10000000)} करोड़ ';
      n %= 10000000;
    }
    if (n >= 100000) {
      result += '${_numToWordsHi(n ~/ 100000)} लाख ';
      n %= 100000;
    }
    if (n >= 1000) {
      if (n % 100 == 0 && n < 10000) {
        result += '${_numToWordsHi(n ~/ 100)} सौ ';
        return result.trim();
      }
      result += '${_numToWordsHi(n ~/ 1000)} हज़ार ';
      n %= 1000;
    }
    if (n >= 100) {
      result += '${_numToWordsHi(n ~/ 100)} सौ ';
      n %= 100;
    }
    if (n > 0) {
      if (ones.containsKey(n)) {
        result += ones[n]!;
      } else {
        result += n.toString();
      }
    }
    return result.trim();
  }

  static String _numToWordsEn(int n) {
    if (n == 0) return 'Zero';
    const ones = {
      1: 'One', 2: 'Two', 3: 'Three', 4: 'Four', 5: 'Five',
      6: 'Six', 7: 'Seven', 8: 'Eight', 9: 'Nine', 10: 'Ten',
      11: 'Eleven', 12: 'Twelve', 13: 'Thirteen', 14: 'Fourteen', 15: 'Fifteen',
      16: 'Sixteen', 17: 'Seventeen', 18: 'Eighteen', 19: 'Nineteen', 20: 'Twenty',
      30: 'Thirty', 40: 'Forty', 50: 'Fifty', 60: 'Sixty', 70: 'Seventy', 80: 'Eighty', 90: 'Ninety',
    };
    if (ones.containsKey(n)) return ones[n]!;

    String result = '';
    if (n >= 10000000) {
      result += '${_numToWordsEn(n ~/ 10000000)} Crore ';
      n %= 10000000;
    }
    if (n >= 100000) {
      result += '${_numToWordsEn(n ~/ 100000)} Lakh ';
      n %= 100000;
    }
    if (n >= 1000) {
      result += '${_numToWordsEn(n ~/ 1000)} Thousand ';
      n %= 1000;
    }
    if (n >= 100) {
      result += '${_numToWordsEn(n ~/ 100)} Hundred ';
      n %= 100;
    }
    if (n > 0) {
      if (ones.containsKey(n)) {
        result += ones[n]!;
      } else if (n < 100) {
        final tens = (n ~/ 10) * 10;
        final rem = n % 10;
        result += '${ones[tens]} ${ones[rem]}';
      } else {
        result += n.toString();
      }
    }
    return result.trim();
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
