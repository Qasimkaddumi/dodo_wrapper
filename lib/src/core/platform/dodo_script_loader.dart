/// Makes the Dodo checkout SDK available on the page.
abstract interface class DodoScriptLoader {
  /// Whether the checkout SDK can run on this platform.
  bool get isSupported;

  /// Whether the checkout SDK is present on the page.
  bool get isLoaded;

  /// Injects the SDK script from [scriptUrl] unless it is already loaded, and
  /// completes once the SDK is available.
  Future<void> load(Uri scriptUrl, {required Duration timeout});
}
