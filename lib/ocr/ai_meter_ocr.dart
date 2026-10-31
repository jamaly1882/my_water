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
  // هل محرك الذكاء الاصطناعي متاح؟
  // (يتطلب تمرير المفتاح عند البناء:
  //  flutter run --dart-define=OPENAI_API_KEY=sk-...)
  // ==========================================================

  static bool get isAvailable => _apiKey.trim().isNotEmpty;

  // ==========================================================
  // قراءة رقم العداد من صورة مقصوصة (نافذة الأرقام السبعة)
  //
  // تُستخدم في مسار "قراءة بداية الدور":
  // تصوير -> قص يدوي -> قراءة بالذكاء الاصطناعي
  // ==========================================================

  static Future<String?> readCroppedMeter(
    Uint8List bytes, {
    int? previousReading,
    String filename = 'meter.jpg',
  }) async {
    if (bytes.isEmpty) {
      debugPrint('AI OCR: الصورة المقصوصة فارغة');
      return null;
    }

    return _requestReading(
      bytes: bytes,
      mimeType: _getMimeType(filename),
      previousReading: previousReading,
    );
  }

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

      return _requestReading(
        bytes: bytes,
        mimeType: _getMimeType(pickedImage.name),
      );
    } catch (e, stackTrace) {
      debugPrint('AI OCR ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  // ==========================================================
  // النداء المشترك لنموذج الرؤية
  //
  // يرسل الصورة مع تعليمات دقيقة لقراءة الخانات السبع فقط،
  // ويمكن تمرير القراءة السابقة لمساعدة النموذج على تجنب
  // الأخطاء المنطقية (قراءة أقل من السابقة مثلاً).
  // ==========================================================

  static Future<String?> _requestReading({
    required Uint8List bytes,
    required String mimeType,
    int? previousReading,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OPENAI_API_KEY غير موجود');
      }

      final String base64Image = base64Encode(bytes);
      final String dataUrl = 'data:$mimeType;base64,$base64Image';

      final String prompt = _buildPrompt(previousReading);

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

      debugPrint('AI OCR: إرسال الصورة إلى نموذج الرؤية...');

      final http.Response response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              throw Exception('انتهت مهلة الاتصال بنموذج الرؤية');
            },
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'OpenAI API Error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final String rawText = _extractOutputText(decoded);
      final String number = _normalizeNumber(rawText);

      debugPrint('AI OCR RAW: $rawText');
      debugPrint('AI OCR NORMALIZED: $number');

      if (number.isEmpty) {
        return null;
      }

      return number;
    } catch (e, stackTrace) {
      debugPrint('AI OCR REQUEST ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  // ==========================================================
  // بناء تعليمات القراءة
  // ==========================================================

  static String _buildPrompt(int? previousReading) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln(
      'اقرأ رقم عداد المياه الظاهر في نافذة الأرقام السبعة فقط.',
    );
    buffer.writeln();
    buffer.writeln('مهم جداً:');
    buffer.writeln(
      '- اقرأ الخانات السبع الظاهرة داخل نافذة العداد من اليسار إلى اليمين.',
    );
    buffer.writeln(
      '- لا تقرأ أرقام الملصقات أو الرقم التسلسلي على جسم العداد.',
    );
    buffer.writeln('- لا تحذف الصفر الأول في بداية القراءة.');
    buffer.writeln('- لا تضف أي رقم ولا تغير ترتيب الأرقام.');
    buffer.writeln(
      '- إذا كانت خانة بين رقمين (منتصفة) اعتمد الرقم الأدنى.',
    );
    buffer.writeln(
      '- أرجع الرقم المكون من 7 خانات فقط بدون شرح وبدون مسافات.',
    );

    if (previousReading != null && previousReading > 0) {
      buffer.writeln();
      buffer.writeln(
        'للمساعدة فقط: القراءة السابقة لهذا العداد هي '
        '${previousReading.toString().padLeft(7, '0')}.',
      );
      buffer.writeln(
        'القراءة الجديدة يجب أن تكون مساوية أو أكبر منها عادةً، '
        'لكن اعتمد دائماً ما تراه في الصورة وليس القراءة السابقة.',
      );
    }

    buffer.writeln();
    buffer.writeln('مثال:');
    buffer.writeln('0650040');

    return buffer.toString();
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
