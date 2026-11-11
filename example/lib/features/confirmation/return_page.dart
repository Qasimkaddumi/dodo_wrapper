import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';

import 'order_backend.dart';

/// Shown when the browser returns from a checkout.
class ReturnPage extends StatefulWidget {
  /// Creates the page.
  const ReturnPage({required this.result, super.key});

  /// What Dodo appended to the return URL.
  final CheckoutReturnResult result;

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  late final Future<OrderState>? _confirmation;

  @override
  void initState() {
    super.initState();
    final id = widget.result.id;
    _confirmation = id == null
        ? null
        : PaymentConfirmation<OrderState>(
            fetchStatus: FakeOrderBackend().fetchOrderState,
            isFinal: (state) => state != OrderState.pending,
          ).waitFor(id);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout finished')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The URL only decides what to show while the backend confirms.
            Text('Return URL says: ${result.rawStatus ?? 'unknown'}'),
            Text('Id: ${result.id ?? '—'}'),
            const SizedBox(height: 16),
            if (_confirmation != null)
              FutureBuilder(
                future: _confirmation,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Not confirmed: ${snapshot.error}');
                  }
                  final state = snapshot.data;
                  return Text(
                    state == null
                        ? 'Waiting for the backend to confirm…'
                        : 'Backend says: ${state.name} (fake backend)',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
