import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_dodo_platform.dart';

void main() {
  const config = DodoConfig(mode: DodoMode.test);
  late FakeDodoPlatform platform;

  setUp(() => platform = FakeDodoPlatform());
  tearDown(Dodo.reset);

  group('DodoConfig', () {
    test('defaults to a pinned SDK version', () {
      expect(
        config.resolvedScriptUrl.toString(),
        contains('dodopayments-checkout@2.1.0'),
      );
    });

    test('uses scriptUrl when given', () {
      final custom = Uri.parse('https://example.com/dodo.js');
      expect(
        DodoConfig(mode: DodoMode.test, scriptUrl: custom).resolvedScriptUrl,
        custom,
      );
    });

    test('rejects unusable values', () {
      for (final invalid in [
        DodoConfig(
          mode: DodoMode.test,
          scriptUrl: Uri.parse('http://example.com/dodo.js'),
        ),
        const DodoConfig(mode: DodoMode.test, loadTimeout: Duration.zero),
      ]) {
        expect(invalid.validate, throwsA(isA<DodoConfigurationException>()));
      }
    });
  });

  test('error text does not depend on minified type names', () {
    expect(
      const DodoConfigurationException('bad').toString(),
      'DodoException: bad',
    );
  });

  group('Dodo', () {
    test('instance throws before initialize', () {
      expect(() => Dodo.instance, throwsA(isA<DodoNotInitializedException>()));
      expect(Dodo.isInitialized, isFalse);
    });

    test('loads the SDK and initializes it', () async {
      final dodo = await Dodo.initialize(config, platform: platform);
      expect(identical(dodo, Dodo.instance), isTrue);
      expect(Dodo.isInitialized, isTrue);
      expect(platform.argsOf('load'), [config.resolvedScriptUrl]);
      expect(platform.callNames, ['load', 'initialize']);
    });

    test('later calls in the same mode return the same instance', () async {
      final first = await Dodo.initialize(config, platform: platform);
      final second = await Dodo.initialize(config, platform: platform);
      expect(identical(first, second), isTrue);
      expect(platform.argsOf('load'), hasLength(1));
    });

    test('concurrent calls share one initialization', () async {
      final results = await Future.wait([
        Dodo.initialize(config, platform: platform),
        Dodo.initialize(config, platform: platform),
      ]);
      expect(identical(results[0], results[1]), isTrue);
      expect(platform.argsOf('load'), hasLength(1));
    });

    test('rejects a different mode', () async {
      await Dodo.initialize(config, platform: platform);
      await expectLater(
        Dodo.initialize(
          const DodoConfig(mode: DodoMode.live),
          platform: platform,
        ),
        throwsA(isA<DodoConfigurationException>()),
      );
    });

    test('rejects a different mode while the first call is pending', () async {
      final first = Dodo.initialize(config, platform: platform);
      final second = Dodo.initialize(
        const DodoConfig(mode: DodoMode.live),
        platform: platform,
      );
      await expectLater(second, throwsA(isA<DodoConfigurationException>()));
      expect((await first).config.mode, DodoMode.test);
      expect(platform.argsOf('load'), hasLength(1));
    });

    test('fails on unsupported platforms without loading', () async {
      platform.isSupported = false;
      await expectLater(
        Dodo.initialize(config, platform: platform),
        throwsA(isA<DodoUnsupportedPlatformException>()),
      );
      expect(platform.calls, isEmpty);
    });

    test('can retry after a failed load', () async {
      platform.loadError = const DodoScriptLoadException('offline');
      await expectLater(
        Dodo.initialize(config, platform: platform),
        throwsA(isA<DodoScriptLoadException>()),
      );
      expect(Dodo.isInitialized, isFalse);

      platform.loadError = null;
      await Dodo.initialize(config, platform: platform);
      expect(Dodo.isInitialized, isTrue);
    });

    test('events forwards checkout events', () async {
      final dodo = await Dodo.initialize(config, platform: platform);
      final next = dodo.events.first;
      platform.emit({'event_type': 'checkout.opened'});
      expect(await next, isA<CheckoutOpened>());
    });
  });
}
