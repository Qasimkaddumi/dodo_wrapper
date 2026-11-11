/// How a checkout is presented.
enum CheckoutDisplayType {
  /// A modal above the page.
  overlay('overlay'),

  /// Embedded in an element of the page.
  inline('inline');

  const CheckoutDisplayType(this.value);

  /// The value the checkout SDK expects.
  final String value;
}

/// Global font size of the checkout.
enum CheckoutFontSize {
  /// Extra small.
  xs('xs'),

  /// Small.
  sm('sm'),

  /// Medium.
  md('md'),

  /// Large.
  lg('lg'),

  /// Extra large.
  xl('xl'),

  /// Twice extra large.
  xxl('2xl');

  const CheckoutFontSize(this.value);

  /// The value the checkout SDK expects.
  final String value;
}

/// Global font weight of the checkout.
enum CheckoutFontWeight {
  /// Normal.
  normal('normal'),

  /// Medium.
  medium('medium'),

  /// Bold.
  bold('bold'),

  /// Extra bold.
  extraBold('extraBold');

  const CheckoutFontWeight(this.value);

  /// The value the checkout SDK expects.
  final String value;
}
