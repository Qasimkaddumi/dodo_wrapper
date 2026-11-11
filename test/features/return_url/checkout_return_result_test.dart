import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CheckoutReturnResult? parse(String url) =>
      CheckoutReturnResult.fromUri(Uri.parse(url));

  test('reads a one-time payment', () {
    final result = parse(
      'https://app.test/success?payment_id=pay_1&status=succeeded'
      '&email=a%40b.com',
    )!;
    expect(result.paymentId, 'pay_1');
    expect(result.subscriptionId, isNull);
    expect(result.id, 'pay_1');
    expect(result.status, CheckoutReturnStatus.succeeded);
    expect(result.rawStatus, 'succeeded');
    expect(result.email, 'a@b.com');
    expect(result.licenseKeys, isEmpty);
  });

  test('reads a subscription with several license keys', () {
    final result = parse(
      'https://app.test/success?subscription_id=sub_1&status=active'
      '&license_key=LK-1,LK-2',
    )!;
    expect(result.id, 'sub_1');
    expect(result.status, CheckoutReturnStatus.active);
    expect(result.licenseKeys, ['LK-1', 'LK-2']);
  });

  test('maps every status', () {
    const expected = {
      'failed': CheckoutReturnStatus.failed,
      'processing': CheckoutReturnStatus.processing,
      'expired': CheckoutReturnStatus.expired,
      'requires_payment_method': CheckoutReturnStatus.requiresAction,
      'requires_customer_action': CheckoutReturnStatus.requiresAction,
    };
    expected.forEach((raw, status) {
      expect(
        parse('https://app.test/?payment_id=pay_1&status=$raw')!.status,
        status,
      );
    });
  });

  test('a missing or new status is unknown when an id is present', () {
    expect(
      parse('https://app.test/?payment_id=pay_1')!.status,
      CheckoutReturnStatus.unknown,
    );
    final result = parse(
      'https://app.test/?payment_id=pay_1&status=brand_new',
    )!;
    expect(result.status, CheckoutReturnStatus.unknown);
    expect(result.rawStatus, 'brand_new');
  });

  group('hash routes', () {
    test('reads parameters appended after the hash route', () {
      final result = parse(
        'https://app.test/#/success?payment_id=pay_1&status=failed',
      )!;
      expect(result.paymentId, 'pay_1');
      expect(result.status, CheckoutReturnStatus.failed);
    });

    test('reads parameters placed before the hash route', () {
      final result = parse(
        'https://app.test/?payment_id=pay_1&status=failed#/success',
      )!;
      expect(result.paymentId, 'pay_1');
    });

    test('a hash route without a query is not a return URL', () {
      expect(parse('https://app.test/#/success'), isNull);
    });
  });

  group('other URLs', () {
    test('are not treated as return URLs', () {
      expect(parse('https://app.test/'), isNull);
      expect(parse('https://app.test/orders?page=2'), isNull);
    });

    test('an unrelated status parameter is ignored', () {
      expect(parse('https://app.test/orders?status=shipped'), isNull);
    });

    test('a success status without an id is an app page, not a return', () {
      expect(parse('https://app.test/users?status=active'), isNull);
      expect(parse('https://app.test/jobs?status=succeeded'), isNull);
      expect(parse('https://app.test/jobs?status=processing'), isNull);
    });

    test('failed and expired are accepted without an id', () {
      expect(
        parse('https://app.test/?status=expired')!.status,
        CheckoutReturnStatus.expired,
      );
      expect(
        parse('https://app.test/?status=failed')!.status,
        CheckoutReturnStatus.failed,
      );
    });
  });

  group('malformed URLs never throw', () {
    test('invalid UTF-8 in another parameter is skipped', () {
      final result = parse('https://app.test/?x=%FF&payment_id=pay_1');
      expect(result?.paymentId, 'pay_1');
    });

    test('invalid UTF-8 in a hash route query is skipped', () {
      expect(parse('https://app.test/#/s?x=%FF'), isNull);
      expect(parse('https://app.test/#/s?x=%FF&payment_id=p')?.id, 'p');
    });

    test('decodes plus signs and keys without values', () {
      final result = parse(
        'https://app.test/?payment_id=pay_1&email=a+b%40c.com&flag',
      )!;
      expect(result.email, 'a b@c.com');
    });

    test('trims spaces around license keys', () {
      final result = parse(
        'https://app.test/?payment_id=p&license_key=LK-1,%20LK-2,,',
      )!;
      expect(result.licenseKeys, ['LK-1', 'LK-2']);
    });
  });
}
