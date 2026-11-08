import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

// ============================================================
// نقطة البداية
// ============================================================
//
// مهم:
// أي خطأ هنا (فشل تهيئة Firebase، حجب الشبكة، إعداد ناقص)
// كان سابقًا يوقف التطبيق قبل runApp فتظهر صفحة بيضاء فارغة
// بلا أي رسالة — خصوصًا على الويب.
//
// الآن: إن فشلت التهيئة نعرض شاشة خطأ واضحة بالعربية
// فيها نص الخطأ وزر إعادة المحاولة.
//
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await startApp();
}

// ============================================================
// الويب: لا جلسة محفوظة
// ============================================================
//
// المطلوب أن تُفتح الصفحة دائمًا على شاشة تسجيل الدخول.
// Persistence.NONE يجعل الجلسة في الذاكرة فقط، فتزول مع تحديث
// الصفحة أو إغلاق التبويب — بخلاف السلوك الافتراضي الذي يحفظ
// الجلسة في المتصفح فيتجاوز الدخول.
//
// هذا يخص الويب وحده: على الجوال تُترك الجلسة كما هي.
// ============================================================

Future<void> _clearWebSession() async {
  if (!kIsWeb) return;

  try {
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
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

/// يهيّئ Firebase ثم يشغّل التطبيق، ويعرض شاشة خطأ عند الفشل.
Future<void> startApp() async {
  try {
    // مهلة محددة حتى لا تبقى الصفحة معلّقة إلى ما لا نهاية
    // على شبكة بطيئة أو محجوبة.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 25),
    );

    await _clearWebSession();

    runApp(
      const MyWaterApp(),
    );
  } catch (error) {
    debugPrint('STARTUP ERROR: $error');

    runApp(
      StartupErrorApp(
        error: error.toString(),
      ),
    );
  }
}

class MyWaterApp extends StatelessWidget {
  const MyWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Azal Soft Platform',

      // =========================================================
      // اللغة العربية
      // =========================================================

      locale: const Locale('ar', 'AE'),

      // =========================================================
      // اللغة واتجاه التطبيق
      // =========================================================

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ar', 'AE'),
      ],

      // =========================================================
      // إجبار التطبيق على RTL
      // =========================================================

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },

      // =========================================================
      // التصميم
      // =========================================================

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),

        inputDecorationTheme:
            const InputDecorationTheme(
          alignLabelWithHint: true,
        ),
      ),

      // =========================================================
      // البداية
      // =========================================================
      //
      // الويب: شاشة الدخول مباشرة بلا شاشة انتظار.
      //
      // السبب: على الويب الجلسة غير محفوظة (Persistence.NONE)،
      // فلا يوجد مستخدم مسجّل عند فتح الصفحة أبدًا — أي أن
      // SplashScreen كان يعرض دوّار «Loading sign-in…» ثم ينتظر
      // استجابة Firebase Auth (حتى 5 ثوانٍ) ليعرض الشاشة نفسها
      // التي كان يمكن رسمها في الإطار الأول.
      //
      // الجوال: يبقى SplashScreen كما هو لأنه هو الذي يقرر:
      // مستخدم مسجل → HomeScreen · غير مسجل → LoginScreen.
      //
      // =========================================================

      home: kIsWeb ? const LoginScreen() : const SplashScreen(),
    );
  }
}

// ============================================================
// شاشة خطأ الإقلاع
// ============================================================
//
// تظهر فقط إذا فشلت تهيئة Firebase، بدلًا من صفحة بيضاء.
// ============================================================

class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({
    super.key,
    required this.error,
  });

  final String error;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool retrying = false;

  Future<void> retry() async {
    if (retrying) return;

    setState(() => retrying = true);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 25),
      );

      await _clearWebSession();

      if (!mounted) return;

      runApp(
        const MyWaterApp(),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        retrying = false;
        lastError = error.toString();
      });
    }
  }

  String? lastError;

  @override
  Widget build(BuildContext context) {
    final String shown = lastError ?? widget.error;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      locale: const Locale('ar', 'AE'),

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('ar', 'AE'),
      ],

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),
      ),

      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 56,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Azal Soft Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تعذّر تشغيل التطبيق: لم يتم الاتصال بخدمات Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      shown,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تحقّق من الاتصال بالإنترنت، ثم أعد المحاولة.\n'
                    'وإذا كانت الصفحة تعمل سابقًا ثم ظهرت بيضاء بعد تحديث، '
                    'فامسح ذاكرة المتصفح المؤقتة أو افتح الصفحة في نافذة خاصة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: retrying ? null : retry,
                      icon: retrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        retrying ? 'جارٍ إعادة المحاولة…' : 'إعادة المحاولة',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
