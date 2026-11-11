import 'package:dodo_wrapper/dodo_wrapper.dart';
import 'package:flutter/material.dart';

import 'config/app_config.dart';

/// Initializes Dodo, then shows [home].
class ExampleApp extends StatefulWidget {
  /// Creates the app.
  const ExampleApp({required this.home, super.key});

  /// The page to show once Dodo is ready.
  final Widget home;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final Future<Dodo> _initialization = Dodo.initialize(
    DodoConfig(mode: AppConfig.mode),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'dodo_wrapper example',
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF3B6D11),
      useMaterial3: true,
    ),
    home: FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.home;
      },
    ),
  );
}
