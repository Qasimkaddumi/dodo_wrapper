import 'dart:async';

import 'package:flutter/foundation.dart';

import 'core/dodo_exception.dart';
import 'core/dodo_mode.dart';
import 'core/platform/dodo_platform.dart';
import 'dodo_config.dart';
import 'features/checkout/data/dodo_checkout_service.dart';
import 'features/checkout/domain/checkout_service.dart';
import 'features/checkout/domain/entities/checkout_event.dart';

/// Entry point of the package: a facade over the Dodo checkout SDK.
///
/// The SDK is a page-wide singleton, so this class is too:
///
/// ```dart
/// await Dodo.initialize(const DodoConfig(mode: DodoMode.test));
/// await Dodo.instance.checkout.open(
///   CheckoutOptions(checkoutUrl: Uri.parse(urlFromYourBackend)),
/// );
/// ```
class Dodo {
  Dodo._({required this.config, required DodoCheckoutService checkout})
    : _checkout = checkout;

  static Dodo? _instance;
  static Future<Dodo>? _initializing;
  static DodoMode? _initializingMode;

  /// The configuration Dodo was initialized with.
  final DodoConfig config;

  final DodoCheckoutService _checkout;

  /// Overlay and inline checkout.
  CheckoutService get checkout => _checkout;

  /// The initialized instance.
  ///
  /// Throws [DodoNotInitializedException] before [initialize] completes.
  static Dodo get instance =>
      _instance ?? (throw const DodoNotInitializedException());

  /// Whether [initialize] has completed.
  static bool get isInitialized => _instance != null;

  /// Loads and initializes the checkout SDK. Safe to call more than once:
  /// later calls with the same mode return the existing instance and ignore
  /// their other settings, and a different mode throws
  /// [DodoConfigurationException].
  ///
  /// [platform] lets tests (or future platforms) replace the SDK bridge.
  static Future<Dodo> initialize(DodoConfig config, {DodoPlatform? platform}) {
    final existing = _instance;
    if (existing != null) {
      if (existing.config.mode != config.mode) {
        return Future.error(_modeConflict);
      }
      return Future.value(existing);
    }
    final pending = _initializing;
    if (pending != null) {
      // An overlapping call must not silently get an instance in another mode.
      if (_initializingMode != config.mode) return Future.error(_modeConflict);
      return pending;
    }
    _initializingMode = config.mode;
    return _initializing = _create(
      config,
      platform ?? DodoPlatform(),
    ).whenComplete(() => _initializing = _initializingMode = null);
  }

  static const DodoConfigurationException _modeConflict =
      DodoConfigurationException(
        'Dodo is already initialized in a different mode. Reload the page to '
        'switch modes.',
      );

  static Future<Dodo> _create(DodoConfig config, DodoPlatform platform) async {
    config.validate();
    if (!platform.isSupported) throw const DodoUnsupportedPlatformException();

    await platform.load(config.resolvedScriptUrl, timeout: config.loadTimeout);

    final checkout = DodoCheckoutService(bridge: platform, mode: config.mode)
      ..initialize();
    return _instance = Dodo._(config: config, checkout: checkout);
  }

  /// Every checkout event. Shortcut for `checkout.events`.
  ///
  /// This is a broadcast stream without replay: events emitted while nobody
  /// listens are dropped. Subscribe before opening a checkout.
  Stream<CheckoutEvent> get events => checkout.events;

  /// Drops the singleton so [initialize] can run again. Tests only.
  @visibleForTesting
  static Future<void> reset() async {
    final instance = _instance;
    _instance = null;
    _initializing = null;
    _initializingMode = null;
    await instance?._checkout.dispose();
  }
}
