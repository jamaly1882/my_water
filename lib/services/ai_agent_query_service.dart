import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AiAgentQueryService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// إرسال سؤال حقيقي إلى وكيل الذكاء الاصطناعي.
  ///
  /// Django هو المسؤول عن:
  /// - التحقق من المستخدم
  /// - معرفة البئر المرتبط به
  /// - إنشاء خطة البحث
  /// - فرض wellId
  /// - تنفيذ البحث
  /// - صياغة الإجابة
  static Future<Map<String, dynamic>> ask({
    required String message,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'يجب تسجيل الدخول أولاً.',
      );
    }

    final String? token =
        await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'تعذر الحصول على رمز تسجيل الدخول.',
      );
    }

    final Uri url = Uri.parse(
      '$baseUrl/api/agent/ask/',
    );

    final http.Response response =
        await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
      }),
    );

    Map<String, dynamic> data;

    try {
      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'استجابة الخادم غير صحيحة.',
        );
      }

      data = Map<String, dynamic>.from(
        decoded,
      );
    } catch (_) {
      throw Exception(
        'تعذر قراءة استجابة الخادم.\n'
        'HTTP ${response.statusCode}',
      );
    }

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw Exception(
        data['error']?.toString() ??
            'حدث خطأ أثناء معالجة السؤال.',
      );
    }

    return data;
  }
}