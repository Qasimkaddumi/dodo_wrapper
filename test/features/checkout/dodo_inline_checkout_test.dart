import 'dart:async';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/features/checkout/data/dodo_checkout_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_dodo_platform.dart';

void main() {
  final firstUrl = Uri.parse(
    'https://test.checkout.dodopayments.com/session/cks_1',
  );
  final secondUrl = Uri.parse(
    'https://test.checkout.dodopayments.com/session/cks_2',
  );

  late FakeDodoPlatform platform;
  late DodoCheckoutService service;

  setUp(() {
    platform = FakeDodoPlatform();
    service = DodoCheckoutService(bridge: platform, mode: DodoMode.test)
      ..initialize();
  });

  tearDown(() => service.dispose());

  Widget inline(Uri url, {ValueChanged<Object>? onError}) => DodoInlineCheckout(
    checkoutUrl: url,
    checkoutService: service,
    frameHost: platform,
    onError: onError,
    hostBuilder: (onElementCreated) {
      onElementCreated(Object());
      return const SizedBox.shrink();
    },
  );

  List<JsonMap> opens() => platform.argsOf('open').cast<JsonMap>();

  testWidgets('opens inline in the element it prepared', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();

    final elementId = platform.argsOf('prepareFrameHost').first;
    expect(elementId, startsWith('dodo-inline-checkout-'));
    expect(platform.argsOf('whenFrameHostReady'), [elementId]);
    expect(opens().single, {
      'checkoutUrl': firstUrl.toString(),
      'elementId': elementId,
    });
    expect(platform.argsOf('initialize').last, {
      'mode': 'test',
      'displayType': 'inline',
    });
  });

  testWidgets('each instance gets its own element id', (tester) async {
    await tester.pumpWidget(
      Column(children: [inline(firstUrl), inline(secondUrl)]),
    );
    final ids = platform.argsOf('prepareFrameHost');
    expect(ids.toSet(), hasLength(2));
  });

  testWidgets('a new URL replaces the open checkout', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    await tester.pumpWidget(inline(secondUrl));
    await tester.pump();

    expect(opens().map((o) => o['checkoutUrl']), [
      firstUrl.toString(),
      secondUrl.toString(),
    ]);
    expect(opens().last['elementId'], opens().first['elementId']);
  });

  testWidgets('the same URL does not reopen', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    expect(opens(), hasLength(1));
  });

  testWidgets('dispose closes its own checkout', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(platform.argsOf('close'), hasLength(1));
    expect(service.isOpen, isFalse);
  });

  testWidgets('dispose leaves a checkout opened elsewhere', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();

    final overlay = CheckoutOptions(checkoutUrl: secondUrl);
    await service.open(overlay);
    final closesBefore = platform.argsOf('close').length;

    await tester.pumpWidget(const SizedBox.shrink());
    expect(platform.argsOf('close'), hasLength(closesBefore));
    expect(service.currentOptions, same(overlay));
  });

  testWidgets('does not close a checkout the customer closed', (tester) async {
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    platform.isOpen = false;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(platform.argsOf('close'), isEmpty);
  });

  testWidgets('disposed while waiting for the host, it never opens', (
    tester,
  ) async {
    final gate = platform.frameHostGate = Completer<void>();
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    gate.complete();
    await tester.pump();
    expect(opens(), isEmpty);
  });

  testWidgets('a URL change while waiting opens only the latest', (
    tester,
  ) async {
    final gate = platform.frameHostGate = Completer<void>();
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    await tester.pumpWidget(inline(secondUrl));
    await tester.pump();

    gate.complete();
    await tester.pump();
    expect(opens().map((o) => o['checkoutUrl']), [secondUrl.toString()]);
  });

  testWidgets('a host shown late still opens, without an error', (
    tester,
  ) async {
    final gate = platform.frameHostGate = Completer<void>();
    final errors = <Object>[];
    await tester.pumpWidget(inline(firstUrl, onError: errors.add));
    // A host in a hidden tab can stay out of the page for a long time.
    await tester.pump(const Duration(minutes: 1));
    expect(opens(), isEmpty);
    expect(errors, isEmpty);

    gate.complete();
    await tester.pump();
    expect(opens(), hasLength(1));
    expect(errors, isEmpty);
  });

  testWidgets('reports open failures to onError', (tester) async {
    platform.openError = const DodoJsException('rejected');
    final errors = <Object>[];
    await tester.pumpWidget(inline(firstUrl, onError: errors.add));
    await tester.pump();
    expect(errors.single, isA<DodoJsException>());
  });

  testWidgets('reports to FlutterError without onError', (tester) async {
    platform.openError = const DodoJsException('rejected');
    await tester.pumpWidget(inline(firstUrl));
    await tester.pump();
    expect(tester.takeException(), isA<DodoJsException>());
  });
}
