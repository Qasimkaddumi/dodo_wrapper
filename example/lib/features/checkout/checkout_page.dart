import 'dart:async';

import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../config/app_config.dart';
import 'event_log.dart';
import 'order_summary.dart';

/// Opens a checkout session as an overlay or inline.
class CheckoutPage extends StatefulWidget {
  /// Creates the page.
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _urlField = TextEditingController(text: AppConfig.checkoutUrl);
  final _events = <CheckoutEvent>[];
  late final StreamSubscription<CheckoutEvent> _subscription;

  bool _manualRedirect = false;
  Uri? _inlineUrl;
  String? _error;

  CheckoutSettings get _settings =>
      CheckoutSettings(manualRedirect: _manualRedirect ? true : null);

  @override
  void initState() {
    super.initState();
    // Subscribe before opening a checkout, so no event is missed.
    _subscription = Dodo.instance.events.listen(_onEvent);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _urlField.dispose();
    super.dispose();
  }

  void _onEvent(CheckoutEvent event) {
    setState(() => _events.insert(0, event));
    // With manualRedirect the SDK leaves navigation to the app.
    if (event case CheckoutRedirectRequested(:final redirectUrl?)) {
      web.window.location.href = redirectUrl.toString();
    }
  }

  Uri? _readUrl() {
    final url = Uri.tryParse(_urlField.text.trim());
    if (url == null || !url.hasScheme) {
      setState(() => _error = 'Enter a checkout URL from your backend.');
      return null;
    }
    setState(() => _error = null);
    return url;
  }

  Future<void> _openOverlay() async {
    final url = _readUrl();
    if (url == null) return;
    setState(() => _inlineUrl = null);
    try {
      await Dodo.instance.checkout.open(
        CheckoutOptions(checkoutUrl: url, settings: _settings),
      );
    } on DodoException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _openInline() {
    final url = _readUrl();
    if (url != null) setState(() => _inlineUrl = url);
  }

  void _close() {
    Dodo.instance.checkout.close();
    setState(() => _inlineUrl = null);
  }

  @override
  Widget build(BuildContext context) {
    final inlineUrl = _inlineUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('dodo_wrapper example')),
      // Not a ListView: a lazy list disposes children scrolled out of view,
      // and an inline checkout that is disposed closes, losing its input.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlField,
              decoration: const InputDecoration(
                labelText: 'checkout_url from your backend (single use)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manual redirect'),
              subtitle: const Text('Applies to the next checkout opened'),
              value: _manualRedirect,
              onChanged: (value) => setState(() => _manualRedirect = value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _openOverlay,
                  child: const Text('Open overlay'),
                ),
                FilledButton.tonal(
                  onPressed: _openInline,
                  child: const Text('Open inline'),
                ),
                OutlinedButton(onPressed: _close, child: const Text('Close')),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            const OrderSummary(),
            if (inlineUrl != null) ...[
              const SizedBox(height: 16),
              // An inline checkout needs a bounded height.
              SizedBox(
                height: 700,
                child: DodoInlineCheckout(
                  checkoutUrl: inlineUrl,
                  settings: _settings,
                  onError: (error) => setState(() => _error = '$error'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            EventLog(events: _events),
          ],
        ),
      ),
    );
  }
}
