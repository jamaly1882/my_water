// ============================================================
// ai_meter_ocr.dart
// قراءة عداد المياه عبر نموذج رؤية اختياري (6 أو 7 خانات).
// هذا المسار ليس هو المسار الافتراضي في التطبيق؛ المسار الافتراضي
// هو OCR المحلي (ML Kit على الجوال وTesseract على الويب).
// لا تضع مفتاح OpenAI في التطبيق النهائي: استخدم وسيطًا خلفيًا.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'ai_meter_response.dart';
import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';

class AIMeterOCR {
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
  );

  static const String _model = 'gpt-4o';
  static const Duration _timeout = Duration(seconds: 30);

  /// يقرأ 6 أو 7 خانات صحيحة من نافذة العداد.
  /// [expectedDigits] اختياري (6 أو 7) عندما يكون عدد خانات العداد معروفًا.
  static Future<String?> readMeter({int? expectedDigits}) async {
    if (expectedDigits != null &&
        expectedDigits != MeterAnalyzer.minDigits &&
        expectedDigits != MeterAnalyzer.maxDigits) {
      throw ArgumentError('expectedDigits must be 6 or 7');
    }

    try {
      if (_apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY is missing');
      }

      debugPrint('========================================');
      debugPrint('AI METER OCR — starting the meter capture');
      debugPrint('========================================');

      final ImagePicker picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedImage == null) {
        debugPrint('The user cancelled the capture');
        return null;
      }

      final Uint8List bytes = await pickedImage.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('The image is empty');
      }

      final ImageQualityReport quality =
          ImageQualityAnalyzer.analyzeBytes(bytes);
      debugPrint('AI OCR Image Quality: ${quality.summaryMessage}');

      final String base64Image = base64Encode(bytes);
      final String mimeType = _getMimeType(pickedImage.name);
      final String dataUrl = 'data:$mimeType;base64,$base64Image';

      final String digitRule = expectedDigits == null
          ? 'The integer window contains either 6 or 7 digits. Count the visible integer drums first.'
          : 'The integer window contains exactly $expectedDigits digits.';

      final String prompt = '''
Read only the integer digits in the water meter's rectangular digit window.

Rules:
- $digitRule
- Read left to right, exactly as printed.
- Keep every leading zero. Do not pad, truncate, or reorder digits.
- Ignore serial numbers, labels, barcodes, and the red fractional drums.
- If any integer digit is hidden, blurred, or ambiguous, return an empty reading instead of guessing.
- Return JSON only: {"reading":"0650040","digit_count":7,"confidence":0.95}
- Confidence must be a number between 0 and 1; use 0 if unreadable.
- "reading" must be a string of 6 or 7 ASCII digits, or "" when unreadable.
''';

      final Uri uri = Uri.parse('https://api.openai.com/v1/responses');

      final Map<String, dynamic> body = {
        'model': _model,
        'max_output_tokens': 80,
        'input': [
          {
            'role': 'user',
            'content': [
              {'type': 'input_text', 'text': prompt},
              {
                'type': 'input_image',
                'image_url': dataUrl,
                'detail': 'high',
              },
            ],
          },
        ],
      };

      final http.Response response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'OpenAI API Error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final String rawText = _extractOutputText(decoded);
      final String? number = parseAiMeterResponse(rawText, expectedDigits: expectedDigits);

      if (number == null) {
        return null;
      }

      return number;
    } catch (e, stackTrace) {
      debugPrint('AI OCR ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static String _extractOutputText(dynamic decoded) {
    try {
      if (decoded is! Map) {
        return '';
      }

      final dynamic direct = decoded['output_text'];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final dynamic output = decoded['output'];
      if (output is List) {
        for (final dynamic item in output) {
          if (item is! Map) continue;
          final dynamic content = item['content'];
          if (content is! List) continue;

          for (final dynamic part in content) {
            if (part is! Map) continue;
            final dynamic text = part['text'];
            if (text is String && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }

      return '';
    } catch (_) {
      return '';
    }
  }

  static String _getMimeType(String filename) {
    final String name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
