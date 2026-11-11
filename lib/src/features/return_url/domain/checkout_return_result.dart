/// Payment status reported on a checkout return URL.
enum CheckoutReturnStatus {
  /// A one-time payment succeeded.
  succeeded,

  /// A subscription is active.
  active,

  /// The payment was declined.
  failed,

  /// The payment settles later.
  processing,

  /// The payment needs more customer or processor action (`requires_*`).
  requiresAction,

  /// The session expired.
  expired,

  /// Missing or unrecognised. Wait for your backend to confirm the outcome.
  unknown,
}

/// What Dodo appended to the session's `return_url` after a checkout.
///
/// This is a UI hint and anyone can edit a URL. Use it to choose what to show
/// while your backend confirms the payment, and never to grant access.
///
/// ```dart
/// final result = CheckoutReturnResult.fromUri(Uri.base);
/// if (result != null) showPaymentPendingPage(result);
/// ```
class CheckoutReturnResult {
  /// Creates a result.
  const CheckoutReturnResult({
    required this.status,
    this.rawStatus,
    this.paymentId,
    this.subscriptionId,
    this.email,
    this.licenseKeys = const [],
  });

  /// Reads a result from [uri], or returns `null` when it is not a checkout
  /// return URL. Never throws.
  ///
  /// A return URL has a `payment_id` or `subscription_id`. A `failed` or
  /// `expired` status alone is also accepted.
  ///
  /// Parameters are read from the query and from a hash route's query, so
  /// both `/success?status=...` and `/#/success?status=...` work.
  static CheckoutReturnResult? fromUri(Uri uri) {
    final parameters = _parameters(uri);
    final rawStatus = parameters['status'];
    final status = _parseStatus(rawStatus);
    final paymentId = parameters['payment_id'];
    final subscriptionId = parameters['subscription_id'];
    // A bare `status` is too common to identify a return URL: an app page
    // such as `/users?status=active` would look like a successful checkout.
    // Only outcomes that can arrive without an id are accepted alone.
    final hasId = paymentId != null || subscriptionId != null;
    final isIdlessOutcome =
        status == CheckoutReturnStatus.expired ||
        status == CheckoutReturnStatus.failed;
    if (!hasId && !isIdlessOutcome) return null;

    return CheckoutReturnResult(
      status: status,
      rawStatus: rawStatus,
      paymentId: paymentId,
      subscriptionId: subscriptionId,
      email: parameters['email'],
      licenseKeys: [
        for (final key in (parameters['license_key'] ?? '').split(','))
          if (key.trim().isNotEmpty) key.trim(),
      ],
    );
  }

  /// The reported status.
  final CheckoutReturnStatus status;

  /// The status exactly as it appeared on the URL.
  final String? rawStatus;

  /// Id of the payment, for one-time purchases.
  final String? paymentId;

  /// Id of the subscription, for subscription purchases.
  final String? subscriptionId;

  /// The customer's email, when on record.
  final String? email;

  /// License keys issued for the purchase.
  final List<String> licenseKeys;

  /// The payment or subscription id, for asking your backend about it.
  String? get id => paymentId ?? subscriptionId;

  /// Reads the query and a hash route's query. This runs on whatever URL the
  /// app starts with, so a malformed parameter is skipped rather than thrown:
  /// `Uri.queryParameters` throws on invalid UTF-8 such as `%FF`.
  static Map<String, String> _parameters(Uri uri) {
    final fragment = uri.fragment;
    final start = fragment.indexOf('?');
    return {
      ..._decodeQuery(uri.query),
      if (start >= 0) ..._decodeQuery(fragment.substring(start + 1)),
    };
  }

  static Map<String, String> _decodeQuery(String query) {
    final parameters = <String, String>{};
    for (final pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final split = pair.indexOf('=');
      final key = _decode(split < 0 ? pair : pair.substring(0, split));
      final value = split < 0 ? '' : _decode(pair.substring(split + 1));
      if (key != null && value != null) parameters[key] = value;
    }
    return parameters;
  }

  static String? _decode(String component) {
    try {
      return Uri.decodeQueryComponent(component);
    } on FormatException {
      return null;
    }
  }

  static CheckoutReturnStatus _parseStatus(String? raw) => switch (raw) {
    'succeeded' => CheckoutReturnStatus.succeeded,
    'active' => CheckoutReturnStatus.active,
    'failed' => CheckoutReturnStatus.failed,
    'processing' => CheckoutReturnStatus.processing,
    'expired' => CheckoutReturnStatus.expired,
    final String value when value.startsWith('requires_') =>
      CheckoutReturnStatus.requiresAction,
    _ => CheckoutReturnStatus.unknown,
  };
}
