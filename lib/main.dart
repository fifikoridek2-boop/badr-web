import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      runApp(_ErrorApp(details.exceptionAsString(), details.stack.toString()));
    };

    runApp(const _TestApp());
  }, (error, stack) {
    runApp(_ErrorApp(error.toString(), stack.toString()));
  });
}

// تطبيق تجريبي بسيط جداً بدون أي packages
class _TestApp extends StatelessWidget {
  const _TestApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.green,
        body: Center(
          child: Text(
            'Flutter يعمل ✅',
            style: TextStyle(color: Colors.white, fontSize: 28),
          ),
        ),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String error, stack;
  const _ErrorApp(this.error, this.stack);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔴 CRASH', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(error, style: const TextStyle(color: Colors.yellowAccent, fontSize: 13, fontFamily: 'monospace')),
                const SizedBox(height: 8),
                SelectableText(
                  stack.length > 2000 ? stack.substring(0, 2000) : stack,
                  style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
