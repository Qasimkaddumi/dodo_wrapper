import '../json.dart';

/// Callback receiving a raw SDK event (`{event_type: ..., data: {...}}`).
typedef DodoEventHandler = void Function(JsonMap event);

/// Low-level calls into the Dodo checkout SDK.
///
/// It speaks plain JSON maps using the exact shapes the SDK expects, so the
/// feature layer owns all mapping between typed models and the wire format.
abstract interface class DodoCheckoutBridge {
  /// Whether a checkout is currently open, per `Checkout.isOpen()`.
  bool get isOpen;

  /// Calls `DodoPayments.Initialize()` with [options] and routes every
  /// checkout event to [onEvent]. May be called again to change the options.
  void initialize(JsonMap options, DodoEventHandler onEvent);

  /// Calls `DodoPayments.Checkout.open()`.
  void open(JsonMap options);

  /// Calls `DodoPayments.Checkout.close()`.
  void close();
}
