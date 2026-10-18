// ============================================================
// ai_meter_ocr.dart
// قراءة عداد المياه عبر نموذج الرؤية الذكي مع فحص جودة الصورة
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';

class AIMeterOCR {
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
  );

  // ==========================================================
  // نموذج الرؤية
  // ==========================================================

  static const String _model = 'gpt-4o';

  // ==========================================================
  // قراءة العداد
  // ==========================================================

  static Future<String?> readMeter() async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY غير موجود');
      }

      debugPrint('========================================');
      debugPrint('AI METER OCR - بدء تصوير العداد');
      debugPrint('========================================');

      final ImagePicker picker = ImagePicker();

      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedImage == null) {
        debugPrint('المستخدم ألغى التصوير');
        return null;
      }

      final Uint8List bytes = await pickedImage.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('الصورة فارغة');
      }

      // فحص جودة الصورة قبل الإرسال
      final ImageQualityReport quality =
          ImageQualityAnalyzer.analyzeBytes(bytes);
      debugPrint('AI OCR Image Quality: ${quality.summaryMessage}');

      final String base64Image = base64Encode(bytes);
      final String mimeType = _getMimeType(pickedImage.name);
      final String dataUrl = 'data:$mimeType;base64,$base64Image';

      const String prompt = '''
اقرأ رقم عداد المياه الظاهر في نافذة الأرقام السبعة فقط.

مهم جداً:
- اقرأ الخانات السبع الظاهرة داخل نافذة العداد من اليسار إلى اليمين.
- لا تقرأ أرقام الملصقات أو الرقم التسلسلي على جسم العداد.
- لا تحذف الصفر الأول في بداية القراءة.
- لا تضف أي رقم ولا تغير ترتيب الأرقام.
- أرجع الرقم المكون من 7 خانات فقط بدون شرح وبدون مسافات.

مثال:
0650040
''';

      final Uri uri = Uri.parse('https://api.openai.com/v1/responses');

      final Map<String, dynamic> body = {
        'model': _model,
        'input': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': prompt,
              },
              {
                'type': 'input_image',
                'image_url': dataUrl,
                'detail': 'high',
              },
            ],
          },
        ],
      };

      final http.Response response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'OpenAI API Error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final String rawText = _extractOutputText(decoded);
      final String number = _normalizeNumber(rawText);

      if (number.isEmpty) {
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

  static String _normalizeNumber(String value) {
    return MeterAnalyzer.normalize(value);
  }

  static String _getMimeType(String filename) {
    final String name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
