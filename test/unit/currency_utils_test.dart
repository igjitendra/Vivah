import 'package:flutter_test/flutter_test.dart';
import 'package:vyavahaar/src/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils (Integer Paise Architecture)', () {
    test('rupeesToPaise accurately converts ₹1,100 to 110,000 paise', () {
      expect(CurrencyUtils.rupeesToPaise(1100), 110000);
    });

    test('paiseToRupees accurately converts 110,000 paise to ₹1,100', () {
      expect(CurrencyUtils.paiseToRupees(110000), 1100.0);
    });

    test('formatPaise produces correct Indian formatted string with ₹ symbol', () {
      expect(CurrencyUtils.formatPaise(110000), '₹1,100');
      expect(CurrencyUtils.formatPaise(0), '₹0');
      expect(CurrencyUtils.formatPaise(5100000), '₹51,000');
    });

    test('parseInputToPaise parses user input strings', () {
      expect(CurrencyUtils.parseInputToPaise('₹1,100'), 110000);
      expect(CurrencyUtils.parseInputToPaise('500'), 50000);
      expect(CurrencyUtils.parseInputToPaise(''), isNull);
    });
  });
}
