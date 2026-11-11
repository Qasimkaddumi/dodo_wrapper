import '../../../core/dodo_amount.dart';
import '../../../core/json.dart';
import '../domain/entities/checkout_breakdown.dart';
import '../domain/entities/checkout_event.dart';

/// Parses a raw SDK event (`{event_type, data}`).
///
/// Never throws: unknown types become [CheckoutUnknownEvent] and malformed
/// fields become `null`. The SDK's payloads are largely undocumented and
/// appear either directly in `data` or nested in `data.message`, so readers
/// accept both.
CheckoutEvent checkoutEventFromJson(JsonMap json) {
  final type = json.stringOrNull('event_type') ?? '';
  final data = json.mapOrNull('data') ?? const <String, dynamic>{};
  return switch (type) {
    'checkout.opened' => CheckoutOpened(raw: json),
    'checkout.form_ready' => CheckoutFormReady(raw: json),
    'checkout.payment_page_opened' => CheckoutPaymentPageOpened(raw: json),
    'checkout.customer_details_submitted' => CheckoutCustomerDetailsSubmitted(
      raw: json,
    ),
    'checkout.pay_button_clicked' => CheckoutPayButtonClicked(raw: json),
    'checkout.breakdown' => CheckoutBreakdownChanged(
      raw: json,
      breakdown: _breakdown(_payload(data)),
    ),
    'checkout.redirect' => CheckoutRedirecting(
      raw: json,
      redirectUrl: _redirectUrl(_payload(data)),
    ),
    'checkout.status' => CheckoutStatusChanged(
      raw: json,
      status: _payload(data).stringOrNull('status'),
    ),
    'checkout.redirect_requested' => CheckoutRedirectRequested(
      raw: json,
      redirectUrl: _redirectUrl(_payload(data)),
    ),
    'checkout.link_expired' => CheckoutLinkExpired(raw: json),
    'checkout.closed' => CheckoutClosed(
      raw: json,
      message: data.stringOrNull('message'),
    ),
    'checkout.error' => CheckoutFailed(
      raw: json,
      message: data.stringOrNull('message'),
    ),
    _ => CheckoutUnknownEvent(type: type, raw: json),
  };
}

/// Returns `data.message` when it is an object, otherwise `data` itself.
JsonMap _payload(JsonMap data) => data.mapOrNull('message') ?? data;

Uri? _redirectUrl(JsonMap payload) {
  final value =
      payload.stringOrNull('redirect_to') ??
      payload.stringOrNull('redirect_url') ??
      payload.stringOrNull('url');
  return value == null ? null : Uri.tryParse(value);
}

CheckoutBreakdown _breakdown(JsonMap payload) {
  final currency = payload.stringOrNull('currency');
  final finalCurrency = payload.stringOrNull('finalTotalCurrency') ?? currency;

  DodoAmount? amount(String key, String? code) {
    final minorUnits = payload.intOrNull(key);
    if (minorUnits == null || code == null) return null;
    return DodoAmount(minorUnits: minorUnits, currency: code);
  }

  return CheckoutBreakdown(
    subTotal: amount('subTotal', currency),
    discount: amount('discount', currency),
    tax: amount('tax', currency),
    total: amount('total', currency),
    finalTotal: amount('finalTotal', finalCurrency),
  );
}
