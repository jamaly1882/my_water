import 'package:flutter/material.dart';

Future<String?> readNumberImpl({
  BuildContext? context,
  int? previousReading,
}) async {
  throw UnsupportedError(
    'Meter reading by photo is not available on this platform.',
  );
}
