import 'package:dodo_wrapper/dodo_wrapper.dart';

/// Build-time configuration read from `--dart-define` flags.
///
/// Dodo API keys are secret and must never appear here: anything in an app
/// ships to every browser.
abstract final class AppConfig {
  static const String _mode = String.fromEnvironment(
    'DODO_MODE',
    defaultValue: 'test',
  );

  /// Must match the mode of the backend that creates the sessions.
  static DodoMode get mode => _mode == 'live' ? DodoMode.live : DodoMode.test;

  /// Optional checkout URL to prefill.
  static const String checkoutUrl = String.fromEnvironment('CHECKOUT_URL');
}
