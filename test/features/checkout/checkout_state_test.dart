import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const raw = <String, dynamic>{};
  const opened = CheckoutOpened(raw: raw);
  const ready = CheckoutFormReady(raw: raw);
  const payClicked = CheckoutPayButtonClicked(raw: raw);
  const failed = CheckoutFailed(raw: raw, message: 'Declined');
  const breakdownEvent = CheckoutBreakdownChanged(
    raw: raw,
    breakdown: CheckoutBreakdown(
      total: DodoAmount(minorUnits: 100, currency: 'USD'),
    ),
  );

  CheckoutState replay(List<CheckoutEvent> events) =>
      events.fold(const CheckoutState(), (state, e) => state.apply(e));

  test('starts idle', () {
    expect(const CheckoutState().phase, CheckoutPhase.idle);
  });

  test('follows the checkout lifecycle', () {
    expect(replay([opened]).phase, CheckoutPhase.loading);
    expect(replay([opened, ready]).phase, CheckoutPhase.ready);
    expect(
      replay([opened, ready, payClicked]).phase,
      CheckoutPhase.processingPayment,
    );
    expect(
      replay([opened, const CheckoutRedirecting(raw: raw)]).phase,
      CheckoutPhase.redirecting,
    );
    expect(
      replay([opened, const CheckoutLinkExpired(raw: raw)]).phase,
      CheckoutPhase.expired,
    );
    expect(
      replay([opened, const CheckoutClosed(raw: raw)]).phase,
      CheckoutPhase.closed,
    );
  });

  test('keeps the latest breakdown', () {
    final state = replay([opened, breakdownEvent, ready]);
    expect(state.breakdown?.total?.minorUnits, 100);
  });

  test('keeps the reported status', () {
    final state = replay([
      const CheckoutStatusChanged(raw: raw, status: 'succeeded'),
      ready,
    ]);
    expect(state.status, 'succeeded');
  });

  test('a failed payment returns to the form with an error', () {
    final state = replay([opened, ready, payClicked, failed]);
    expect(state.phase, CheckoutPhase.ready);
    expect(state.errorMessage, 'Declined');
  });

  test('an unrelated failure does not change the phase', () {
    expect(replay([opened, failed]).phase, CheckoutPhase.loading);
  });

  test('the error survives price updates and clears on retry', () {
    final failure = [opened, ready, payClicked, failed];
    expect(replay([...failure, breakdownEvent]).errorMessage, 'Declined');
    expect(replay([...failure, payClicked]).errorMessage, isNull);
  });

  test('a new checkout starts from a clean slate', () {
    final state = replay([opened, breakdownEvent, failed, opened]);
    expect(state.breakdown, isNull);
    expect(state.errorMessage, isNull);
    expect(state.phase, CheckoutPhase.loading);
  });

  test('unknown events only update lastEvent', () {
    const unknown = CheckoutUnknownEvent(type: 'checkout.new', raw: raw);
    final state = replay([opened, ready, unknown]);
    expect(state.phase, CheckoutPhase.ready);
    expect(state.lastEvent, same(unknown));
  });
}
