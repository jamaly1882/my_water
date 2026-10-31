import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'meter_analysis.dart';

import 'ocr_mobile_stub.dart'
    if (dart.library.io) 'ocr_mobile.dart' as mobile;

import 'ocr_web_stub.dart'
    if (dart.library.html) 'ocr_web.dart' as web;

/// ============================================================
/// خدمة قراءة العداد الموحّدة
///
/// المسار:
/// تصوير / اختيار صورة -> قص نافذة الأرقام السبعة ->
/// قراءة بالذكاء الاصطناعي (AI Vision) ->
/// وإذا تعذّر: قراءة محلية على الجهاز ->
/// ثم نافذة مراجعة وتأكيد.
///
/// تُرجع القراءة مع المحرّك الذي أنتجها.
/// ============================================================

class OCRService {
  OCRService._();

  static Future<MeterReadingResult?> readNumber(
    BuildContext context, {
    int? previousReading,
    bool preferAi = true,
  }) async {
    if (kIsWeb) {
      final String? reading =
          await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (_) => web.OcrWebPage(
            previousReading: previousReading,
            preferAi: preferAi,
          ),
        ),
      );

      if (reading == null || reading.trim().isEmpty) {
        return null;
      }

      // صفحة الويب تُرجع القراءة مع محرّكها عبر وسم في نهاية النص
      final WebReadingResult parsed = _parseWebResult(reading);

      return MeterReadingResult(
        reading: parsed.reading,
        engine: parsed.engine,
      );
    }

    return mobile.readNumberImpl(
      context: context,
      previousReading: previousReading,
      preferAi: preferAi,
    );
  }

  // ==========================================================
  // فك وسم صفحة الويب
  //
  // الصيغة: "0650040|ai" أو "0650040|local"
  // ==========================================================

  static WebReadingResult _parseWebResult(String raw) {
    final List<String> parts = raw.split('|');

    final String reading = parts.first.trim();

    if (parts.length > 1 && parts[1].trim() == 'ai') {
      return WebReadingResult(
        reading: reading,
        engine: OcrEngine.aiVision,
      );
    }

    return WebReadingResult(
      reading: reading,
      engine: OcrEngine.local,
    );
  }
}

/// نتيجة قراءة من صفحة الويب
class WebReadingResult {
  final String reading;
  final OcrEngine engine;

  const WebReadingResult({
    required this.reading,
    required this.engine,
  });
}
