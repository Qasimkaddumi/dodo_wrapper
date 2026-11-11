import 'checkout_enums.dart';

/// Client-side presentation options of a checkout. Anything left `null` uses
/// the checkout SDK's default.
///
/// Colours and themes are not set here: they belong to the checkout session
/// your backend creates (`customization.theme_config`).
class CheckoutSettings {
  /// Creates checkout settings.
  const CheckoutSettings({
    this.showTimer,
    this.showSecurityBadge,
    this.manualRedirect,
    this.payButtonText,
    this.fontSize,
    this.fontWeight,
  });

  /// Whether to show the session timer. When `false`, a
  /// `CheckoutLinkExpired` event is emitted when the session expires.
  final bool? showTimer;

  /// Whether to show the security badge.
  final bool? showSecurityBadge;

  /// When `true`, the SDK does not navigate by itself. It emits
  /// `CheckoutStatusChanged` and `CheckoutRedirectRequested` instead, and the
  /// app handles navigation. By default a completed checkout navigates the
  /// whole page to the session's `return_url`, which restarts a Flutter app.
  final bool? manualRedirect;

  /// Custom label of the pay button.
  final String? payButtonText;

  /// Global font size.
  final CheckoutFontSize? fontSize;

  /// Global font weight.
  final CheckoutFontWeight? fontWeight;
}
