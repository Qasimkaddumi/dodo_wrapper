import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// An amount of money in a currency's smallest unit, as Dodo reports it.
///
/// Not every currency has two decimals, so never divide by 100 blindly:
///
/// ```dart
/// const DodoAmount(minorUnits: 1999, currency: 'USD').toDecimalString(); // 19.99
/// const DodoAmount(minorUnits: 1999, currency: 'JPY').toDecimalString(); // 1999
/// ```
@immutable
class DodoAmount {
  /// Creates an amount of [minorUnits] in the ISO 4217 [currency].
  const DodoAmount({required this.minorUnits, required this.currency});

  static const Set<String> _zeroDecimalCurrencies = {
    'BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF', 'KRW', 'MGA', //
    'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
  };

  static const Set<String> _threeDecimalCurrencies = {
    'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND', //
  };

  /// The amount in the currency's smallest unit, for example cents.
  final int minorUnits;

  /// ISO 4217 currency code, for example `USD`.
  final String currency;

  /// How many decimal places [currency] uses.
  int get decimalPlaces {
    final code = currency.toUpperCase();
    if (_zeroDecimalCurrencies.contains(code)) return 0;
    if (_threeDecimalCurrencies.contains(code)) return 3;
    return 2;
  }

  /// The amount in major units, for example dollars. For display arithmetic
  /// only; use [minorUnits] when exact values matter.
  double get majorUnits => minorUnits / math.pow(10, decimalPlaces);

  /// The exact amount in major units, for example `19.99`, with no rounding.
  String toDecimalString() {
    final places = decimalPlaces;
    if (places == 0) return minorUnits.toString();
    final digits = minorUnits.abs().toString().padLeft(places + 1, '0');
    final split = digits.length - places;
    final sign = minorUnits < 0 ? '-' : '';
    return '$sign${digits.substring(0, split)}.${digits.substring(split)}';
  }

  @override
  bool operator ==(Object other) =>
      other is DodoAmount &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${toDecimalString()} $currency';
}
