import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';
import 'login_screen.dart';
import 'set_up_mshrf/setup_mshrf_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  // ============================================================
  // التحقق من تسجيل الدخول
  // ============================================================

  Future<void> checkLogin() async {
    // ==========================================================
    // ننتظر قليلاً حتى يستعيد Firebase جلسة المستخدم
    // ==========================================================

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    final User? user = auth.currentUser;

    if (!mounted) return;

    // ==========================================================
    // لا يوجد تسجيل دخول
    // ==========================================================

    if (user == null) {
      goToLogin();
      return;
    }

    // ==========================================================
    // المدير الرئيسي
    // ==========================================================

    if (user.email?.toLowerCase() ==
        "ahmedul2020@gmail.com") {
      goToAdmin();
      return;
    }

    // ==========================================================
    // المشرف
    // ==========================================================

    try {
      final DocumentSnapshot userDoc =
          await firestore
              .collection("users")
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        await auth.signOut();

        if (!mounted) return;

        message("بيانات المستخدم غير موجودة");

        goToLogin();

        return;
      }

      final data =
          userDoc.data() as Map<String, dynamic>;

      // ========================================================
      // الصلاحية
      // ========================================================

      final String role =
          data["role"]?.toString() ?? "";

      if (role != "supervisor") {
        await auth.signOut();

        if (!mounted) return;

        message("ليس لديك صلاحية دخول");

        goToLogin();

        return;
      }

      // ========================================================
      // بيانات المشرف
      // ========================================================

      final String supervisorId = user.uid;

      final String provinceId =
          data["provinceId"]?.toString() ?? "";

      final String districtId =
          data["districtId"]?.toString() ?? "";

      final String hamletId =
          data["hamletId"]?.toString() ?? "";

      final String villageId =
          data["villageId"]?.toString() ?? "";

      final String wellId =
          data["wellId"]?.toString() ?? "";

      final String wellName =
          data["wellName"]?.toString() ?? "";

      // ========================================================
      // الدخول مباشرة إلى الرئيسية
      // ========================================================

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            isAdmin: false,
            supervisorId: supervisorId,
            provinceId: provinceId,
            districtId: districtId,
            hamletId: hamletId,
            villageId: villageId,
            wellId: wellId,
            wellName: wellName,
          ),
        ),
      );
    } catch (e) {
      // ========================================================
      // في حالة حدوث خطأ
      // ========================================================

      await auth.signOut();

      if (!mounted) return;

      message("تعذر التحقق من بيانات الدخول");

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

  void goToAdmin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SetupMshrfScreen(),
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
                "نظام إدارة المياه",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "جاري التحقق من تسجيل الدخول...",
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