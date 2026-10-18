// ============================================================
// ai_meter_ocr.dart
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AIMeterOCR {
  static const String _apiKey =
      String.fromEnvironment(
    'OPENAI_API_KEY',
  );

  // ==========================================================
  // نموذج الرؤية
  // ==========================================================

  static const String _model = 'gpt-5.6';

  // ==========================================================
  // قراءة العداد
  // ==========================================================

  static Future<String?> readMeter() async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception(
          'OPENAI_API_KEY غير موجود',
        );
      }

      print('========================================');
      print('AI METER OCR');
      print('بدء تصوير العداد');
      print('========================================');

      final ImagePicker picker =
          ImagePicker();

      // ======================================================
      // التقاط الصورة
      // ======================================================

      final XFile? pickedImage =
          await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice:
            CameraDevice.rear,
      );

      if (pickedImage == null) {
        print(
          'المستخدم ألغى التصوير',
        );

        return null;
      }

      // ======================================================
      // قراءة الصورة
      // ======================================================

      final Uint8List bytes =
          await pickedImage.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception(
          'الصورة فارغة',
        );
      }

      print(
        'حجم الصورة: ${bytes.length} bytes',
      );

      // ======================================================
      // Base64
      // ======================================================

      final String base64Image =
          base64Encode(bytes);

      final String mimeType =
          _getMimeType(
        pickedImage.name,
      );

      final String dataUrl =
          'data:$mimeType;base64,$base64Image';

      // ======================================================
      // التعليمات للنموذج
      // ======================================================

      const String prompt = '''
اقرأ رقم عداد المياه الظاهر في نافذة الأرقام فقط.

مهم جداً:
- اقرأ الخانات الظاهرة داخل نافذة العداد.
- لا تقرأ أرقام الملصقات أو جسم العداد.
- لا تحذف أول رقم.
- لا تضف أي رقم.
- لا تغير ترتيب الأرقام.
- إذا كان الرقم يبدأ بصفر، احتفظ به.
- أرجع الرقم فقط.
- بدون شرح.
- بدون مسافات.
- بدون علامات اقتباس.

مثال:
إذا كان الرقم الظاهر:
9142037

فالنتيجة يجب أن تكون:
9142037
''';

      // ======================================================
      // الطلب
      // ======================================================

      final Uri uri =
          Uri.parse(
        'https://api.openai.com/v1/responses',
      );

      final Map<String, dynamic>
          body = {
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

      print(
        'إرسال الصورة إلى OpenAI...',
      );

      final http.Response response =
          await http.post(
        uri,
        headers: {
          'Authorization':
              'Bearer $_apiKey',
          'Content-Type':
              'application/json',
        },
        body: jsonEncode(body),
      );

      // ======================================================
      // طباعة الاستجابة للتشخيص
      // ======================================================

      print('========================================');

      print(
        'HTTP STATUS: ${response.statusCode}',
      );

      print('OPENAI RESPONSE:');

      print(response.body);

      print('========================================');

      // ======================================================
      // فشل API
      // ======================================================

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'OpenAI API Error ${response.statusCode}: '
          '${response.body}',
        );
      }

      // ======================================================
      // JSON
      // ======================================================

      final dynamic decoded =
          jsonDecode(
        response.body,
      );

      // ======================================================
      // استخراج النص
      // ======================================================

      final String rawText =
          _extractOutputText(
        decoded,
      );

      print('========================================');

      print(
        'AI RAW TEXT: $rawText',
      );

      print('========================================');

      // ======================================================
      // تنظيف
      // ======================================================

      final String number =
          _normalizeNumber(
        rawText,
      );

      print(
        'AI FINAL NUMBER: $number',
      );

      // ======================================================
      // لا توجد نتيجة
      // ======================================================

      if (number.isEmpty) {
        print(
          'لم يتم العثور على رقم العداد',
        );

        return null;
      }

      return number;
    } catch (
      e,
      stackTrace
    ) {
      print(
        '========================================',
      );

      print(
        'AI OCR ERROR:',
      );

      print(e);

      print(stackTrace);

      print(
        '========================================',
      );

      return null;
    }
  }

  // ==========================================================
  // استخراج النص من Responses API
  // ==========================================================

  static String _extractOutputText(
    dynamic decoded,
  ) {
    try {
      if (decoded is! Map) {
        return '';
      }

      // ========================================================
      // output_text
      // ========================================================

      final dynamic direct =
          decoded['output_text'];

      if (direct is String &&
          direct.trim().isNotEmpty) {
        return direct.trim();
      }

      // ========================================================
      // output
      // ========================================================

      final dynamic output =
          decoded['output'];

      if (output is List) {
        for (final dynamic item
            in output) {
          if (item is! Map) {
            continue;
          }

          final dynamic content =
              item['content'];

          if (content is! List) {
            continue;
          }

          for (final dynamic part
              in content) {
            if (part is! Map) {
              continue;
            }

            final dynamic text =
                part['text'];

            if (text is String &&
                text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
      }

      return '';
    } catch (e) {
      print(
        'خطأ استخراج النص: $e',
      );

      return '';
    }
  }

  // ==========================================================
  // تنظيف الرقم
  // ==========================================================

  static String _normalizeNumber(
    String value,
  ) {
    String number =
        value.trim();

    // أخطاء بصرية محتملة
    number = number
        .replaceAll(
          'O',
          '0',
        )
        .replaceAll(
          'o',
          '0',
        )
        .replaceAll(
          'I',
          '1',
        )
        .replaceAll(
          'i',
          '1',
        )
        .replaceAll(
          'l',
          '1',
        )
        .replaceAll(
          '|',
          '1',
        );

    // أرقام فقط
    number =
        number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return number;
  }

  // ==========================================================
  // MIME TYPE
  // ==========================================================

  static String _getMimeType(
    String filename,
  ) {
    final String name =
        filename.toLowerCase();

    if (name.endsWith('.png')) {
      return 'image/png';
    }

    if (name.endsWith('.webp')) {
      return 'image/webp';
    }

    if (name.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }
}