import 'package:flutter/foundation.dart';

import 'payment_confirmation_exception.dart';
import 'polling_policy.dart';

/// Fetches the current status of a payment from the app's own backend.
typedef PaymentStatusFetcher<T> = Future<T> Function(String id);

/// Returns `true` when [status] is final and polling can stop.
typedef PaymentStatusPredicate<T> = bool Function(T status);

/// Polls the app's backend until a payment reaches a final status.
///
/// Dodo sends webhooks to your backend, not to the client, so after a
/// checkout the app has to wait until its backend reflects the payment. This
/// class performs no HTTP itself: you supply the [fetchStatus] function, and
/// choose which id it takes. That is usually `CheckoutOptions.sessionId` or
/// `CheckoutReturnResult.id`.
///
/// ```dart
/// final confirmation = PaymentConfirmation<OrderStatus>(
///   fetchStatus: myApi.getOrderStatus,
///   isFinal: (status) => status.isPaid || status.isFailed,
/// );
/// final status = await confirmation.waitFor(options.sessionId!);
/// ```
class PaymentConfirmation<T> {
  /// Creates a confirmation helper.
  ///
  /// [delay] and [clock] exist for tests and default to real time.
  PaymentConfirmation({
    required this.fetchStatus,
    required this.isFinal,
    this.policy = const PollingPolicy(),
    @visibleForTesting Future<void> Function(Duration)? delay,
    @visibleForTesting DateTime Function()? clock,
  }) : _delay = delay ?? ((duration) => Future<void>.delayed(duration)),
       _clock = clock ?? DateTime.now {
    // Duration comparisons cannot run in PollingPolicy's const constructor.
    if (policy.initialInterval <= Duration.zero ||
        policy.maxInterval <= Duration.zero ||
        policy.timeout <= Duration.zero) {
      throw ArgumentError.value(
        policy,
        'policy',
        'initialInterval, maxInterval and timeout must be positive',
      );
    }
  }

  /// Fetches the current status of a payment.
  final PaymentStatusFetcher<T> fetchStatus;

  /// Decides whether a status ends polling.
  final PaymentStatusPredicate<T> isFinal;

  /// Controls the delays, retries and timeout.
  final PollingPolicy policy;

  final Future<void> Function(Duration) _delay;
  final DateTime Function() _clock;

  /// Emits every status of [id] as it is fetched, then closes after the
  /// first final status.
  ///
  /// The stream fails with a [PaymentConfirmationTimeoutException] when the
  /// policy's timeout or `maxAttempts` is reached first. Cancelling the
  /// subscription stops polling.
  ///
  /// Throws an [ArgumentError] synchronously when [id] is empty.
  Stream<T> watch(String id) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    return _poll(id);
  }

  /// Completes with the first final status of [id].
  ///
  /// Fails like [watch] on timeout or on a fetch error when
  /// `policy.retryOnError` is `false`.
  Future<T> waitFor(String id) async => watch(id).firstWhere(isFinal);

  Stream<T> _poll(String id) async* {
    final deadline = _clock().add(policy.timeout);
    var attempt = 0;
    T? lastStatus;
    while (true) {
      attempt++;
      final fetched = await _tryFetch(id, deadline.difference(_clock()));
      if (fetched != null) {
        final status = fetched.status;
        lastStatus = status;
        yield status;
        if (isFinal(status)) return;
      }

      final now = _clock();
      final outOfAttempts =
          policy.maxAttempts != null && attempt >= policy.maxAttempts!;
      if (outOfAttempts || !now.isBefore(deadline)) {
        throw PaymentConfirmationTimeoutException(
          id: id,
          attempts: attempt,
          lastStatus: lastStatus,
        );
      }

      // Never sleep past the deadline; the next fetch happens at most at it.
      final remaining = deadline.difference(now);
      final wait = policy.delayAfter(attempt);
      await _delay(wait < remaining ? wait : remaining);
    }
  }

  /// Fetches once. Returns `null` when the fetch failed and the error was
  /// swallowed for a retry; rethrows when `policy.retryOnError` is `false`.
  ///
  /// A fetch still running at the deadline is abandoned and counts as a
  /// failed attempt, so a stalled request cannot outlast the timeout.
  Future<({T status})?> _tryFetch(String id, Duration remaining) async {
    try {
      final status = await fetchStatus(
        id,
      ).timeout(remaining, onTimeout: () => throw const _DeadlineReached());
      return (status: status);
    } on _DeadlineReached {
      return null;
    } on Object catch (error, stackTrace) {
      if (!policy.retryOnError) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      return null;
    }
  }
}

/// Thrown internally when a fetch outlasts the polling deadline.
class _DeadlineReached implements Exception {
  const _DeadlineReached();
}
