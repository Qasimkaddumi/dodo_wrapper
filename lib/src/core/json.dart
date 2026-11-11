/// A decoded JSON object.
typedef JsonMap = Map<String, dynamic>;

/// Returns a copy of [json] without `null` values, so optional fields are
/// omitted rather than sent as `null` to the Dodo checkout SDK.
JsonMap compactJson(Map<String, Object?> json) => {
  for (final entry in json.entries)
    if (entry.value != null) entry.key: entry.value,
};

/// Read helpers for loosely typed JSON coming back from the checkout SDK.
///
/// Every reader returns `null` for missing or malformed values instead of
/// throwing, so an unexpected payload can never break the event stream.
extension JsonMapReader on JsonMap {
  /// Reads a string, or `null`. Numbers and bools are stringified; objects
  /// and lists are treated as malformed and yield `null`.
  String? stringOrNull(String key) => switch (this[key]) {
    final String value => value,
    final num value => value.toString(),
    final bool value => value.toString(),
    _ => null,
  };

  /// Reads a finite number as an int, or `null`. Accepts numeric strings.
  int? intOrNull(String key) {
    final value = this[key];
    final number = value is String ? num.tryParse(value) : value;
    return number is num && number.isFinite ? number.toInt() : null;
  }

  /// Reads a nested object, or `null`.
  JsonMap? mapOrNull(String key) {
    final value = this[key];
    return value is Map ? value.cast<String, dynamic>() : null;
  }
}
