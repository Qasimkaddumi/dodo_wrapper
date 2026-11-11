import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DodoAmount amount(int minorUnits, String currency) =>
      DodoAmount(minorUnits: minorUnits, currency: currency);

  test('uses each currency\'s decimal places', () {
    expect(amount(1999, 'USD').toDecimalString(), '19.99');
    expect(amount(1999, 'JPY').toDecimalString(), '1999');
    expect(amount(1999, 'KWD').toDecimalString(), '1.999');
  });

  test('matches currency codes case-insensitively', () {
    expect(amount(500, 'jpy').decimalPlaces, 0);
  });

  test('pads small and negative amounts without rounding', () {
    expect(amount(5, 'USD').toDecimalString(), '0.05');
    expect(amount(0, 'USD').toDecimalString(), '0.00');
    expect(amount(-250, 'EUR').toDecimalString(), '-2.50');
    expect(amount(7, 'BHD').toDecimalString(), '0.007');
  });

  test('converts to major units', () {
    expect(amount(1250, 'USD').majorUnits, 12.5);
    expect(amount(1250, 'KRW').majorUnits, 1250);
  });

  test('has value equality', () {
    expect(amount(100, 'USD'), amount(100, 'USD'));
    expect(amount(100, 'USD').hashCode, amount(100, 'USD').hashCode);
    expect(amount(100, 'USD'), isNot(amount(100, 'EUR')));
  });
}
