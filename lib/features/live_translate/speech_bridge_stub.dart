// ============================================================
// speech_bridge_stub.dart
// نسخة المنصات غير الويب (Android / iOS / سطح المكتب).
// التعرّف على الكلام الفوري غير موصول بعد؛ نُعيد رسائل واضحة
// بدل الانهيار أو التعليق.
// ============================================================

import 'speech_bridge.dart';

const String _unsupported =
    'الاستماع الفوري متاح حالياً على نسخة الويب (Chrome). '
    'على الهاتف سيُربط بمحرّك التعرّف على الكلام في تحديث لاحق.';

Future<bool> isSupported() async => false;

Future<bool> supportsSystemAudio() async => false;

Future<void> startMic({
  required String language,
  required SpeechTextCallback onText,
  required SpeechMessageCallback onStatus,
  required SpeechMessageCallback onError,
}) async {
  onError(_unsupported);
}

Future<void> stopMic() async {}

Future<void> startSystemAudio({
  required String websocketUrl,
  required SpeechTextCallback onText,
  required SpeechMessageCallback onStatus,
  required SpeechMessageCallback onError,
}) async {
  onError(_unsupported);
}

Future<void> stopSystemAudio() async {}
