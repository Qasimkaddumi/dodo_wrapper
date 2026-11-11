import '../../../../core/json.dart';
import 'checkout_breakdown.dart';

/// An event emitted by a checkout.
///
/// Events are UI hints and can be missed if the page closes. Only your
/// backend, through verified webhooks, should decide a payment succeeded.
///
/// Dodo adds events over time and unrecognised ones arrive as
/// [CheckoutUnknownEvent]. New subclasses will be added in minor releases,
/// so this type is deliberately not `sealed`: a `switch` over it needs a
/// default case, which keeps your code compiling when a type is added.
abstract base class CheckoutEvent {
  /// Creates an event of [type].
  const CheckoutEvent({required this.type, required this.raw});

  /// The event type exactly as the SDK sent it, e.g. `checkout.opened`.
  final String type;

  /// The event as received from the SDK.
  final JsonMap raw;

  @override
  // Not runtimeType: release web builds minify it.
  String toString() => 'CheckoutEvent($type)';
}

/// The checkout frame loaded. Useful for skeleton states.
final class CheckoutOpened extends CheckoutEvent {
  /// Creates the event.
  const CheckoutOpened({required super.raw}) : super(type: 'checkout.opened');
}

/// The checkout form is ready for input. Hide loading states here.
final class CheckoutFormReady extends CheckoutEvent {
  /// Creates the event.
  const CheckoutFormReady({required super.raw})
    : super(type: 'checkout.form_ready');
}

/// The payment page is displayed.
final class CheckoutPaymentPageOpened extends CheckoutEvent {
  /// Creates the event.
  const CheckoutPaymentPageOpened({required super.raw})
    : super(type: 'checkout.payment_page_opened');
}

/// The customer submitted their customer and billing details.
final class CheckoutCustomerDetailsSubmitted extends CheckoutEvent {
  /// Creates the event.
  const CheckoutCustomerDetailsSubmitted({required super.raw})
    : super(type: 'checkout.customer_details_submitted');
}

/// The customer clicked the pay button.
final class CheckoutPayButtonClicked extends CheckoutEvent {
  /// Creates the event.
  const CheckoutPayButtonClicked({required super.raw})
    : super(type: 'checkout.pay_button_clicked');
}

/// Prices, tax or discounts changed.
final class CheckoutBreakdownChanged extends CheckoutEvent {
  /// Creates the event.
  const CheckoutBreakdownChanged({required this.breakdown, required super.raw})
    : super(type: 'checkout.breakdown');

  /// The current prices.
  final CheckoutBreakdown breakdown;
}

/// The checkout is about to navigate, for example to a bank page.
final class CheckoutRedirecting extends CheckoutEvent {
  /// Creates the event.
  const CheckoutRedirecting({required super.raw, this.redirectUrl})
    : super(type: 'checkout.redirect');

  /// Where the checkout is navigating to, when provided.
  final Uri? redirectUrl;
}

/// The payment outcome, reported when `manualRedirect` is enabled.
///
/// The SDK does not document this payload, so [status] is `null` when it
/// cannot be found. [CheckoutEvent.raw] always has the full event.
final class CheckoutStatusChanged extends CheckoutEvent {
  /// Creates the event.
  const CheckoutStatusChanged({required super.raw, this.status})
    : super(type: 'checkout.status');

  /// The reported status, for example `succeeded`.
  final String? status;
}

/// The app should navigate, reported when `manualRedirect` is enabled.
///
/// The SDK does not document this payload, so [redirectUrl] is `null` when
/// it cannot be found. [CheckoutEvent.raw] always has the full event.
final class CheckoutRedirectRequested extends CheckoutEvent {
  /// Creates the event.
  const CheckoutRedirectRequested({required super.raw, this.redirectUrl})
    : super(type: 'checkout.redirect_requested');

  /// The URL to open.
  final Uri? redirectUrl;
}

/// The session expired. Only emitted when `showTimer` is `false`.
final class CheckoutLinkExpired extends CheckoutEvent {
  /// Creates the event.
  const CheckoutLinkExpired({required super.raw})
    : super(type: 'checkout.link_expired');
}

/// The checkout closed. Also emitted when the package closes an open
/// checkout to replace it with a new one.
final class CheckoutClosed extends CheckoutEvent {
  /// Creates the event.
  const CheckoutClosed({required super.raw, this.message})
    : super(type: 'checkout.closed');

  /// Reason given by the SDK, when provided.
  final String? message;
}

/// An error occurred in the checkout.
final class CheckoutFailed extends CheckoutEvent {
  /// Creates the event.
  const CheckoutFailed({required super.raw, this.message})
    : super(type: 'checkout.error');

  /// Error description, when provided.
  final String? message;
}

/// An event this package has no type for. [CheckoutEvent.raw] has its data.
final class CheckoutUnknownEvent extends CheckoutEvent {
  /// Creates the event.
  const CheckoutUnknownEvent({required super.type, required super.raw});
}
