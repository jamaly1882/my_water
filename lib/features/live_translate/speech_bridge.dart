// ============================================================
// speech_bridge.dart
// واجهة موحّدة للاستماع إلى الكلام وتحويله إلى نص.
//
// على الويب: Web Speech API للميكروفون، و MediaRecorder + WebSocket
//            لصوت الاجتماع (يحتاج خدمة تفريغ صوتي).
// على الموبايل: غير مدعوم حالياً — الكود يعطي رسالة واضحة بدل الانهيار.
// ============================================================

import 'speech_bridge_stub.dart'
    if (dart.library.html) 'speech_bridge_web.dart' as impl;

/// دالة تُستدعى بالنص المتفَرَّغ: [isFinal] صحيحة عند اكتمال الجملة.
typedef SpeechTextCallback = void Function(String text, bool isFinal);

/// دالة رسائل الحالة أو الخطأ.
typedef SpeechMessageCallback = void Function(String message);

class SpeechBridge {
  SpeechBridge._();

  /// هل التعرّف على الكلام مدعوم في هذه المنصة/المتصفح؟
  static Future<bool> isSupported() {
    return impl.isSupported();
  }

  /// هل يمكن التقاط صوت التبويب/الاجتماع؟
  static Future<bool> supportsSystemAudio() {
    return impl.supportsSystemAudio();
  }

  /// بدء الاستماع إلى الميكروفون.
  ///
  /// [language] بصيغة BCP-47، مثل: en-US
  static Future<void> startMic({
    required String language,
    required SpeechTextCallback onText,
    required SpeechMessageCallback onStatus,
    required SpeechMessageCallback onError,
  }) {
    return impl.startMic(
      language: language,
      onText: onText,
      onStatus: onStatus,
      onError: onError,
    );
  }

  /// إيقاف الاستماع إلى الميكروفون.
  static Future<void> stopMic() {
    return impl.stopMic();
  }

  /// الاستماع إلى صوت الاجتماع/التبويب.
  ///
  /// [websocketUrl] عنوان خدمة التفريغ الصوتي التي تستقبل مقاطع الصوت
  /// وترسل نصاً في صورة JSON: {"text": "...", "isFinal": true}
  static Future<void> startSystemAudio({
    required String websocketUrl,
    required SpeechTextCallback onText,
    required SpeechMessageCallback onStatus,
    required SpeechMessageCallback onError,
  }) {
    return impl.startSystemAudio(
      websocketUrl: websocketUrl,
      onText: onText,
      onStatus: onStatus,
      onError: onError,
    );
  }

  /// إيقاف الاستماع إلى صوت الاجتماع.
  static Future<void> stopSystemAudio() {
    return impl.stopSystemAudio();
  }
}
