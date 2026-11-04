// ============================================================
// speech_bridge_web.dart
// تنفيذ الجسر على الويب عبر الدوال المعرّفة في web/voice_translate.js
// (window.AYCVoice)، بنفس نمط ocr_web.dart في هذا المشروع.
// ============================================================

import 'dart:js_util' as js_util;

import 'speech_bridge.dart';

dynamic _voice() {
  try {
    return js_util.getProperty<dynamic>(js_util.globalThis, 'AYCVoice');
  } catch (_) {
    return null;
  }
}

Future<bool> isSupported() async {
  final dynamic voice = _voice();

  if (voice == null) return false;

  try {
    return js_util.callMethod<bool>(voice, 'isSupported', <dynamic>[]);
  } catch (_) {
    return false;
  }
}

Future<bool> supportsSystemAudio() async {
  final dynamic voice = _voice();

  if (voice == null) return false;

  try {
    return js_util.callMethod<bool>(
      voice,
      'supportsSystemAudio',
      <dynamic>[],
    );
  } catch (_) {
    return false;
  }
}

Future<void> startMic({
  required String language,
  required SpeechTextCallback onText,
  required SpeechMessageCallback onStatus,
  required SpeechMessageCallback onError,
}) async {
  final dynamic voice = _voice();

  if (voice == null) {
    onError(
      'ملف voice_translate.js غير محمّل. تأكّد من وجوده في مجلد web.',
    );
    return;
  }

  try {
    js_util.callMethod<dynamic>(
      voice,
      'startMic',
      <dynamic>[
        language,
        js_util.allowInterop(
          (dynamic text, dynamic isFinal) {
            onText(
              text == null ? '' : text.toString(),
              isFinal == true,
            );
          },
        ),
        js_util.allowInterop(
          (dynamic message) {
            onStatus(message == null ? '' : message.toString());
          },
        ),
        js_util.allowInterop(
          (dynamic message) {
            onError(message == null ? '' : message.toString());
          },
        ),
      ],
    );
  } catch (error) {
    onError('تعذّر بدء الاستماع: $error');
  }
}

Future<void> stopMic() async {
  final dynamic voice = _voice();

  if (voice == null) return;

  try {
    js_util.callMethod<dynamic>(voice, 'stopMic', <dynamic>[]);
  } catch (_) {
    // تجاهل
  }
}

Future<void> startSystemAudio({
  required String websocketUrl,
  required SpeechTextCallback onText,
  required SpeechMessageCallback onStatus,
  required SpeechMessageCallback onError,
}) async {
  final dynamic voice = _voice();

  if (voice == null) {
    onError(
      'ملف voice_translate.js غير محمّل. تأكّد من وجوده في مجلد web.',
    );
    return;
  }

  try {
    js_util.callMethod<dynamic>(
      voice,
      'startSystemAudio',
      <dynamic>[
        websocketUrl,
        js_util.allowInterop(
          (dynamic text, dynamic isFinal) {
            onText(
              text == null ? '' : text.toString(),
              isFinal == true,
            );
          },
        ),
        js_util.allowInterop(
          (dynamic message) {
            onStatus(message == null ? '' : message.toString());
          },
        ),
        js_util.allowInterop(
          (dynamic message) {
            onError(message == null ? '' : message.toString());
          },
        ),
      ],
    );
  } catch (error) {
    onError('تعذّر بدء التقاط صوت الاجتماع: $error');
  }
}

Future<void> stopSystemAudio() async {
  final dynamic voice = _voice();

  if (voice == null) return;

  try {
    js_util.callMethod<dynamic>(
      voice,
      'stopSystemAudio',
      <dynamic>[],
    );
  } catch (_) {
    // تجاهل
  }
}

Future<bool> captionsSupported() async {
  final dynamic voice = _voice();

  if (voice == null) return false;

  try {
    return js_util.callMethod<bool>(
      voice,
      'captionsSupported',
      <dynamic>[],
    );
  } catch (_) {
    return false;
  }
}

Future<bool> openCaptions() async {
  final dynamic voice = _voice();

  if (voice == null) return false;

  try {
    final dynamic result = js_util.callMethod<dynamic>(
      voice,
      'openCaptions',
      <dynamic>[],
    );

    final dynamic opened =
        await js_util.promiseToFuture<dynamic>(result);

    return opened == true;
  } catch (_) {
    return false;
  }
}

Future<void> updateCaptions({
  required String arabic,
  required String original,
}) async {
  final dynamic voice = _voice();

  if (voice == null) return;

  try {
    js_util.callMethod<dynamic>(
      voice,
      'updateCaptions',
      <dynamic>[arabic, original],
    );
  } catch (_) {
    // تجاهل
  }
}

Future<void> closeCaptions() async {
  final dynamic voice = _voice();

  if (voice == null) return;

  try {
    js_util.callMethod<dynamic>(voice, 'closeCaptions', <dynamic>[]);
  } catch (_) {
    // تجاهل
  }
}

Future<bool> isCaptionsOpen() async {
  final dynamic voice = _voice();

  if (voice == null) return false;

  try {
    return js_util.callMethod<bool>(
      voice,
      'isCaptionsOpen',
      <dynamic>[],
    );
  } catch (_) {
    return false;
  }
}
