import 'local_insight_service.dart';

// ============================================================
// وكيل الأسئلة — AI Agent query service
//
// كان يرسل السؤال إلى خادم Django خارجي يعتمد على Ollama.
// الآن يُجيب داخل التطبيق من بيانات Firestore نفسها، تلقائياً:
// لا HTTP، لا خادم محلي، لا Ollama، لا مفتاح API.
// ============================================================

class AiAgentQueryService {
  /// إجابة فورية محسوبة من بيانات النظام.
  static Future<Map<String, dynamic>> ask({
    required String message,
    bool forceRefresh = false,
  }) {
    return LocalInsightService.ask(
      message,
      forceRefresh: forceRefresh,
    );
  }

  /// خيار للمستخدم: تجاهل الذاكرة المؤقتة وقراءة Firestore من جديد.
  static Future<Map<String, dynamic>> refresh({
    required String message,
  }) {
    return ask(message: message, forceRefresh: true);
  }
}
