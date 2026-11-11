import 'dart:async';

import '../../../core/dodo_exception.dart';
import '../../../core/dodo_mode.dart';
import '../../../core/json.dart';
import '../../../core/platform/dodo_checkout_bridge.dart';
import '../domain/checkout_service.dart';
import '../domain/entities/checkout_enums.dart';
import '../domain/entities/checkout_event.dart';
import '../domain/entities/checkout_options.dart';
import 'checkout_event_mapper.dart';
import 'checkout_options_mapper.dart';

/// [CheckoutService] backed by the checkout SDK through a
/// [DodoCheckoutBridge].
class DodoCheckoutService implements CheckoutService {
  /// Creates the service. Call [initialize] before opening a checkout.
  DodoCheckoutService({
    required DodoCheckoutBridge bridge,
    required DodoMode mode,
  }) : _bridge = bridge,
       _mode = mode;

  final DodoCheckoutBridge _bridge;
  final DodoMode _mode;
  final StreamController<CheckoutEvent> _events =
      StreamController<CheckoutEvent>.broadcast();

  /// The display type the SDK is currently initialized with.
  CheckoutDisplayType? _displayType;

  /// The options passed to the last successful [open].
  CheckoutOptions? _current;

  /// Whether a call to the SDK's synchronous `open` is in progress.
  bool _isOpening = false;

  /// `checkout.error` received during `open`, held until `open` returns.
  CheckoutFailed? _heldFailure;

  @override
  Stream<CheckoutEvent> get events => _events.stream;

  @override
  bool get isOpen => _bridge.isOpen;

  @override
  CheckoutOptions? get currentOptions => _bridge.isOpen ? _current : null;

  /// Initializes the SDK for overlays, its default display type.
  void initialize() => _useDisplayType(CheckoutDisplayType.overlay);

  @override
  Future<void> open(CheckoutOptions options) async {
    options.validate();
    _validateUrl(options.checkoutUrl);

    // Reusing an open frame, or re-initializing under one, leaves the SDK
    // showing the previous checkout.
    close();
    _useDisplayType(options.displayType);
    _openOnce(checkoutOptionsToJson(options));
    _current = options;
  }

  @override
  void close() {
    if (_bridge.isOpen) _bridge.close();
  }

  /// Releases the event stream.
  Future<void> dispose() => _events.close();

  /// The SDK accepts `http` URLs and URLs from the other mode, so both are
  /// rejected here. The SDK validates the URL's path itself.
  void _validateUrl(Uri url) {
    if (url.scheme != 'https') {
      throw DodoValidationException('checkoutUrl must use https: $url');
    }
    final urlMode = DodoMode.fromCheckoutHost(url.host);
    if (urlMode == null) {
      throw DodoValidationException(
        'checkoutUrl is not a Dodo checkout URL: $url',
      );
    }
    if (urlMode != _mode) {
      throw DodoValidationException(
        'A ${urlMode.value} mode checkoutUrl cannot be opened in '
        '${_mode.value} mode.',
      );
    }
    // The SDK rejects these too, but with a message about URL formats.
    if (url.pathSegments.isNotEmpty && url.pathSegments.first == 'buy') {
      throw DodoValidationException(
        'Static payment links (/buy/...) cannot be opened as an overlay or '
        'inline. Redirect the browser to the link, or create a checkout '
        'session: $url',
      );
    }
  }

  /// Initializing again is only needed when the display type changes.
  void _useDisplayType(CheckoutDisplayType displayType) {
    if (_displayType == displayType) return;
    _bridge.initialize(
      initializeOptionsToJson(_mode, displayType),
      _handleRawEvent,
    );
    _displayType = displayType;
  }

  /// Calls the SDK so that a rejected open is reported once. The SDK both
  /// throws and emits `checkout.error` for some failures, so an error seen
  /// during the call is only published if the call did not throw.
  void _openOnce(JsonMap options) {
    _heldFailure = null;
    _isOpening = true;
    try {
      _bridge.open(options);
    } finally {
      _isOpening = false;
    }
    final failure = _heldFailure;
    if (failure != null) _events.add(failure);
  }

  void _handleRawEvent(JsonMap raw) {
    if (_events.isClosed) return;
    final event = checkoutEventFromJson(raw);
    if (_isOpening && event is CheckoutFailed) {
      _heldFailure = event;
      return;
    }
    _events.add(event);
  }
}
