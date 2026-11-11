import '../../../../core/dodo_exception.dart';
import 'checkout_enums.dart';
import 'checkout_settings.dart';

/// What to open and how to present it.
class CheckoutOptions {
  /// Creates options for the session at [checkoutUrl].
  ///
  /// The checkout opens as an overlay unless [elementId] is given, in which
  /// case it is embedded in the page element with that id.
  const CheckoutOptions({
    required this.checkoutUrl,
    this.elementId,
    this.settings,
  });

  /// The `checkout_url` your backend received when it created the session.
  /// Session URLs are single-use: create a new session for each attempt.
  final Uri checkoutUrl;

  /// Id of the page element an inline checkout renders into.
  final String? elementId;

  /// Client-side presentation options.
  final CheckoutSettings? settings;

  /// How this checkout is presented.
  CheckoutDisplayType get displayType => elementId == null
      ? CheckoutDisplayType.overlay
      : CheckoutDisplayType.inline;

  /// The checkout session id (`cks_...`) in [checkoutUrl], or `null` when the
  /// URL has none. Useful for asking your backend about this session.
  String? get sessionId {
    final segments = checkoutUrl.pathSegments;
    if (segments.isEmpty || !segments.last.startsWith('cks_')) return null;
    return segments.last;
  }

  /// Throws [DodoValidationException] when the options cannot work.
  void validate() {
    if (elementId != null && elementId!.trim().isEmpty) {
      throw const DodoValidationException('elementId must not be empty.');
    }
  }
}
