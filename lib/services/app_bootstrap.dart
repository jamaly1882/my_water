import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

// ============================================================
// تهيئة التطبيق — بالتوازي مع رسم الواجهة
// ============================================================
//
// سابقًا كان main() ينتظر Firebase.initializeApp كاملة قبل runApp،
// ثم ينتظر SplashScreen إشارة حالة الدخول. حصيلة ذلك: شاشة تحميل
// إضافية بعد انتهاء تنزيل التطبيق أصلًا.
//
// الآن: تُرسم شاشة تسجيل الدخول فورًا، وتجري التهيئة في الخلفية،
// وزر الدخول لا يُفعَّل إلا بعد أن تصبح Firebase جاهزة.
//
// من يستخدم هذا الملف:
//   - main.dart      → start() عند الإقلاع
//   - login_screen   → يستمع إلى state لتفعيل الزر
//   - splash_screen  → ينتظر ready قبل فحص الجلسة (الجوال)
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

  /// حالة التهيئة — تستمع إليها شاشة الدخول.
  static final ValueNotifier<BootstrapState> state =
      ValueNotifier<BootstrapState>(
    BootstrapState.idle,
  );

  /// نص آخر خطأ، لعرضه للمستخدم بدل الصفحة البيضاء.
  static String? lastError;

  static Future<void>? _pending;

  static bool get isReady =>
      state.value == BootstrapState.ready;

  /// يبدأ التهيئة مرة واحدة فقط؛ النداءات التالية تُعيد نفس الـ Future.
  static Future<void> start() {
    return _pending ??= _start();
  }

  /// إعادة المحاولة بعد فشل (زر «إعادة المحاولة»).
  static Future<void> retry() {
    _pending = null;

    return start();
  }

  static Future<void> _start() async {
    if (state.value == BootstrapState.ready) {
      return;
    }

    state.value = BootstrapState.starting;
    lastError = null;

    try {
      // مهلة محددة حتى لا تتوقف الصفحة إلى ما لا نهاية
      // على شبكة بطيئة أو محجوبة.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(
          const Duration(seconds: 25),
        );
      }

      await clearWebSession();

      state.value = BootstrapState.ready;
    } catch (error) {
      lastError = error.toString();
      state.value = BootstrapState.failed;

      debugPrint('BOOTSTRAP ERROR: $error');
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
  // يُنفَّذ داخل التهيئة، أي قبل تفعيل زر الدخول — فلا يمكن
  // تسجيل الدخول قبل أن تُطبَّق.
  // ============================================================

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
}
