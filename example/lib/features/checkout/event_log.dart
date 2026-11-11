import 'dart:convert';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';

/// Shows every checkout event with its raw data, newest first.
class EventLog extends StatelessWidget {
  /// Creates the log.
  const EventLog({required this.events, super.key});

  /// The events to show.
  final List<CheckoutEvent> events;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Events', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (events.isEmpty) const Text('None yet.'),
      for (final event in events)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SelectableText(
            '${event.type}  ${jsonEncode(event.raw['data'])}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
    ],
  );
}
