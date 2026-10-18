import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MyWaterApp(),
  );
}

class MyWaterApp extends StatelessWidget {
  const MyWaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'نظام إدارة المياه',

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
      // مهم جدًا:
      // لا نضع LoginScreen هنا.
      // SplashScreen هو الذي يقرر:
      //
      // مستخدم مسجل → HomeScreen
      // غير مسجل → LoginScreen
      //
      // =========================================================

      home: const SplashScreen(),
    );
  }
}