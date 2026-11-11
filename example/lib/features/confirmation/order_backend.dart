/// Lifecycle of an order as your backend sees it.
enum OrderState {
  /// The webhook has not arrived yet.
  pending,

  /// The backend received a verified success webhook.
  paid,

  /// The backend received a verified failure webhook.
  failed,
}

/// The API of YOUR backend, as far as this example is concerned.
abstract interface class OrderBackend {
  /// Returns the state of the order for a Dodo payment or subscription [id].
  Future<OrderState> fetchOrderState(String id);
}

/// A fake backend so the example runs without a server.
///
/// In production, implement [OrderBackend] with an HTTP call to YOUR backend.
/// Your backend is the system of record: it marks the order as paid when it
/// receives a verified webhook such as `payment.succeeded` or
/// `subscription.active`. Dodo sends webhooks to your server, not to the
/// browser. The Flutter app only asks "is this order paid yet?".
///
/// Never grant access based on client-side events or the return URL. The
/// browser can be closed, and anyone can edit a URL.
///
/// This fake answers "pending" for the first [pendingCalls] requests, then
/// "paid", to simulate the webhook arriving a few seconds later.
class FakeOrderBackend implements OrderBackend {
  /// Creates the fake.
  FakeOrderBackend({this.pendingCalls = 3});

  /// How many requests answer "pending" before "paid".
  final int pendingCalls;

  int _calls = 0;

  @override
  Future<OrderState> fetchOrderState(String id) async {
    // Simulate network latency.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _calls++;
    return _calls > pendingCalls ? OrderState.paid : OrderState.pending;
  }
}
