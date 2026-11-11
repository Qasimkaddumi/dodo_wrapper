import 'dart:async';

import 'package:dodo_wrapper/dodo_wrapper.dart';

/// In-memory [DodoPlatform] that records calls, for unit tests.
class FakeDodoPlatform implements DodoPlatform {
  /// Every call as `(methodName, argument)`, in order.
  final List<(String, Object?)> calls = [];

  /// When set, [open] emits [eventDuringOpen] (if any) and then throws this.
  Object? openError;

  /// Raw event emitted synchronously from inside [open].
  JsonMap? eventDuringOpen;

  /// Error thrown by [load].
  Object? loadError;

  /// When set, [whenFrameHostReady] waits for this to complete.
  Completer<void>? frameHostGate;

  DodoEventHandler? _onEvent;

  @override
  bool isSupported = true;

  @override
  bool isLoaded = false;

  @override
  bool isOpen = false;

  /// Simulates the SDK emitting [event].
  void emit(JsonMap event) => _onEvent?.call(event);

  /// Arguments of every call to [method].
  List<Object?> argsOf(String method) => [
    for (final call in calls)
      if (call.$1 == method) call.$2,
  ];

  /// Names of every call, in order.
  List<String> get callNames => [for (final call in calls) call.$1];

  @override
  Future<void> load(Uri scriptUrl, {required Duration timeout}) async {
    calls.add(('load', scriptUrl));
    final error = loadError;
    if (error != null) throw error;
    isLoaded = true;
  }

  @override
  void initialize(JsonMap options, DodoEventHandler onEvent) {
    calls.add(('initialize', options));
    _onEvent = onEvent;
  }

  @override
  void open(JsonMap options) {
    calls.add(('open', options));
    final event = eventDuringOpen;
    if (event != null) emit(event);
    final error = openError;
    if (error != null) throw error;
    isOpen = true;
  }

  @override
  void close() {
    calls.add(('close', null));
    isOpen = false;
  }

  @override
  void prepareFrameHost(Object element, {required String elementId}) =>
      calls.add(('prepareFrameHost', elementId));

  @override
  Future<bool> whenFrameHostReady(
    String elementId, {
    required bool Function() isCancelled,
  }) async {
    calls.add(('whenFrameHostReady', elementId));
    await frameHostGate?.future;
    return !isCancelled();
  }
}
