/// Prepares page elements that host an inline checkout.
abstract interface class DodoFrameHost {
  /// Prepares [element], created by an `HtmlElementView`, to host an inline
  /// checkout: assigns [elementId] and sizing styles.
  void prepareFrameHost(Object element, {required String elementId});

  /// Waits until the element with [elementId] is attached to the document,
  /// so the checkout SDK can find it.
  ///
  /// There is no timeout: a host that is not painted yet, for example in a
  /// hidden tab, joins the page once it is shown. Completes with `false`
  /// once [isCancelled] returns `true`.
  Future<bool> whenFrameHostReady(
    String elementId, {
    required bool Function() isCancelled,
  });
}
