import '../../../core/dodo_exception.dart';

/// Thrown when a payment is not confirmed within the polling budget of a
/// `PollingPolicy` (timeout or `maxAttempts`).
class PaymentConfirmationTimeoutException extends DodoException {
  /// Creates the exception.
  const PaymentConfirmationTimeoutException({
    required this.id,
    required this.attempts,
    this.lastStatus,
  }) : super('$id was not confirmed after $attempts attempt(s).');

  /// The id that was being polled.
  final String id;

  /// How many fetches were made before giving up.
  final int attempts;

  /// The last status returned by the fetcher, or `null` if every fetch
  /// failed.
  final Object? lastStatus;
}
