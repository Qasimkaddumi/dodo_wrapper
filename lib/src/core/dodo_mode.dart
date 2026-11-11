/// The Dodo Payments environment a checkout runs in.
enum DodoMode {
  /// Test mode: no real money moves.
  test('test', 'test.checkout.dodopayments.com'),

  /// Live mode: real payments.
  live('live', 'checkout.dodopayments.com');

  const DodoMode(this.value, this.checkoutHost);

  /// The value the checkout SDK expects for its `mode` option.
  final String value;

  /// Host that serves checkout pages in this mode.
  final String checkoutHost;

  /// Returns the mode whose checkout pages are served from [host], or `null`
  /// when [host] is not a Dodo checkout host.
  static DodoMode? fromCheckoutHost(String host) {
    for (final mode in values) {
      if (mode.checkoutHost == host) return mode;
    }
    return null;
  }
}
