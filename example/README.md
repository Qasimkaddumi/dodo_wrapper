# dodo_wrapper example

A small Flutter web app that demonstrates the `dodo_wrapper` package:

| Demo | What it shows |
| --- | --- |
| Checkout page | Overlay checkout, inline checkout with `DodoInlineCheckout`, an order summary built with `DodoCheckoutBuilder`, manual redirects, and a log of every raw event. |
| Return page | Reading the return URL with `CheckoutReturnResult`, then waiting for your backend with `PaymentConfirmation`. The backend here is a fake. |

## Run it

The package is client-side only, so you need a checkout session created by your
backend. In Dodo's **test mode**, create a session with `return_url` set to
`http://localhost:5000/`, and copy its `checkout_url`.

```sh
flutter run -d chrome --web-port 5000
```

Paste the URL into the app and open it. Each session URL works once, so create
a new one for every attempt.

Optional values:

```sh
--dart-define=CHECKOUT_URL=https://test.checkout.dodopayments.com/session/cks_xxx
--dart-define=DODO_MODE=live
```

The mode defaults to `test` and must match the backend that created the
session. Never put a Dodo API key in an app: it would ship to every browser.

## Where to look

```text
lib/
  main.dart                       chooses the checkout or return page
  app.dart                        Dodo.initialize, startup errors, theme
  config/app_config.dart          --dart-define values
  features/
    checkout/checkout_page.dart   overlay and inline checkout demo
    checkout/order_summary.dart   DodoCheckoutBuilder
    checkout/event_log.dart       raw event log
    confirmation/return_page.dart return URL and backend polling
    confirmation/order_backend.dart  the fake backend
```

`features/confirmation/order_backend.dart` explains how the fake should be
replaced with a real backend call. Read it before you copy this example into a
product.
