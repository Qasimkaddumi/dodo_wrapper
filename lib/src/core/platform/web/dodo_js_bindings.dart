// Minimal dart:js_interop bindings for the dodopayments-checkout global.
//
// Only the members this package uses are declared. The global is undefined
// until the script has loaded, so the getters are nullable.
import 'dart:js_interop';

/// `window.DodoPaymentsCheckout`, or `null` before the script has loaded.
@JS('DodoPaymentsCheckout')
external DodoPaymentsCheckoutJs? get dodoPaymentsCheckoutJs;

/// The UMD namespace exposed by the SDK script.
extension type DodoPaymentsCheckoutJs._(JSObject _) implements JSObject {
  /// `DodoPaymentsCheckout.DodoPayments`.
  @JS('DodoPayments')
  external DodoPaymentsJs? get dodoPayments;
}

/// The `DodoPayments` SDK object.
extension type DodoPaymentsJs._(JSObject _) implements JSObject {
  /// `DodoPayments.Checkout`.
  @JS('Checkout')
  external DodoCheckoutJs get checkout;

  /// `DodoPayments.Initialize(config)`.
  @JS('Initialize')
  external void initialize(JSAny config);
}

/// `DodoPayments.Checkout`.
extension type DodoCheckoutJs._(JSObject _) implements JSObject {
  /// `DodoPayments.Checkout.open(options)`.
  @JS('open')
  external void open(JSAny options);

  /// `DodoPayments.Checkout.close()`.
  @JS('close')
  external void close();

  /// `DodoPayments.Checkout.isOpen()`.
  @JS('isOpen')
  external bool isOpen();
}
