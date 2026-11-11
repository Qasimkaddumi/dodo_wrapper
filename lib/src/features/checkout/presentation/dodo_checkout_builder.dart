import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../dodo.dart';
import '../domain/entities/checkout_event.dart';
import '../domain/entities/checkout_state.dart';

/// Builds UI from the live state of the Dodo checkout.
///
/// Pair it with `DodoInlineCheckout` to design your own checkout page: Dodo
/// renders the payment form, you render everything else.
///
/// ```dart
/// DodoCheckoutBuilder(
///   builder: (context, state) =>
///       Text(state.breakdown?.finalTotal?.toString() ?? '—'),
/// )
/// ```
class DodoCheckoutBuilder extends StatefulWidget {
  /// Creates the builder.
  const DodoCheckoutBuilder({
    required this.builder,
    this.events,
    this.onEvent,
    super.key,
  });

  /// Called with the latest [CheckoutState] whenever it changes.
  final Widget Function(BuildContext context, CheckoutState state) builder;

  /// Event source. Defaults to `Dodo.instance.events`.
  final Stream<CheckoutEvent>? events;

  /// Optional side-effect hook for every event, e.g. navigation on redirect.
  final ValueChanged<CheckoutEvent>? onEvent;

  @override
  State<DodoCheckoutBuilder> createState() => _DodoCheckoutBuilderState();
}

class _DodoCheckoutBuilderState extends State<DodoCheckoutBuilder> {
  CheckoutState _state = const CheckoutState();
  StreamSubscription<CheckoutEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(DodoCheckoutBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      unawaited(_subscription?.cancel());
      _subscribe();
    }
  }

  void _subscribe() {
    final events = widget.events ?? Dodo.instance.events;
    _subscription = events.listen((event) {
      widget.onEvent?.call(event);
      if (mounted) setState(() => _state = _state.apply(event));
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
