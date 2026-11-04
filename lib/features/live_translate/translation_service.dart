// ============================================================
// translation_service.dart
// ترجمة النص إلى العربية عبر خدمة الخادم.
//
// العقد المتوقّع (نفس نمط خدمة وكيل الذكاء الاصطناعي):
//   POST {baseUrl}/api/translate/
//   Authorization: Bearer <Firebase ID token>
//   { "text": "...", "source": "en", "target": "ar" }
//   → { "translation": "..." }
//
// [baseUrl] قابل للتغيير من إعدادات الشاشة، لأن 127.0.0.1 لا يصلح
// على الهاتف أو على النطاق المنشور.
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TranslationService {
  static String baseUrl = 'http://127.0.0.1:8000';

  /// اختبار سريع للاتصال بالخادم.
  static Future<bool> ping() async {
    try {
      final http.Response response = await http
          .get(Uri.parse('$baseUrl/api/health/'))
          .timeout(const Duration(seconds: 6));

      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<String> translate({
    required String text,
    String source = 'en',
    String target = 'ar',
  }) async {
    final String trimmed = text.trim();

    if (trimmed.isEmpty) return '';

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final String? token = await user.getIdToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final http.Response response = await http
        .post(
          Uri.parse('$baseUrl/api/translate/'),
          headers: headers,
          body: jsonEncode(<String, String>{
            'text': trimmed,
            'source': source,
            'target': target,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception(
        'خدمة الترجمة أعادت الرمز ${response.statusCode}.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map) {
      final dynamic value = decoded['translation'] ??
          decoded['translatedText'] ??
          decoded['translated_text'] ??
          decoded['text'];

      if (value != null) return value.toString();
    }

    throw Exception('استجابة غير مفهومة من خدمة الترجمة.');
  }
}
