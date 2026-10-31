
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';
import '../widgets/my_app_bar.dart';
import 'set_up_mshrf/setup_mshrf_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  // ============================================================
  // بيانات الحساب التجريبي
  // ============================================================

  static const String demoUsername = 'demo';
  static const String demoPassword = 'Demo@123456';
  static const String demoEmail = 'demo@mywater.com';

  // ============================================================
  // تحويل اسم المستخدم إلى بريد Firebase
  // ============================================================

  String createEmail(String username) {
    final value = username.trim();

    if (value.contains('@')) {
      return value.toLowerCase();
    }

    return '$value@mywater.com';
  }

  // ============================================================
  // تسجيل الدخول العادي أو التجريبي
  // ============================================================

  Future<void> login({bool demo = false}) async {
    if (loading) return;

    final username = demo
        ? demoUsername
        : usernameController.text.trim();

    final password = demo
        ? demoPassword
        : passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      message('أدخل اسم المستخدم وكلمة السر');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final String email = demo
          ? demoEmail
          : createEmail(username);

      // ========================================================
      // تسجيل الدخول في Firebase
      // ========================================================

      final UserCredential result =
          await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;

      if (user == null) {
        message('تعذر الحصول على بيانات المستخدم');
        return;
      }

      // ========================================================
      // المدير الرئيسي
      // ========================================================

      if (user.email?.toLowerCase() ==
          'ahmedul2020@gmail.com') {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SetupMshrfScreen(),
          ),
        );

        return;
      }

      // ========================================================
      // قراءة بيانات المستخدم من Firestore
      // ========================================================

      final DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await auth.signOut();

        message('بيانات المستخدم غير موجودة');
        return;
      }

      final data =
          userDoc.data() as Map<String, dynamic>;

      // ========================================================
      // التحقق من حالة الحساب
      // ========================================================

      if (data['active'] == false) {
        await auth.signOut();

        message('هذا الحساب غير مفعل');
        return;
      }

      // ========================================================
      // التحقق من الصلاحية
      // ========================================================

      final String role =
          data['role']?.toString() ?? '';

      if (role != 'supervisor') {
        await auth.signOut();

        message('ليس لديك صلاحية دخول');
        return;
      }

      // ========================================================
      // التحقق من الحساب التجريبي
      // ========================================================

      if (demo && data['isDemo'] != true) {
        await auth.signOut();

        message('هذا الحساب ليس حساباً تجريبياً');
        return;
      }

      // ========================================================
      // بيانات المشرف
      // ========================================================

      final String supervisorId = user.uid;

      final String provinceId =
          data['provinceId']?.toString() ?? '';

      final String districtId =
          data['districtId']?.toString() ?? '';

      final String hamletId =
          data['hamletId']?.toString() ?? '';

      final String villageId =
          data['villageId']?.toString() ?? '';

      final String wellId =
          data['wellId']?.toString() ?? '';

      final String wellName =
          data['wellName']?.toString() ?? '';

      // ========================================================
      // التحقق من اكتمال بيانات الموقع
      // ========================================================

      if (provinceId.isEmpty ||
          districtId.isEmpty ||
          hamletId.isEmpty ||
          villageId.isEmpty ||
          wellId.isEmpty) {
        await auth.signOut();

        message('بيانات موقع المشرف غير مكتملة');
        return;
      }

      // ========================================================
      // الانتقال إلى الصفحة الرئيسية
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
    }

    // ==========================================================
    // أخطاء Firebase Authentication
    // ==========================================================

    on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'المستخدم غير موجود';
          break;

        case 'wrong-password':
          errorMessage = 'كلمة السر غير صحيحة';
          break;

        case 'invalid-email':
          errorMessage = 'البريد غير صحيح';
          break;

        case 'invalid-credential':
          errorMessage =
              'اسم المستخدم أو كلمة السر غير صحيحة';
          break;

        case 'user-disabled':
          errorMessage = 'هذا الحساب معطل';
          break;

        case 'too-many-requests':
          errorMessage =
              'تمت محاولات كثيرة، حاول مرة أخرى لاحقاً';
          break;

        case 'network-request-failed':
          errorMessage = 'تحقق من اتصال الإنترنت';
          break;

        default:
          errorMessage =
              e.message ?? 'خطأ في تسجيل الدخول';
      }

      message(errorMessage);
    } catch (e) {
      message('حدث خطأ أثناء تسجيل الدخول');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // الدخول بالحساب التجريبي
  // ============================================================

  Future<void> loginDemo() async {
    if (loading) return;

    await login(demo: true);
  }

  // ============================================================
  // الرسائل
  // ============================================================

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // تنظيف
  // ============================================================

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // الصفحة
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F9FF),

        appBar: const MyAppBar(
          title: 'تسجيل الدخول',
          icon: Icons.login,
        ),

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),

                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(24),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ======================================
                        // أيقونة المياه
                        // ======================================

                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),

                          child: Icon(
                            Icons.water_drop,
                            size: 60,
                            color: Colors.blue.shade700,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ======================================
                        // العنوان
                        // ======================================

                        const Text(
                          'نظام إدارة المياه',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'أدخل بيانات الدخول للمتابعة',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ======================================
                        // اسم المستخدم
                        // ======================================

                        TextField(
                          controller: usernameController,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,

                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم أو البريد',
                            hintText: 'رقم المشرف أو بريد المدير',

                            prefixIcon: const Icon(
                              Icons.person,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ======================================
                        // كلمة السر
                        // ======================================

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,

                          onSubmitted: (_) {
                            if (!loading) {
                              login();
                            }
                          },

                          decoration: InputDecoration(
                            labelText: 'كلمة السر',

                            prefixIcon: const Icon(
                              Icons.lock,
                            ),

                            suffixIcon: IconButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      setState(() {
                                        obscurePassword =
                                            !obscurePassword;
                                      });
                                    },

                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // ======================================
                        // زر الدخول العادي
                        // ======================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,

                          child: ElevatedButton.icon(
                            onPressed: loading
                                ? null
                                : () => login(),

                            icon: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),

                            label: Text(
                              loading
                                  ? 'جاري الدخول...'
                                  : 'دخول',

                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ======================================
                        // زر الحساب التجريبي
                        // ======================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,

                          child: OutlinedButton.icon(
                            onPressed: loading
                                ? null
                                : loginDemo,

                            icon: const Icon(
                              Icons.verified_user,
                              color: Colors.green,
                            ),

                            label: const Text(
                              'الدخول بحساب تجريبي',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.green,
                                width: 1.5,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'حساب مخصص لتقييم وتجربة النظام',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'نظام إدارة المياه',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
