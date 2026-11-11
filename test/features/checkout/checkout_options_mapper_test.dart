import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:dodo_wrapper/src/features/checkout/data/checkout_options_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final url = Uri.parse('https://test.checkout.dodopayments.com/session/cks_1');

  test('builds Initialize options', () {
    expect(initializeOptionsToJson(DodoMode.live, CheckoutDisplayType.inline), {
      'mode': 'live',
      'displayType': 'inline',
    });
  });

  test('omits everything that was not set', () {
    expect(checkoutOptionsToJson(CheckoutOptions(checkoutUrl: url)), {
      'checkoutUrl': url.toString(),
    });
  });

  test('includes every setting', () {
    final json = checkoutOptionsToJson(
      CheckoutOptions(
        checkoutUrl: url,
        elementId: 'host',
        settings: const CheckoutSettings(
          showTimer: false,
          showSecurityBadge: true,
          manualRedirect: true,
          payButtonText: 'Pay',
          fontSize: CheckoutFontSize.xxl,
          fontWeight: CheckoutFontWeight.extraBold,
        ),
      ),
    );
    expect(json, {
      'checkoutUrl': url.toString(),
      'elementId': 'host',
      'options': {
        'showTimer': false,
        'showSecurityBadge': true,
        'manualRedirect': true,
        'payButtonText': 'Pay',
        'fontSize': '2xl',
        'fontWeight': 'extraBold',
      },
    });
  });

  test('reads the session id from the URL', () {
    expect(CheckoutOptions(checkoutUrl: url).sessionId, 'cks_1');
    expect(
      CheckoutOptions(
        checkoutUrl: Uri.parse('https://checkout.dodopayments.com/AbCd1234'),
      ).sessionId,
      isNull,
    );
  });

  test('derives the display type from elementId', () {
    expect(
      CheckoutOptions(checkoutUrl: url).displayType,
      CheckoutDisplayType.overlay,
    );
    expect(
      CheckoutOptions(checkoutUrl: url, elementId: 'x').displayType,
      CheckoutDisplayType.inline,
    );
  });
}
