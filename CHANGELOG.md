## 0.1.0

* Initial release for Flutter web.
* `Dodo.initialize` loads and initializes the Dodo checkout SDK (`DodoConfig`), pinned to `dodopayments-checkout` 2.1.0.
* Overlay and inline checkout from a backend-created session URL with `Dodo.instance.checkout.open`, plus `close`, `isOpen` and `currentOptions`.
* `DodoInlineCheckout` embeds a checkout in the widget tree, and `DodoCheckoutBuilder` exposes live `CheckoutState` for custom order summaries.
* Typed `CheckoutEvent` subclasses with lenient parsing of unknown events and undocumented payloads.
* `CheckoutBreakdown` and `DodoAmount`, with correct handling of zero-decimal and three-decimal currencies.
* `CheckoutReturnResult` reads the checkout return URL, including from hash routes.
* `PaymentConfirmation` and `PollingPolicy` for waiting on your backend to confirm a payment.
* Checkout URL validation: rejects non-https URLs, non-Dodo hosts and URLs from the wrong mode.
* Typed exception hierarchy rooted at `DodoException`.
* `DodoPlatform` bridge, so tests and future platforms can replace the SDK implementation.
* Example app in `example/`.
