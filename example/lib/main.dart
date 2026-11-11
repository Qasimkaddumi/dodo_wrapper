import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/checkout/checkout_page.dart';
import 'features/confirmation/return_page.dart';

void main() {
  // After a checkout, Dodo sends the browser back to the session's return_url
  // with the result on the URL. That is a fresh start of this app.
  final result = CheckoutReturnResult.fromUri(Uri.base);
  runApp(
    ExampleApp(
      home: result == null ? const CheckoutPage() : ReturnPage(result: result),
    ),
  );
}
