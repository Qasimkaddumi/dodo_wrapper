import 'package:flutter/widgets.dart';

import '../../../core/platform/dodo_frame_host.dart';
import '../../../core/platform/dodo_platform.dart';
import '../../../dodo.dart';
import '../domain/checkout_service.dart';
import '../domain/entities/checkout_options.dart';
import '../domain/entities/checkout_settings.dart';

/// Builds the element that hosts the checkout, in place of `HtmlElementView`.
typedef DodoFrameHostBuilder =
    Widget Function(ValueChanged<Object> onElementCreated);

/// Embeds a Dodo checkout in the widget tree.
///
/// Give it a bounded height, for example
/// `SizedBox(height: 700, child: DodoInlineCheckout(...))`. Content taller
/// than that scrolls inside the widget. Dodo requires the whole frame,
/// including its legal footer, to stay reachable.
///
/// Changing [checkoutUrl] opens that session in place of the current one.
/// Other changes have no effect on an open checkout, because session URLs
/// are single-use and cannot be reopened with new settings.
class DodoInlineCheckout extends StatefulWidget {
  /// Creates an inline checkout for the session at [checkoutUrl].
  const DodoInlineCheckout({
    required this.checkoutUrl,
    this.settings,
    this.checkoutService,
    this.frameHost,
    this.onError,
    @visibleForTesting this.hostBuilder,
    super.key,
  });

  /// The `checkout_url` your backend received when it created the session.
  final Uri checkoutUrl;

  /// Client-side presentation options.
  final CheckoutSettings? settings;

  /// Service used to open the checkout. Defaults to `Dodo.instance.checkout`.
  final CheckoutService? checkoutService;

  /// Prepares the host element. Defaults to `DodoPlatform()`.
  final DodoFrameHost? frameHost;

  /// Called with errors from opening the checkout. When `null`, errors are
  /// reported with [FlutterError.reportError].
  final ValueChanged<Object>? onError;

  /// Replaces the `HtmlElementView`, which only exists on web. Tests only.
  final DodoFrameHostBuilder? hostBuilder;

  @override
  State<DodoInlineCheckout> createState() => _DodoInlineCheckoutState();
}

class _DodoInlineCheckoutState extends State<DodoInlineCheckout> {
  static int _nextId = 0;

  final String _elementId = 'dodo-inline-checkout-${_nextId++}';
  late final DodoFrameHost _frameHost;

  /// The checkout this widget opened most recently.
  CheckoutOptions? _opened;

  /// Incremented by each open, so that a superseded one can stop.
  int _attempt = 0;

  CheckoutService get _service =>
      widget.checkoutService ?? Dodo.instance.checkout;

  @override
  void initState() {
    super.initState();
    _frameHost = widget.frameHost ?? DodoPlatform();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(DodoInlineCheckout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkoutUrl != widget.checkoutUrl) _open();
  }

  @override
  void dispose() {
    _attempt++;
    _closeIfStillOurs();
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted) return;
    final attempt = ++_attempt;
    final options = CheckoutOptions(
      checkoutUrl: widget.checkoutUrl,
      elementId: _elementId,
      settings: widget.settings,
    );
    try {
      // A host that is not painted yet, such as in a hidden tab, is not in
      // the page. Wait for it rather than give up.
      final ready = await _frameHost.whenFrameHostReady(
        _elementId,
        isCancelled: () => !mounted || attempt != _attempt,
      );
      if (!ready || !mounted || attempt != _attempt) return;
      _opened = options;
      await _service.open(options);
    } on Object catch (error, stack) {
      if (mounted && attempt == _attempt) _report(error, stack);
    }
  }

  /// The SDK has one checkout per page. Another widget or an overlay may
  /// have replaced ours, and that one must stay open. Ours must be closed,
  /// though: removing its element leaves the SDK reporting it as open.
  void _closeIfStillOurs() {
    final opened = _opened;
    if (opened == null) return;
    try {
      if (identical(_service.currentOptions, opened)) _service.close();
    } on Object catch (error, stack) {
      _report(error, stack);
    }
  }

  void _report(Object error, StackTrace stack) {
    final onError = widget.onError;
    if (onError != null) {
      onError(error);
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'dodo_wrapper',
        context: ErrorDescription('while opening an inline Dodo checkout'),
      ),
    );
  }

  void _prepareHost(Object element) =>
      _frameHost.prepareFrameHost(element, elementId: _elementId);

  @override
  Widget build(BuildContext context) {
    final hostBuilder = widget.hostBuilder;
    if (hostBuilder != null) return hostBuilder(_prepareHost);
    return HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: _prepareHost,
    );
  }
}
