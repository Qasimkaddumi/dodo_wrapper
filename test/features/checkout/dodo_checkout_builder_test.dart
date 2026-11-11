import 'dart:async';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<CheckoutEvent> events;

  setUp(() => events = StreamController<CheckoutEvent>.broadcast());
  tearDown(() => events.close());

  /// Lets the stream deliver its event, then builds the resulting frame.
  Future<void> deliver(WidgetTester tester) async {
    await tester.idle();
    await tester.pump();
  }

  Widget builder({
    Stream<CheckoutEvent>? stream,
    ValueChanged<CheckoutEvent>? onEvent,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: DodoCheckoutBuilder(
      events: stream ?? events.stream,
      onEvent: onEvent,
      builder: (_, state) => Text(state.phase.name),
    ),
  );

  testWidgets('rebuilds from events', (tester) async {
    await tester.pumpWidget(builder());
    expect(find.text('idle'), findsOneWidget);

    events.add(const CheckoutFormReady(raw: {}));
    await deliver(tester);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('forwards every event to onEvent', (tester) async {
    final received = <CheckoutEvent>[];
    await tester.pumpWidget(builder(onEvent: received.add));
    events.add(const CheckoutOpened(raw: {}));
    await tester.pump();
    expect(received.single, isA<CheckoutOpened>());
  });

  testWidgets('switches to a new event source', (tester) async {
    final other = StreamController<CheckoutEvent>.broadcast();
    addTearDown(other.close);
    await tester.pumpWidget(builder());
    await tester.pumpWidget(builder(stream: other.stream));

    events.add(const CheckoutFormReady(raw: {}));
    await deliver(tester);
    expect(find.text('idle'), findsOneWidget);

    other.add(const CheckoutClosed(raw: {}));
    await deliver(tester);
    expect(find.text('closed'), findsOneWidget);
  });

  testWidgets('stops listening after dispose', (tester) async {
    await tester.pumpWidget(builder());
    expect(events.hasListener, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(events.hasListener, isFalse);
  });
}
