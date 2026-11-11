// Runs the real WebDodoPlatform in a browser, against a stand-in SDK loaded
// from a data: URL so the tests need no network:
//
//   flutter test --platform chrome test/web
@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/core/platform/web/dodo_platform_web.dart';
import 'package:dodo_wrapper/src/features/checkout/data/dodo_checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

/// Stand-in for the SDK's `DodoPaymentsCheckout.DodoPayments` global. Its
/// `open` mimics the real SDK: a bad URL emits `checkout.error`, then throws.
const _fakeSdk = '''
window.__dodoCalls = [];
window.DodoPaymentsCheckout = { DodoPayments: {
  Initialize: function (config) {
    window.__dodoCalls.push('init:' + config.mode + ':' + config.displayType);
    window.__dodoOnEvent = config.onEvent;
  },
  Checkout: {
    opened: false,
    open: function (options) {
      if (options.checkoutUrl === 'bad' || options.checkoutUrl.indexOf('cks_bad') >= 0) {
        window.__dodoOnEvent({event_type: 'checkout.error', data: {message: 'x'}});
        throw new Error('Invalid checkout URL format');
      }
      this.opened = true;
      window.__dodoCalls.push('open:' + options.checkoutUrl + ':' +
        (options.options ? options.options.fontSize : ''));
      window.__dodoOnEvent({event_type: 'checkout.breakdown',
        data: {message: {total: 1999, currency: 'USD'}, timestamp: 1}});
    },
    close: function () { this.opened = false; },
    isOpen: function () { return this.opened; }
  }
}};
''';

Uri _script(String source) =>
    Uri.dataFromString(source, mimeType: 'text/javascript');

List<String> _calls() =>
    (globalContext['__dodoCalls'] as JSArray<JSString>?)?.toDart
        .map((call) => call.toDart)
        .toList() ??
    const [];

int _tagsWithSrc(Uri url) {
  final normalized = (web.HTMLAnchorElement()..href = url.toString()).href;
  final scripts = web.document.getElementsByTagName('script');
  var count = 0;
  for (var i = 0; i < scripts.length; i++) {
    final script = scripts.item(i) as web.HTMLScriptElement?;
    if (script?.src == normalized) count++;
  }
  return count;
}

Future<void> _appendScript(Uri url) {
  final done = Completer<void>();
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..src = url.toString();
  script
    ..addEventListener('load', ((web.Event _) => done.complete()).toJS)
    ..addEventListener('error', ((web.Event _) => done.complete()).toJS);
  web.document.head!.appendChild(script);
  return done.future;
}

void main() {
  group('script loading', () {
    test(
      'a tag that loaded without the SDK fails fast, not by timeout',
      () async {
        final url = _script('window.__unrelated = 1;');
        // As if the app's index.html already had this tag.
        await _appendScript(url);

        final stopwatch = Stopwatch()..start();
        await expectLater(
          WebDodoPlatform().load(url, timeout: const Duration(seconds: 10)),
          throwsA(isA<DodoScriptLoadException>()),
        );
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
        expect(_tagsWithSrc(url), 0, reason: 'the failed tag is removed');
      },
    );

    test('a failed load can be retried, quickly', () async {
      // Nothing listens on port 9, so the request fails at once.
      final url = Uri.parse('http://127.0.0.1:9/dodo.js');
      final platform = WebDodoPlatform();
      for (var attempt = 0; attempt < 2; attempt++) {
        final stopwatch = Stopwatch()..start();
        await expectLater(
          platform.load(url, timeout: const Duration(seconds: 10)),
          throwsA(isA<DodoScriptLoadException>()),
        );
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      }
    });

    test('loads the SDK once for concurrent callers', () async {
      final url = _script(_fakeSdk);
      final platform = WebDodoPlatform();
      await Future.wait([
        platform.load(url, timeout: const Duration(seconds: 10)),
        platform.load(url, timeout: const Duration(seconds: 10)),
      ]);
      expect(platform.isLoaded, isTrue);
      expect(_tagsWithSrc(url), 1);
    });
  });

  group('checkout bridge', () {
    late WebDodoPlatform platform;
    late List<JsonMap> events;

    setUp(() async {
      platform = WebDodoPlatform();
      await platform.load(
        _script(_fakeSdk),
        timeout: const Duration(seconds: 10),
      );
      events = [];
      platform.initialize({
        'mode': 'test',
        'displayType': 'overlay',
      }, events.add);
    });

    test('passes options to the SDK and events back to Dart', () {
      platform.open({
        'checkoutUrl': 'https://test.checkout.dodopayments.com/session/cks_1',
        'options': {'fontSize': 'lg'},
      });
      expect(_calls(), [
        'init:test:overlay',
        'open:https://test.checkout.dodopayments.com/session/cks_1:lg',
      ]);
      expect(platform.isOpen, isTrue);

      final event = events.single;
      expect(event['event_type'], 'checkout.breakdown');
      final message = (event['data'] as Map)['message'] as Map;
      expect((message['total'] as num).toInt(), 1999);

      platform.close();
      expect(platform.isOpen, isFalse);
    });

    test('an SDK error becomes DodoJsException', () {
      expect(
        () => platform.open({'checkoutUrl': 'bad'}),
        throwsA(
          isA<DodoJsException>().having(
            (e) => e.message,
            'message',
            contains('Invalid checkout URL format'),
          ),
        ),
      );
    });

    test('through the service, a rejected open is reported once', () async {
      final service = DodoCheckoutService(bridge: platform, mode: DodoMode.test)
        ..initialize();
      final published = <CheckoutEvent>[];
      final subscription = service.events.listen(published.add);
      addTearDown(() async {
        await subscription.cancel();
        await service.dispose();
      });

      await expectLater(
        service.open(
          CheckoutOptions(
            checkoutUrl: Uri.parse(
              'https://test.checkout.dodopayments.com/session/cks_bad',
            ),
          ),
        ),
        throwsA(isA<DodoJsException>()),
      );
      await pumpEventQueue();
      expect(published.whereType<CheckoutFailed>(), isEmpty);
    });
  });

  group('frame host', () {
    test('waits for the host to join the page, then resolves', () async {
      final platform = WebDodoPlatform();
      final host = web.document.createElement('div');
      platform.prepareFrameHost(host, elementId: 'dodo-test-host');
      expect((host as web.HTMLElement).style.overflow, 'auto');

      var resolved = false;
      final ready = platform
          .whenFrameHostReady('dodo-test-host', isCancelled: () => false)
          .then((value) => resolved = value);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(resolved, isFalse);

      web.document.body!.appendChild(host);
      await ready.timeout(const Duration(seconds: 2));
      expect(resolved, isTrue);
      host.remove();
    });

    test('stops waiting once cancelled', () async {
      var cancelled = false;
      final ready = WebDodoPlatform().whenFrameHostReady(
        'dodo-never-attached',
        isCancelled: () => cancelled,
      );
      cancelled = true;
      expect(await ready.timeout(const Duration(seconds: 2)), isFalse);
    });
  });
}
