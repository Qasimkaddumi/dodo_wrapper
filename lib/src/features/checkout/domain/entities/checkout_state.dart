import 'checkout_breakdown.dart';
import 'checkout_event.dart';

/// Coarse lifecycle of a checkout, derived from its events.
enum CheckoutPhase {
  /// No checkout event received yet.
  idle,

  /// The checkout frame opened and the form is still loading.
  loading,

  /// The form is ready for the customer.
  ready,

  /// The customer clicked pay.
  processingPayment,

  /// The checkout is navigating, for example to a bank page.
  redirecting,

  /// The session expired.
  expired,

  /// The checkout was closed.
  closed,
}

/// Snapshot of a checkout built from its event stream.
///
/// Use it to render your own order summary next to an inline checkout. It is
/// a UI hint: only your backend can confirm that a payment succeeded.
class CheckoutState {
  /// Creates a state.
  const CheckoutState({
    this.phase = CheckoutPhase.idle,
    this.breakdown,
    this.status,
    this.errorMessage,
    this.lastEvent,
  });

  /// Current lifecycle phase.
  final CheckoutPhase phase;

  /// Latest prices, if any were reported.
  final CheckoutBreakdown? breakdown;

  /// Latest payment status reported with `manualRedirect`, if any.
  final String? status;

  /// Latest error message. Cleared when the customer can try again.
  final String? errorMessage;

  /// The most recent event.
  final CheckoutEvent? lastEvent;

  /// Returns the state after [event].
  CheckoutState apply(CheckoutEvent event) => switch (event) {
    // A new checkout starts from a clean slate.
    CheckoutOpened() => CheckoutState(
      phase: CheckoutPhase.loading,
      lastEvent: event,
    ),
    CheckoutFormReady() => _copy(
      event,
      phase: CheckoutPhase.ready,
      clearError: true,
    ),
    CheckoutPayButtonClicked() => _copy(
      event,
      phase: CheckoutPhase.processingPayment,
      clearError: true,
    ),
    CheckoutBreakdownChanged(:final breakdown) => _copy(
      event,
      breakdown: breakdown,
    ),
    CheckoutStatusChanged(:final status) => _copy(event, status: status),
    CheckoutRedirecting() || CheckoutRedirectRequested() => _copy(
      event,
      phase: CheckoutPhase.redirecting,
    ),
    CheckoutLinkExpired() => _copy(event, phase: CheckoutPhase.expired),
    CheckoutClosed() => _copy(event, phase: CheckoutPhase.closed),
    CheckoutFailed(:final message) => CheckoutState(
      // A failed payment returns the customer to the form.
      phase: phase == CheckoutPhase.processingPayment
          ? CheckoutPhase.ready
          : phase,
      breakdown: breakdown,
      status: status,
      errorMessage: message,
      lastEvent: event,
    ),
    _ => _copy(event),
  };

  CheckoutState _copy(
    CheckoutEvent event, {
    CheckoutPhase? phase,
    CheckoutBreakdown? breakdown,
    String? status,
    bool clearError = false,
  }) => CheckoutState(
    phase: phase ?? this.phase,
    breakdown: breakdown ?? this.breakdown,
    status: status ?? this.status,
    errorMessage: clearError ? null : errorMessage,
    lastEvent: event,
  );
}
