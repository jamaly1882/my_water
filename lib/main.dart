import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_bootstrap.dart';

// ============================================================
// نقطة البداية
// ============================================================
//
// مهم:
// كان main() ينتظر Firebase.initializeApp قبل runApp، فكان المستخدم
// يرى شاشة تحميل إضافية بعد انتهاء تنزيل التطبيق أصلًا، ثم شاشة
// SplashScreen تدوّر عدة ثوانٍ قبل أن تظهر شاشة الدخول.
//
// الآن:
//   1) runApp فورًا — أول إطار يُرسم بأسرع ما يمكن.
//   2) التهيئة تجري في الخلفية (AppBootstrap.start).
//   3) شاشة الدخول تظهر مباشرة، وزر الدخول يُفعَّل حين تجهز Firebase.
//
// الويب يفتح دائمًا على تسجيل الدخول (لا شاشة انتقال)، والجوال
// يبقى على SplashScreen الذي يفحص الجلسة المحفوظة.
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // لا ننتظرها: الرسم يبدأ الآن، والتهيئة تكتمل في الخلفية.
  unawaited(AppBootstrap.start());

  runApp(const MyWaterApp());
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
      // الويب: شاشة الدخول مباشرة — بلا شاشة انتقال وبلا انتظار.
      // الجوال: SplashScreen يقرر بين الرئيسية وتسجيل الدخول.
      // =========================================================

      home: kIsWeb
          ? const LoginScreen()
          : const SplashScreen(),
    );
  }
}
