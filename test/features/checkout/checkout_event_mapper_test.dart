import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/features/checkout/data/checkout_event_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CheckoutEvent parse(String type, [Object? data]) =>
      checkoutEventFromJson({'event_type': type, 'data': data});

  test('maps every payload-free event type', () {
    final expected = <String, Matcher>{
      'checkout.opened': isA<CheckoutOpened>(),
      'checkout.form_ready': isA<CheckoutFormReady>(),
      'checkout.payment_page_opened': isA<CheckoutPaymentPageOpened>(),
      'checkout.customer_details_submitted':
          isA<CheckoutCustomerDetailsSubmitted>(),
      'checkout.pay_button_clicked': isA<CheckoutPayButtonClicked>(),
      'checkout.link_expired': isA<CheckoutLinkExpired>(),
    };
    expected.forEach((type, matcher) {
      final event = parse(type);
      expect(event, matcher);
      expect(event.type, type);
    });
  });

  test('keeps the original event in raw', () {
    final json = {
      'event_type': 'checkout.opened',
      'data': {'timestamp': 1},
    };
    expect(checkoutEventFromJson(json).raw, same(json));
  });

  test('reads the message of closed and error events', () {
    final closed = parse('checkout.closed', {'message': 'Closed'});
    final failed = parse('checkout.error', {'message': 'Boom'});
    expect((closed as CheckoutClosed).message, 'Closed');
    expect((failed as CheckoutFailed).message, 'Boom');
  });

  group('breakdown', () {
    CheckoutBreakdown breakdown(Map<String, Object?> message) =>
        (parse('checkout.breakdown', {'message': message})
                as CheckoutBreakdownChanged)
            .breakdown;

    test('builds amounts in their currencies', () {
      final result = breakdown({
        'subTotal': 1000,
        'discount': 100,
        'tax': 90,
        'total': 990,
        'currency': 'USD',
        'finalTotal': 150000,
        'finalTotalCurrency': 'JPY',
      });
      expect(
        result.subTotal,
        const DodoAmount(minorUnits: 1000, currency: 'USD'),
      );
      expect(result.total, const DodoAmount(minorUnits: 990, currency: 'USD'));
      expect(
        result.finalTotal,
        const DodoAmount(minorUnits: 150000, currency: 'JPY'),
      );
    });

    test('final total falls back to the base currency', () {
      final result = breakdown({'finalTotal': 500, 'currency': 'EUR'});
      expect(result.finalTotal?.currency, 'EUR');
    });

    test('tolerates null, malformed and currency-less amounts', () {
      final partial = breakdown({
        'subTotal': 1000,
        'tax': null,
        'discount': 'n/a',
        'currency': 'USD',
      });
      expect(partial.subTotal, isNotNull);
      expect(partial.tax, isNull);
      expect(partial.discount, isNull);
      expect(breakdown({'subTotal': 1000}).subTotal, isNull);
      expect(
        breakdown({'subTotal': double.nan, 'currency': 'USD'}).subTotal,
        isNull,
      );
    });
  });

  group('undocumented payloads', () {
    test('status is read from data or data.message', () {
      final direct = parse('checkout.status', {'status': 'succeeded'});
      final nested = parse('checkout.status', {
        'message': {'status': 'failed'},
      });
      expect((direct as CheckoutStatusChanged).status, 'succeeded');
      expect((nested as CheckoutStatusChanged).status, 'failed');
    });

    test('redirect URLs are read from data.message.redirect_to', () {
      final event = parse('checkout.redirect', {
        'message': {'redirect_to': 'https://bank.example/auth'},
      });
      expect(
        (event as CheckoutRedirecting).redirectUrl,
        Uri.parse('https://bank.example/auth'),
      );
    });

    test('a missing redirect URL is null, not an error', () {
      final event = parse('checkout.redirect_requested', {'timestamp': 1});
      expect((event as CheckoutRedirectRequested).redirectUrl, isNull);
    });
  });

  group('never throws', () {
    test('unknown types become CheckoutUnknownEvent', () {
      final event = parse('checkout.resize', {'height': 500});
      expect(event, isA<CheckoutUnknownEvent>());
      expect(event.type, 'checkout.resize');
    });

    test('malformed events are tolerated', () {
      expect(checkoutEventFromJson({}), isA<CheckoutUnknownEvent>());
      expect(parse('checkout.error', 'not a map'), isA<CheckoutFailed>());
      expect(parse('checkout.breakdown', 42), isA<CheckoutBreakdownChanged>());
    });
  });
}
