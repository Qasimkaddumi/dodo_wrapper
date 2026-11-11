import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/core/platform/stub/dodo_platform_stub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const platform = StubDodoPlatform();
  final unsupported = throwsA(isA<DodoUnsupportedPlatformException>());

  test('reports that nothing is available', () {
    expect(platform.isSupported, isFalse);
    expect(platform.isLoaded, isFalse);
    expect(platform.isOpen, isFalse);
  });

  test('throws on every call', () {
    expect(
      platform.load(Uri.parse('https://x'), timeout: Duration.zero),
      unsupported,
    );
    expect(() => platform.initialize({}, (_) {}), unsupported);
    expect(() => platform.open({}), unsupported);
    expect(platform.close, unsupported);
    expect(
      () => platform.prepareFrameHost(Object(), elementId: 'x'),
      unsupported,
    );
    expect(
      platform.whenFrameHostReady('x', isCancelled: () => false),
      unsupported,
    );
  });
}
