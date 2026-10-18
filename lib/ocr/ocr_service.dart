import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ocr_mobile_stub.dart'
    if (dart.library.io) 'ocr_mobile.dart' as mobile;

import 'ocr_web_stub.dart'
    if (dart.library.html) 'ocr_web.dart' as web;

class OCRService {
  OCRService._();

  static Future<String?> readNumber(
    BuildContext context, {
    int? previousReading,
  }) async {
    if (kIsWeb) {
      return Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => web.OcrWebPage(
            previousReading: previousReading,
          ),
        ),
      );
    }

    return mobile.readNumberImpl(
      context: context,
      previousReading: previousReading,
    );
  }
}
