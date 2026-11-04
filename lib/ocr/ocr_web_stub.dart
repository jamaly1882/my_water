import 'package:flutter/material.dart';

class OcrWebPage extends StatelessWidget {
  final int? previousReading;

  const OcrWebPage({
    super.key,
    this.previousReading,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Photo meter reading is not supported on this platform.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
