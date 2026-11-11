import 'entities/checkout_event.dart';
import 'entities/checkout_options.dart';

/// Opens and closes Dodo checkouts and exposes their events.
abstract interface class CheckoutService {
  /// Every checkout event (broadcast stream without replay). Subscribe
  /// before opening a checkout so that no event is missed.
  Stream<CheckoutEvent> get events;

  /// Whether a checkout is currently open.
  bool get isOpen;

  /// The options of the checkout that is currently open, or `null` when none
  /// is. Compare with `identical` to tell whether a given checkout is still
  /// the open one.
  CheckoutOptions? get currentOptions;

  /// Opens a checkout, closing any checkout that is already open.
  ///
  /// Fails with `DodoValidationException` before calling the SDK when the
  /// options or URL are invalid, and with `DodoJsException` when the SDK
  /// rejects them.
  Future<void> open(CheckoutOptions options);

  /// Closes the open checkout. Does nothing when none is open.
  void close();
}
