import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../dodo_exception.dart';
import '../../json.dart';
import '../dodo_checkout_bridge.dart';
import '../dodo_platform.dart';
import '../js_value_converter.dart';
import 'dodo_js_bindings.dart';

/// Creates the platform implementation used on Flutter web.
DodoPlatform createDodoPlatform() => WebDodoPlatform();

/// [DodoPlatform] backed by the real checkout SDK on the page.
class WebDodoPlatform implements DodoPlatform {
  /// Creates the web platform. The SDK is only touched once [load] runs.
  WebDodoPlatform();

  /// In-flight script load, shared by concurrent callers of [load].
  Future<void>? _pendingLoad;

  DodoPaymentsJs? get _sdk => dodoPaymentsCheckoutJs?.dodoPayments;

  @override
  bool get isSupported => true;

  @override
  bool get isLoaded => _sdk != null;

  @override
  bool get isOpen => _guard(() => _requireSdk().checkout.isOpen());

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    if (isLoaded) return;
    final inFlight = _pendingLoad;
    if (inFlight != null) return inFlight;

    final pending = _injectScript(scriptUrl, timeout);
    _pendingLoad = pending;
    try {
      await pending;
    } catch (_) {
      // Clear the cache so a later call can retry the load.
      _pendingLoad = null;
      rethrow;
    }
  }

  @override
  void initialize(JsonMap options, DodoEventHandler onEvent) {
    _guard(() {
      final sdk = _requireSdk();
      final config = options.jsify()! as JSObject;
      void eventCallback(JSAny? event) {
        try {
          onEvent(toJsonMap(event?.dartify()));
        } catch (error, stackTrace) {
          // A Dart failure must never break the checkout SDK itself.
          Zone.current.handleUncaughtError(error, stackTrace);
        }
      }

      config.setProperty('onEvent'.toJS, eventCallback.toJS);
      sdk.initialize(config);
    });
  }

  @override
  void open(JsonMap options) =>
      _guard(() => _requireSdk().checkout.open(options.jsify()!));

  @override
  void close() => _guard(() => _requireSdk().checkout.close());

  @override
  void prepareFrameHost(Object element, {required String elementId}) {
    final host = element as web.HTMLElement;
    host.id = elementId;
    host.style
      ..width = '100%'
      ..height = '100%'
      ..overflow = 'auto';
  }

  @override
  Future<bool> whenFrameHostReady(
    String elementId, {
    required bool Function() isCancelled,
  }) async {
    while (web.document.getElementById(elementId)?.isConnected != true) {
      if (isCancelled()) return false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return !isCancelled();
  }

  /// Returns the live SDK object or throws when it is not loaded.
  DodoPaymentsJs _requireSdk() {
    final sdk = _sdk;
    if (sdk == null) throw const DodoNotInitializedException();
    return sdk;
  }

  /// Runs [body], converting SDK errors into [DodoJsException]. Package
  /// exceptions pass through unchanged.
  T _guard<T>(T Function() body) {
    try {
      return body();
    } on DodoException {
      rethrow;
    } catch (error) {
      throw DodoJsException(error.toString(), raw: error);
    }
  }

  /// Injects a fresh SDK `<script>` and completes once the SDK is defined.
  ///
  /// A tag with the same `src` that is already in the page is replaced. It
  /// may have failed or finished loading long ago, and a finished tag never
  /// fires `load` or `error` again. A tag that fails or times out is removed,
  /// so a retry starts clean.
  Future<void> _injectScript(Uri scriptUrl, Duration timeout) {
    final src = scriptUrl.toString();
    _findScript(src)?.remove();
    final script = _createScript(src);
    final completer = Completer<void>();
    Timer? timer;

    void fail(String message) {
      if (completer.isCompleted) return;
      timer?.cancel();
      script.remove();
      completer.completeError(DodoScriptLoadException(message));
    }

    void onLoad(web.Event event) {
      if (completer.isCompleted) return;
      if (!isLoaded) {
        fail('$src loaded but did not define the Dodo checkout SDK.');
        return;
      }
      timer?.cancel();
      completer.complete();
    }

    void onError(web.Event event) =>
        fail('Failed to load the Dodo checkout SDK from $src');

    timer = Timer(
      timeout,
      () => fail(
        'Timed out after ${timeout.inMilliseconds}ms loading the Dodo '
        'checkout SDK from $src.',
      ),
    );
    script
      ..addEventListener('load', onLoad.toJS)
      ..addEventListener('error', onError.toJS);
    (web.document.head ?? web.document.body)?.appendChild(script);
    return completer.future;
  }

  web.HTMLScriptElement _createScript(String src) =>
      (web.document.createElement('script') as web.HTMLScriptElement)
        ..src = src
        ..async = true;

  /// Returns the `<script>` element already pointing at [src], if any.
  ///
  /// `script.src` is the URL as the browser resolved and normalized it, so
  /// [src] is normalized the same way before comparing.
  web.HTMLScriptElement? _findScript(String src) {
    final normalized = (web.HTMLAnchorElement()..href = src).href;
    final scripts = web.document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      // getElementsByTagName('script') only ever yields script elements.
      final script = scripts.item(i) as web.HTMLScriptElement?;
      if (script != null && script.src == normalized) return script;
    }
    return null;
  }
}
