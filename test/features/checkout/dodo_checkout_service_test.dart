import 'dart:async';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/features/checkout/data/dodo_checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dodo_platform.dart';

void main() {
  final testUrl = Uri.parse(
    'https://test.checkout.dodopayments.com/session/cks_1',
  );
  final liveUrl = Uri.parse('https://checkout.dodopayments.com/session/cks_1');

  late FakeDodoPlatform platform;
  late DodoCheckoutService service;
  late List<CheckoutEvent> events;
  late StreamSubscription<CheckoutEvent> subscription;

  setUp(() {
    platform = FakeDodoPlatform();
    service = DodoCheckoutService(bridge: platform, mode: DodoMode.test)
      ..initialize();
    events = [];
    subscription = service.events.listen(events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await service.dispose();
  });

  group('initialize', () {
    test('sets up the SDK for overlays in the configured mode', () {
      expect(platform.argsOf('initialize'), [
        {'mode': 'test', 'displayType': 'overlay'},
      ]);
    });
  });

  group('open', () {
    test('sends the mapped options to the SDK', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      expect(platform.argsOf('open'), [
        {'checkoutUrl': testUrl.toString()},
      ]);
      expect(service.isOpen, isTrue);
    });

    test('rejects invalid URLs before calling the SDK', () async {
      final badUrls = [
        // The SDK itself accepts these two.
        Uri.parse('http://test.checkout.dodopayments.com/session/cks_1'),
        liveUrl,
        Uri.parse('https://evil.example.com/session/cks_1'),
      ];
      for (final url in badUrls) {
        await expectLater(
          service.open(CheckoutOptions(checkoutUrl: url)),
          throwsA(isA<DodoValidationException>()),
        );
      }
      expect(platform.argsOf('open'), isEmpty);
    });

    test('accepts live URLs in live mode only', () async {
      final live = DodoCheckoutService(bridge: platform, mode: DodoMode.live);
      addTearDown(live.dispose);
      await live.open(CheckoutOptions(checkoutUrl: liveUrl));
      expect(platform.argsOf('open'), hasLength(1));
      await expectLater(
        live.open(CheckoutOptions(checkoutUrl: testUrl)),
        throwsA(isA<DodoValidationException>()),
      );
    });

    test('rejects static payment links with a clear message', () async {
      await expectLater(
        service.open(
          CheckoutOptions(
            checkoutUrl: Uri.parse(
              'https://test.checkout.dodopayments.com/buy/pdt_1',
            ),
          ),
        ),
        throwsA(
          isA<DodoValidationException>().having(
            (e) => e.message,
            'message',
            contains('Static payment links'),
          ),
        ),
      );
      expect(platform.argsOf('open'), isEmpty);
    });

    test('rejects a blank elementId', () async {
      await expectLater(
        service.open(CheckoutOptions(checkoutUrl: testUrl, elementId: ' ')),
        throwsA(isA<DodoValidationException>()),
      );
    });

    test('closes an open checkout before opening another', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      expect(platform.callNames, ['initialize', 'open', 'close', 'open']);
    });

    test('re-initializes only when the display type changes', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await service.open(
        CheckoutOptions(checkoutUrl: testUrl, elementId: 'host'),
      );
      expect(platform.argsOf('initialize'), [
        {'mode': 'test', 'displayType': 'overlay'},
        {'mode': 'test', 'displayType': 'inline'},
      ]);
    });

    test('closes before re-initializing', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await service.open(
        CheckoutOptions(checkoutUrl: testUrl, elementId: 'host'),
      );
      expect(platform.callNames.sublist(2), ['close', 'initialize', 'open']);
    });
  });

  group('error reporting', () {
    const errorEvent = {
      'event_type': 'checkout.error',
      'data': {'message': 'Failed to create checkout'},
    };

    test('a rejected open is reported once, by the exception', () async {
      platform
        ..eventDuringOpen = errorEvent
        ..openError = const DodoJsException('rejected');

      await expectLater(
        service.open(CheckoutOptions(checkoutUrl: testUrl)),
        throwsA(isA<DodoJsException>()),
      );
      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test('an error during a successful open is still published', () async {
      platform.eventDuringOpen = errorEvent;
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await pumpEventQueue();
      expect(events.single, isA<CheckoutFailed>());
    });

    test('a held error does not leak into the next open', () async {
      platform
        ..eventDuringOpen = errorEvent
        ..openError = const DodoJsException('rejected');
      await expectLater(
        service.open(CheckoutOptions(checkoutUrl: testUrl)),
        throwsA(isA<DodoJsException>()),
      );

      platform
        ..eventDuringOpen = null
        ..openError = null;
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      await pumpEventQueue();
      expect(events, isEmpty);
    });

    test('errors outside open are published', () async {
      platform.emit(errorEvent);
      await pumpEventQueue();
      expect(events.single, isA<CheckoutFailed>());
    });
  });

  group('currentOptions', () {
    test('is the open checkout, and null once it closes', () async {
      expect(service.currentOptions, isNull);
      final options = CheckoutOptions(checkoutUrl: testUrl);
      await service.open(options);
      expect(service.currentOptions, same(options));
      service.close();
      expect(service.currentOptions, isNull);
    });

    test('is null when the customer closed the checkout', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      platform.isOpen = false;
      expect(service.currentOptions, isNull);
    });

    test('is not set by a rejected open', () async {
      platform.openError = const DodoJsException('rejected');
      await expectLater(
        service.open(CheckoutOptions(checkoutUrl: testUrl)),
        throwsA(isA<DodoJsException>()),
      );
      expect(service.currentOptions, isNull);
    });
  });

  group('close', () {
    test('closes an open checkout', () async {
      await service.open(CheckoutOptions(checkoutUrl: testUrl));
      service.close();
      expect(platform.argsOf('close'), hasLength(1));
      expect(service.isOpen, isFalse);
    });

    test('does nothing when no checkout is open', () {
      service.close();
      expect(platform.argsOf('close'), isEmpty);
    });
  });

  group('events', () {
    test('publishes typed events', () async {
      platform.emit({'event_type': 'checkout.form_ready'});
      await pumpEventQueue();
      expect(events.single, isA<CheckoutFormReady>());
    });

    test('ignores events after dispose', () async {
      await service.dispose();
      expect(
        () => platform.emit({'event_type': 'checkout.opened'}),
        returnsNormally,
      );
    });
  });
}
