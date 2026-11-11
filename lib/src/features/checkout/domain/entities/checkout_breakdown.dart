import '../../../../core/dodo_amount.dart';

/// The prices shown by a checkout. Tax is only known once the customer has
/// entered a valid address, so any amount can be `null` early on.
class CheckoutBreakdown {
  /// Creates a breakdown.
  const CheckoutBreakdown({
    this.subTotal,
    this.discount,
    this.tax,
    this.total,
    this.finalTotal,
  });

  /// Price before discount and tax.
  final DodoAmount? subTotal;

  /// Discount applied.
  final DodoAmount? discount;

  /// Tax applied.
  final DodoAmount? tax;

  /// `subTotal - discount + tax`, in the base currency.
  final DodoAmount? total;

  /// The amount actually charged. Can be in a different currency from the
  /// other amounts, and is the one to show as the price the customer pays.
  final DodoAmount? finalTotal;
}
