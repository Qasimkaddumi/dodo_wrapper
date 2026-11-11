import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';

/// An order summary rendered by the app from live checkout events.
class OrderSummary extends StatelessWidget {
  /// Creates the summary.
  const OrderSummary({super.key});

  @override
  Widget build(BuildContext context) => DodoCheckoutBuilder(
    builder: (context, state) {
      final breakdown = state.breakdown;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${state.phase.name}'),
              if (state.errorMessage != null) Text(state.errorMessage!),
              const Divider(),
              _row('Subtotal', breakdown?.subTotal),
              _row('Discount', breakdown?.discount),
              // Tax is unknown until the customer enters an address.
              _row('Tax', breakdown?.tax),
              _row('You pay', breakdown?.finalTotal),
            ],
          ),
        ),
      );
    },
  );

  Widget _row(String label, DodoAmount? amount) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(label), Text(amount?.toString() ?? '—')],
  );
}
