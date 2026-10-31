import 'package:flutter/material.dart';

import 'meter_analysis.dart';

/// بديل يُستخدم على المنصات التي لا تدعم dart:io
Future<MeterReadingResult?> readNumberImpl({
  BuildContext? context,
  int? previousReading,
  bool preferAi = true,
}) async {
  throw UnsupportedError(
    'قراءة العداد بهذه الطريقة غير متاحة على هذه المنصة.',
  );
}
