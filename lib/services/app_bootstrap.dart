import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'web_recovery.dart';

// ============================================================
// تهيئة التطبيق — بالتوازي مع رسم الواجهة
// ============================================================
//
// الشاشة تُرسم فورًا، وتجري التهيئة في الخلفية، وزر الدخول لا يُفعَّل
// إلا بعد أن تصبح Firebase جاهزة.
//
// من يستخدم هذا الملف:
//   - main.dart      → start() عند الإقلاع
//   - login_screen   → يستمع إلى state لتفعيل الزر، ويعرض سبب الفشل
//   - splash_screen  → ينتظر ready قبل فحص الجلسة (الجوال)
//
// ============================================================
// لماذا ثلاث محاولات وإصلاح للمتصفح؟
// ============================================================
//
// إنترنت بطيء أو محجوب يجعل سكربت Firebase (يُحمَّل من gstatic.com)
// يصل متأخرًا، فيفشل أول initializeApp برسالة تقنية مثل
// «Null check operator used on a null value» — ثم ينجح بعد ثانيتين
// إن أعدنا المحاولة. وكانت النسخة السابقة تحاول مرة واحدة فقط،
// فتبقى الشاشة عالقة على «تعذّر الاتصال» في بعض المتصفحات.
//
// الآن:
//   1) المحاولة الأولى — فورية (الشبكة السريعة لا تنتظر).
//   2) عند الفشل: حذف التطبيق المشوّه ثم إعادة المحاولة (×3) بفاصل
//      متزايد 1.5s ثم 3s.
//   3) إن كان الخطأ يوحي بسكربت محجوب أو كاش قديم: مسح الكاش
//      وإلغاء service worker ثم إعادة تحميل الصفحة مرة واحدة
//      (web/index.html → window.__azalHardReload).
//   4) إن فشل كل ذلك: تُعرض رسالة مفهومة + سبب تقني + زرّا
//      «إعادة المحاولة» و«مسح الكاش وإعادة التحميل».
//
// أي خطأ في خطوة غير حرجة (مثل ضبط جلسة الويب) لا يُسقط التهيئة.
// ============================================================

enum BootstrapState {
  /// لم تبدأ التهيئة بعد.
  idle,

  /// Firebase قيد التهيئة.
  starting,

  /// Firebase جاهزة ويمكن تسجيل الدخول.
  ready,

  /// فشلت التهيئة — انظر [AppBootstrap.lastError].
  failed,
}

class AppBootstrap {
  AppBootstrap._();

  /// عدد المحاولات قبل إظهار رسالة الفشل.
  static const int maxAttempts = 3;

  /// مهلة كل محاولة على حِدة.
  static const Duration attemptTimeout = Duration(seconds: 20);

  /// حالة التهيئة — تستمع إليها شاشة الدخول.
  static final ValueNotifier<BootstrapState> state =
      ValueNotifier<BootstrapState>(
    BootstrapState.idle,
  );

  /// نص آخر خطأ كما وصل من Firebase (يُعرض بخط ثابت للمساعدة).
  static String? lastError;

  /// سبب مفهوم بالعربية، مشتق من نص الخطأ — يظهر فوق النص التقني.
  static String? lastHint;

  /// رقم المحاولة الحالية (1..maxAttempts) — تعرضه شاشة الدخول.
  static int attempt = 0;

  /// هل طُلب إصلاح المتصفح في هذه الجلسة؟ (منع حلقة إعادة تحميل)
  static bool recoveryRequested = false;

  static Future<void>? _pending;

  static bool get isReady =>
      state.value == BootstrapState.ready;

  /// يبدأ التهيئة مرة واحدة فقط؛ النداءات التالية تُعيد نفس الـ Future.
  static Future<void> start() {
    return _pending ??= _start();
  }

  /// يبدأ التهيئة إن لم تبدأ، أو يعيد المحاولة إن كانت قد فشلت.
  static Future<void> ensureStarted() {
    if (state.value == BootstrapState.failed) {
      return retry();
    }

    return start();
  }

  /// إعادة المحاولة بعد فشل (زر «إعادة المحاولة»).
  static Future<void> retry() {
    _pending = null;

    return start();
  }

  /// هل يمكن لهذا المنصة مسح الكاش وإعادة التحميل؟
  static bool get canHardReload =>
      kIsWeb && canHardReloadPlatform;

  /// حالة سكربتات Firebase في المتصفح (للتشخيص) — `null` خارج الويب.
  static String? get sdkState => firebaseSdkState();

  /// زر «مسح الكاش وإعادة التحميل» — يعود `false` إن لم يبدأ شيء.
  static bool hardReload() {
    if (!kIsWeb) return false;

    recoveryRequested = true;

    return hardReloadPlatform();
  }

  // ============================================================
  // الدورة الكاملة
  // ============================================================

  static Future<void> _start() async {
    if (state.value == BootstrapState.ready) {
      return;
    }

    state.value = BootstrapState.starting;
    lastError = null;
    lastHint = null;

    Object? failure;

    for (var current = 1; current <= maxAttempts; current++) {
      attempt = current;

      try {
        await _initializeFirebase();

        // خطوة غير حرجة: فشلها لا يعني أن Firebase غير متاحة.
        await _applyWebPersistence();

        state.value = BootstrapState.ready;

        return;
      } catch (error) {
        failure = error;
        lastError = _describe(error);

        debugPrint(
          'BOOTSTRAP ERROR ($current/$maxAttempts): $error',
        );

        if (current < maxAttempts) {
          await _deleteBrokenApp();
          await Future<void>.delayed(
            Duration(milliseconds: 1500 * current),
          );
        }
      }
    }

    // آخر ورقة: كاش قديم أو سكربت محجوب — نظّف ثم أعد التحميل مرة واحدة.
    if (kIsWeb && _looksLikeScriptProblem(failure)) {
      if (hardReload()) {
        _armStuckTimer();

        return;
      }
    }

    state.value = BootstrapState.failed;
  }

  /// إن أُعيد التحميل ولم تصل الصفحة، لا نترك المستخدم على «جارٍ التجهيز».
  static void _armStuckTimer() {
    Timer(const Duration(seconds: 15), () {
      if (state.value == BootstrapState.starting) {
        lastHint ??=
            'لم تكتمل إعادة التحميل. أعد المحاولة، وإن تكرر الأمر '
            'استخدم متصفحًا آخر.';

        state.value = BootstrapState.failed;
      }
    });
  }

  static Future<void> _initializeFirebase() async {
    final FirebaseOptions options =
        DefaultFirebaseOptions.currentPlatform;

    // نداء متوازٍ من شاشة أخرى قد يكون أنشأ التطبيق بالفعل.
    // نتحقق أن التطبيق القائم سليم (نفس المشروع) قبل أن نكتفي به،
    // فلا نُعلن «جاهز» على تطبيق نصف مهيأ.
    try {
      final FirebaseApp existing = Firebase.app();

      if (existing.options.projectId == options.projectId) {
        return;
      }
    } catch (_) {
      // لا يوجد تطبيق افتراضي بعد — نُنشئه الآن.
    }

    await Firebase.initializeApp(
      options: options,
    ).timeout(attemptTimeout);
  }

  /// حذف تطبيق Firebase نصف المهيأ قبل المحاولة التالية.
  ///
  /// بدونه تفشل المحاولة التالية برسالة duplicate-app، فيبدو الفشل
  /// دائمًا ولو كان العطل عابرًا.
  static Future<void> _deleteBrokenApp() async {
    try {
      for (final app in Firebase.apps.toList(growable: false)) {
        await app.delete();
      }
    } catch (error) {
      debugPrint('BOOTSTRAP RESET: $error');
    }
  }

  // ============================================================
  // الويب: لا جلسة محفوظة
  // ============================================================
  //
  // المطلوب أن تُفتح الصفحة دائمًا على شاشة تسجيل الدخول.
  // Persistence.NONE يجعل الجلسة في الذاكرة فقط، فتزول مع تحديث
  // الصفحة أو إغلاق التبويب.
  //
  // فشل هذه الخطوة لا يمنع الدخول (الجلسة تُنشأ من جديد عند كل
  // تسجيل دخول)، لذلك تُلتقط أخطاؤها ولا تُسقط التهيئة.
  // ============================================================

  static Future<void> _applyWebPersistence() async {
    if (!kIsWeb) return;

    await clearWebSession();
  }

  static Future<void> clearWebSession() async {
    if (!kIsWeb) return;

    try {
      await FirebaseAuth.instance.setPersistence(
        Persistence.NONE,
      );
    } catch (error) {
      debugPrint('WEB PERSISTENCE: $error');

      // بديل مضمون إن لم تُدعم الواجهة: خروج صريح.
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        debugPrint('WEB SIGN OUT: $signOutError');
      }
    }
  }

  // ============================================================
  // تصنيف الخطأ
  // ============================================================

  /// سبب مفهوم للمستخدم، مع الاحتفاظ بالنص التقني في [lastError].
  static String _describe(Object? error) {
    final String text = error?.toString() ?? 'Unknown error';
    final String lower = text.toLowerCase();

    if (lower.contains('null check') ||
        lower.contains('of undefined') ||
        lower.contains('cannot read') ||
        lower.contains('not a function')) {
      lastHint =
          'المتصفح لم يُكمل تحميل ملفات Firebase (مانع إعلانات، شبكة '
          'بطيئة، أو نسخة قديمة محفوظة في الكاش).';
    } else if (lower.contains('timeout') ||
        lower.contains('deadline')) {
      lastHint =
          'انتهت المهلة قبل وصول رد Firebase. تحقّق من سرعة الاتصال '
          'ثم أعد المحاولة.';
    } else if (lower.contains('network') ||
        lower.contains('offline') ||
        lower.contains('failed host lookup') ||
        lower.contains('xmlhttprequest')) {
      lastHint =
          'لا يبدو أن هناك اتصالًا بالإنترنت، أو أن طلب Firebase محجوب '
          'على هذه الشبكة.';
    } else if (lower.contains('permission') ||
        lower.contains('unauthorized') ||
        lower.contains('api-key')) {
      lastHint =
          'إعدادات مشروع Firebase لا تسمح لهذا الرابط. راجع النطاقات '
          'المصرّح بها في وحدة التحكم.';
    } else {
      lastHint = null;
    }

    return text;
  }

  /// الأخطاء التي يستفيد معها مسح الكاش من إعادة التحميل.
  static bool _looksLikeScriptProblem(Object? error) {
    final String lower =
        error?.toString().toLowerCase() ?? '';

    return lower.contains('null check') ||
        lower.contains('of undefined') ||
        lower.contains('cannot read') ||
        lower.contains('not a function');
  }
}
