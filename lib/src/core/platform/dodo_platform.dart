import 'dodo_checkout_bridge.dart';
import 'dodo_frame_host.dart';
import 'dodo_platform_factory.dart';
import 'dodo_script_loader.dart';

/// Everything the package needs from the host platform.
///
/// New platforms are added by implementing this interface. Consumers of a
/// single capability depend on [DodoScriptLoader], [DodoCheckoutBridge] or
/// [DodoFrameHost] rather than on this composition.
///
/// Implement it outside this package only for test fakes. Members may be
/// added in minor releases as the checkout SDK grows.
abstract interface class DodoPlatform
    implements DodoScriptLoader, DodoCheckoutBridge, DodoFrameHost {
  /// The implementation for the current platform. On web this drives the
  /// real checkout SDK; elsewhere every call throws
  /// `DodoUnsupportedPlatformException`.
  factory DodoPlatform() => createDodoPlatform();
}
