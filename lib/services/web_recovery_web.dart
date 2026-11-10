// ============================================================
// web_recovery_web.dart — تنفيذ الإصلاح في المتصفح
// ============================================================

import 'dart:js_util' as js_util;

/// هل يستطيع المتصفح تنفيذ الإصلاح؟
bool get canHardReloadPlatform => true;

/// ينادي `window.__azalHardReload()` (يعرّفها web/index.html).
///
/// تعود `true` إذا بدأ المسح وإعادة التحميل فعلًا، و`false` إذا كانت
/// المحاولة مستنفدة في هذه الجلسة أو لم تكن الدالة موجودة (متصفح قديم
/// أو index.html لم يُحدَّث).
bool hardReloadPlatform() {
  try {
    final result = js_util.callMethod<Object?>(
      js_util.globalThis,
      '__azalHardReload',
      const <Object?>[],
    );

    return result == true;
  } catch (_) {
    return false;
  }
}

/// هل وصلت سكربتات Firebase إلى الصفحة؟
///
/// تُعرض هذه الحالة في لوحة الخطأ، فتعرف من صورة واحدة أن العطل
/// «السكربت لم يُحمّل» لا «رقم سري خاطئ».
String? firebaseSdkState() {
  try {
    final Object? app = js_util.getProperty<Object?>(
      js_util.globalThis,
      'firebase',
    );
    final Object? core = js_util.getProperty<Object?>(
      js_util.globalThis,
      'firebase_core',
    );
    final Object? auth = js_util.getProperty<Object?>(
      js_util.globalThis,
      'firebase_auth',
    );

    String mark(Object? value) =>
        value == null ? 'missing' : 'ok';

    return 'firebase=${mark(app)} · core=${mark(core)} · '
        'auth=${mark(auth)}';
  } catch (_) {
    return null;
  }
}
