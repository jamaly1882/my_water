import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/app_bootstrap.dart';
import '../services/sign_in_result.dart';
import 'login_screen.dart';

// كل ما يحتاج Firestore يُنزَّل عند الحاجة فقط (تحميل مؤجَّل)،
// فلا يدخل cloud_firestore في حزمة الإقلاع ولا شاشة الدخول.
import '../home_screen.dart' deferred as home_screen;
import '../services/sign_in_flow.dart' deferred as sign_in_flow;
import 'set_up_mshrf/setup_mshrf_screen.dart' deferred as setup_mshrf;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // قراءة عند الحاجة: الشاشة قد تُبنى قبل أن تكتمل تهيئة Firebase.
  FirebaseAuth get auth => FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  // ============================================================
  // التحقق من تسجيل الدخول
  // ============================================================

  Future<void> checkLogin() async {
    // الجوال ينتظر اكتمال التهيئة (تبدأ في main بالتوازي).
    await AppBootstrap.start();

    if (!mounted) return;

    if (!AppBootstrap.isReady) {
      message('Could not reach Firebase');

      goToLogin();

      return;
    }

    // ==========================================================
    // ننتظر أول إشارة من Firebase عن حالة الدخول
    //
    // authStateChanges() تُصدر الحالة الحالية فورًا (مستخدم أو null)،
    // فلا حاجة إلى التأخير الثابت الذي كان هنا سابقًا — كان يسبب
    // وميضًا ثم يتجاوز شاشة الدخول عند وجود جلسة محفوظة.
    //
    // على الويب صارت الجلسة غير محفوظة (انظر main.dart)،
    // فتصل الحالة null وتُعرض شاشة الدخول مباشرة.
    // ==========================================================

    User? user;

    try {
      user = await auth
          .authStateChanges()
          .first
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => auth.currentUser,
          );
    } catch (_) {
      user = auth.currentUser;
    }

    if (!mounted) return;

    // ==========================================================
    // لا يوجد تسجيل دخول
    // ==========================================================

    if (user == null) {
      goToLogin();
      return;
    }

    // ==========================================================
    // تحديد الوجهة — Firestore يأتي من مكتبة مؤجَّلة
    // ==========================================================

    try {
      await sign_in_flow.loadLibrary();

      if (!mounted) return;

      final SignInResult result =
          await sign_in_flow.resolveProfile(
        uid: user.uid,
        email: user.email,
      );

      if (!mounted) return;

      if (result.outcome == SignInOutcome.admin) {
        await goToAdmin();
        return;
      }

      final SupervisorProfile? profile = result.profile;

      if (result.outcome != SignInOutcome.supervisor ||
          profile == null) {
        await auth.signOut();

        if (!mounted) return;

        switch (result.outcome) {
          case SignInOutcome.userNotFound:
            message("User record not found");
            break;

          case SignInOutcome.inactive:
            message("This account is not activated");
            break;

          case SignInOutcome.notSupervisor:
            message("You do not have access permission");
            break;

          default:
            message("Could not verify your sign-in");
        }

        goToLogin();

        return;
      }

      // ========================================================
      // الدخول مباشرة إلى الرئيسية
      // ========================================================

      await home_screen.loadLibrary();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => home_screen.HomeScreen(
            isAdmin: false,
            supervisorId: profile.uid,
            provinceId: profile.provinceId,
            provinceName: profile.provinceName,
            districtId: profile.districtId,
            districtName: profile.districtName,
            hamletId: profile.hamletId,
            hamletName: profile.hamletName,
            villageId: profile.villageId,
            villageName: profile.villageName,
            wellId: profile.wellId,
            wellName: profile.wellName,
          ),
        ),
      );
    } catch (e) {
      // ========================================================
      // في حالة حدوث خطأ
      // ========================================================

      await auth.signOut();

      if (!mounted) return;

      message("Could not verify your sign-in");

      goToLogin();
    }
  }

  // ============================================================
  // الذهاب إلى تسجيل الدخول
  // ============================================================

  void goToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // دخول المدير
  // ============================================================

  Future<void> goToAdmin() async {
    if (!mounted) return;

    await setup_mshrf.loadLibrary();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => setup_mshrf.SetupMshrfScreen(),
      ),
    );
  }

  // ============================================================
  // الرسائل
  // ============================================================

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
            const Color(0xffF5F9FF),

        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              // ==================================================
              // أيقونة المياه
              // ==================================================

              Container(
                width: 110,
                height: 110,

                decoration:
                    BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.water_drop,
                  size: 75,
                  color: Colors.blue.shade700,
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // اسم النظام
              // ==================================================

              const Text(
                "Azal Soft Platform",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Loading sign-in…",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 25),

              const SizedBox(
                width: 35,
                height: 35,

                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}