# dodo_wrapper

Unofficial [Dodo Payments](https://dodopayments.com) checkout for Flutter web. This package is not affiliated with Dodo Payments.

For Android and iOS, use Dodo's official [`dodopayments_checkout`](https://pub.dev/packages/dodopayments_checkout) package.

## Features

- Overlay checkout above your Flutter app
- Inline checkout embedded in your layout with `DodoInlineCheckout`
- Typed checkout events
- Live price breakdowns for your own order summary with `DodoCheckoutBuilder`
- Return-URL parsing, including hash routes
- Polling helper for waiting on your backend to confirm a payment
- Works with JavaScript and WebAssembly builds

## How it fits

This package is client-side only. It holds no API key and makes no API calls.

```text
Your Flutter app                 Your backend                 Dodo Payments
      |  1. "I want the pro plan"      |                            |
      |------------------------------->|  2. POST /checkouts        |
      |                                |--------------------------->|
      |  3. checkout_url               |<---------------------------|
      |<-------------------------------|                            |
      |  4. Dodo.instance.checkout.open(...)                        |
      |------------------------------------------------------------>|
      |                                |  5. verified webhook       |
      |                                |<---------------------------|
      |  6. "Is my order paid yet?"    |                            |
      |------------------------------->|                            |
```

Your backend needs to:

- Create a checkout session and return its `checkout_url` to the app. Session URLs are single-use, so create a new one for every attempt.
- Set `return_url` to a page of your Flutter app.
- Grant access only after a verified webhook.

Never put a Dodo API key in your app. Anything in an app ships to every browser.

## Platform support

Flutter web only, on Flutter 3.32 or later. On other platforms, `Dodo.initialize` throws `DodoUnsupportedPlatformException`.

## Installation

```yaml
dependencies:
  dodo_wrapper: ^0.1.0
```

The package loads Dodo's checkout SDK from `cdn.jsdelivr.net` at runtime. If your site uses a Content Security Policy, allow that host and Dodo's checkout domains. To host the script yourself, set `DodoConfig.scriptUrl`.

## Quick start

```dart
import 'package:dodo_wrapper/dodo_wrapper.dart';

await Dodo.initialize(const DodoConfig(mode: DodoMode.test));

// Subscribe before opening a checkout, so that no event is missed.
Dodo.instance.events.listen((event) {
  switch (event) {
    case CheckoutFormReady():
      hideLoader();
    case CheckoutFailed(:final message):
      showError(message);
    default:
      break;
  }
});

final checkoutUrl = await myBackend.createCheckout(plan: 'pro');
await Dodo.instance.checkout.open(
  CheckoutOptions(checkoutUrl: Uri.parse(checkoutUrl)),
);
```

`mode` must match the backend that created the session: a test session cannot be opened in live mode, or the other way round.

## Inline checkout

Render the payment form in your own layout. Give the widget a bounded height; taller content scrolls inside it.

```dart
Row(
  children: [
    Expanded(
      child: DodoCheckoutBuilder(
        builder: (context, state) {
          final breakdown = state.breakdown;
          return Column(
            children: [
              Text('Subtotal: ${breakdown?.subTotal ?? '—'}'),
              Text('Tax: ${breakdown?.tax ?? '—'}'),
              Text('You pay: ${breakdown?.finalTotal ?? '—'}'),
            ],
          );
        },
      ),
    ),
    Expanded(
      child: SizedBox(
        height: 700,
        child: DodoInlineCheckout(checkoutUrl: Uri.parse(checkoutUrl)),
      ),
    ),
  ],
);
```

Giving the widget a new `checkoutUrl` opens that session in its place. It closes its checkout when removed from the tree, so keep it out of lazy lists such as `ListView.builder`: scrolling it out of view would dispose it and lose the customer's input. A widget that isn't painted yet, for example in a hidden tab, opens its checkout once it is shown.

Tax is unknown until the customer enters an address, so amounts can be `null` early on. Show `finalTotal` as the price: it is what the customer is charged and can be in a different currency from the other amounts.

Dodo requires the whole checkout frame, including its legal footer, to stay reachable.

## Customizing the checkout

```dart
CheckoutOptions(
  checkoutUrl: url,
  settings: const CheckoutSettings(
    showTimer: false,
    showSecurityBadge: true,
    payButtonText: 'Pay now',
    fontSize: CheckoutFontSize.lg,
    fontWeight: CheckoutFontWeight.medium,
    manualRedirect: true,
  ),
);
```

Colours and themes are not set here. They belong to the session your backend creates (`customization.theme_config`) or to the Design page of the Dodo dashboard.

## Events

| Event | When |
| --- | --- |
| `CheckoutOpened` | The checkout frame loaded |
| `CheckoutFormReady` | The form is ready for input |
| `CheckoutPaymentPageOpened` | The payment page is displayed |
| `CheckoutCustomerDetailsSubmitted` | Customer and billing details were submitted |
| `CheckoutPayButtonClicked` | The customer clicked pay |
| `CheckoutBreakdownChanged` | Prices, tax or discounts changed |
| `CheckoutRedirecting` | The checkout is navigating, for example to a bank page |
| `CheckoutStatusChanged` | Payment outcome, with `manualRedirect` |
| `CheckoutRedirectRequested` | The app should navigate, with `manualRedirect` |
| `CheckoutLinkExpired` | The session expired, only with `showTimer: false` |
| `CheckoutClosed` | The checkout closed |
| `CheckoutFailed` | An error occurred |
| `CheckoutUnknownEvent` | Any event this package has no type for |

Every event has `type` and `raw`, the event as Dodo sent it. Dodo doesn't document the `checkout.status` and `checkout.redirect_requested` payloads, so read `raw` if the typed fields are `null`. Include a default case when you switch over events, because new types may be added.

The stream has no replay: events emitted while nobody listens are dropped.

## After the checkout

By default, a finished checkout navigates the whole page to the session's `return_url`, which restarts your Flutter app. Read the result when the app starts:

```dart
final result = CheckoutReturnResult.fromUri(Uri.base);
if (result != null) {
  // Show a "confirming your payment" page.
}
```

`CheckoutReturnStatus` tells you what the URL reported. Anyone can edit a URL, so use it only to choose what to show.

`fromUri` never throws, and returns `null` for URLs that aren't checkout returns. A return URL has a `payment_id` or `subscription_id`; a `failed` or `expired` status alone is also accepted. Pointing `return_url` at a dedicated page of your app avoids mistaking another page's parameters for a checkout result.

To stay in the app instead, set `manualRedirect: true` and handle `CheckoutRedirectRequested` yourself.

## Confirming payment with your backend

Dodo sends webhooks to your backend, not to the browser. `PaymentConfirmation` polls your backend until the payment is final. You supply the function that asks your backend, so the package makes no HTTP calls.

```dart
final confirmation = PaymentConfirmation<OrderStatus>(
  fetchStatus: myApi.getOrderStatus,
  isFinal: (status) => status.isPaid || status.isFailed,
  policy: const PollingPolicy(timeout: Duration(minutes: 3)),
);

// Use options.sessionId while still in the app, or result.id after a return.
final status = await confirmation.waitFor(result.id!);
```

It fails with `PaymentConfirmationTimeoutException` if the payment isn't final within the policy's limits. Use `watch` instead of `waitFor` to receive every status as it arrives.

## Amounts

Dodo reports amounts in a currency's smallest unit. `DodoAmount` knows each currency's decimal places, so never divide by 100 yourself:

```dart
const DodoAmount(minorUnits: 1999, currency: 'USD').toDecimalString(); // 19.99
const DodoAmount(minorUnits: 1999, currency: 'JPY').toDecimalString(); // 1999
const DodoAmount(minorUnits: 1999, currency: 'KWD').toDecimalString(); // 1.999
```

## Error handling

Errors the package raises extend `DodoException`. Two exceptions: `PaymentConfirmation` passes on errors from your own `fetchStatus` when `retryOnError` is `false`, and throws `ArgumentError` for an empty id or an invalid `PollingPolicy`.

| Exception | When |
| --- | --- |
| `DodoNotInitializedException` | `Dodo.instance` was used before `Dodo.initialize` completed |
| `DodoConfigurationException` | The configuration is invalid, or `Dodo.initialize` was called again in another mode |
| `DodoValidationException` | The checkout URL or options are invalid. Nothing was sent to Dodo |
| `DodoUnsupportedPlatformException` | The app is not running on web |
| `DodoScriptLoadException` | The checkout SDK could not be loaded |
| `DodoJsException` | The checkout SDK rejected a call |
| `PaymentConfirmationTimeoutException` | The payment wasn't final within the polling limits |

Errors from a checkout that is already open arrive as `CheckoutFailed` events. `DodoInlineCheckout` reports open failures through `onError`, or through `FlutterError.reportError` without it.

## Limitations

- Each page has one checkout at a time. Opening another closes the first, which emits `CheckoutClosed`. An inline checkout closed this way is not reopened when the other one closes; give its widget a new session URL.
- Apple Pay isn't available in overlay checkout, and inline needs domain verification in the Dodo dashboard.
- Dodo's static `/buy/...` payment links can't be opened in overlay or inline, and `open` rejects them with `DodoValidationException`. Use a checkout session, or redirect the browser to the link.

## Testing

`DodoPlatform` is an interface, so tests can replace the SDK. Implement it only for test fakes: members may be added in minor releases.

```dart
await Dodo.initialize(config, platform: MyFakeDodoPlatform());
```

The package's own tests run on the VM with `flutter test`. The web platform layer has browser tests, run with `flutter test --platform chrome test/web`.

## Security notes

- Keep API keys and webhook secrets on your backend.
- Let the app send a plan name, not a price or product id, and map it to an allowed product on the backend.
- Treat events and return URLs as hints. Grant access only from verified webhooks.

## Example

[`example/`](example) is a small app with overlay and inline checkout, an order summary, a raw event log and a return page.

## License

MIT
