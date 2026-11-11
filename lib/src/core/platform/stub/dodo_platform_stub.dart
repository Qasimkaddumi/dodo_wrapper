import '../../dodo_exception.dart';
import '../../json.dart';
import '../dodo_checkout_bridge.dart';
import '../dodo_platform.dart';

/// Creates the platform implementation used on non-web targets.
DodoPlatform createDodoPlatform() => const StubDodoPlatform();

/// [DodoPlatform] for platforms without the checkout SDK. Every call throws
/// [DodoUnsupportedPlatformException].
class StubDodoPlatform implements DodoPlatform {
  /// Creates the stub platform.
  const StubDodoPlatform();

  @override
  bool get isSupported => false;

  @override
  bool get isLoaded => false;

  @override
  bool get isOpen => false;

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    throw const DodoUnsupportedPlatformException();
  }

  @override
  void initialize(JsonMap options, DodoEventHandler onEvent) {
    throw const DodoUnsupportedPlatformException();
  }

  @override
  void open(JsonMap options) {
    throw const DodoUnsupportedPlatformException();
  }

  @override
  void close() {
    throw const DodoUnsupportedPlatformException();
  }

  @override
  void prepareFrameHost(Object element, {required String elementId}) {
    throw const DodoUnsupportedPlatformException();
  }

  @override
  Future<bool> whenFrameHostReady(
    String elementId, {
    required bool Function() isCancelled,
  }) async {
    throw const DodoUnsupportedPlatformException();
  }
}
