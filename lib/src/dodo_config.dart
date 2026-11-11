import 'core/dodo_exception.dart';
import 'core/dodo_mode.dart';

/// Configuration passed to `Dodo.initialize`.
///
/// There is deliberately no API key here: Dodo API keys are secret and must
/// stay on your backend.
class DodoConfig {
  /// Creates a configuration for [mode].
  const DodoConfig({
    required this.mode,
    this.scriptUrl,
    this.loadTimeout = const Duration(seconds: 20),
  });

  /// Default checkout SDK location, pinned to the version this package was
  /// tested against.
  static final Uri defaultScriptUrl = Uri.parse(
    'https://cdn.jsdelivr.net/npm/dodopayments-checkout@2.1.0/dist/index.js',
  );

  /// Whether checkouts run in test or live mode. Must match the backend that
  /// creates the checkout sessions.
  final DodoMode mode;

  /// Overrides where the checkout SDK is loaded from.
  final Uri? scriptUrl;

  /// How long to wait for the checkout SDK to load.
  final Duration loadTimeout;

  /// The resolved script URL.
  Uri get resolvedScriptUrl => scriptUrl ?? defaultScriptUrl;

  /// Throws [DodoConfigurationException] when the config cannot work.
  void validate() {
    if (loadTimeout <= Duration.zero) {
      throw const DodoConfigurationException('loadTimeout must be positive.');
    }
    if (resolvedScriptUrl.scheme != 'https') {
      throw const DodoConfigurationException('scriptUrl must use https.');
    }
  }
}
