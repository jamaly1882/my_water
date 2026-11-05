
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';
import '../services/gm_dashboard_service.dart';
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
      message('Enter your username and password');
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
        message('Could not load user data');
        return;
      }

      // ========================================================
      // المدير الرئيسي
      //
      // يُتعرف عليه من البريد الرئيسي أو من الدور
      // داخل مجموعة users.
      // ========================================================

      if (GmRoles.isMainSupervisorEmail(user.email)) {
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

        message('User record not found');
        return;
      }

      final data =
          userDoc.data() as Map<String, dynamic>;

      // ========================================================
      // التحقق من حالة الحساب
      // ========================================================

      if (data['active'] == false) {
        await auth.signOut();

        message('This account is not activated');
        return;
      }

      // ========================================================
      // التحقق من الصلاحية
      // ========================================================

      final String role =
          data['role']?.toString() ?? '';

      // ========================================================
      // المشرف الرئيسي من خلال الدور
      // ========================================================

      if (GmRoles.isMainSupervisorRole(role)) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const SetupMshrfScreen(),
          ),
        );

        return;
      }

      if (role != 'supervisor') {
        await auth.signOut();

        message('You do not have access permission');
        return;
      }

      // ========================================================
      // التحقق من الحساب التجريبي
      // ========================================================

      if (demo && data['isDemo'] != true) {
        await auth.signOut();

        message('This is not a demo account');
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
      // أسماء الموقع
      //
      // وثيقة المشرف تخزّن الأسماء إلى جانب المعرّفات، وكانت
      // الشاشة تمرّر المعرّفات فقط، فتصل صفحة الزبون بلا اسم
      // محافظة ولا مديرية ولا عزلة.
      // ========================================================

      final String provinceName =
          data['provinceName']?.toString() ?? '';

      final String districtName =
          data['districtName']?.toString() ?? '';

      final String hamletName =
          data['hamletName']?.toString() ?? '';

      final String villageName =
          data['villageName']?.toString() ?? '';

      // ========================================================
      // التحقق من اكتمال بيانات الموقع
      // ========================================================

      if (provinceId.isEmpty ||
          districtId.isEmpty ||
          hamletId.isEmpty ||
          villageId.isEmpty ||
          wellId.isEmpty) {
        await auth.signOut();

        message('Supervisor location data is incomplete');
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
            provinceName: provinceName,
            districtId: districtId,
            districtName: districtName,
            hamletId: hamletId,
            hamletName: hamletName,
            villageId: villageId,
            villageName: villageName,
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
          errorMessage = 'User not found';
          break;

        case 'wrong-password':
          errorMessage = 'Wrong password';
          break;

        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;

        case 'invalid-credential':
          errorMessage =
              'Wrong username or password';
          break;

        case 'user-disabled':
          errorMessage = 'This account is disabled';
          break;

        case 'too-many-requests':
          errorMessage =
              'Too many attempts — try again later';
          break;

        case 'network-request-failed':
          errorMessage = 'Check your internet connection';
          break;

        default:
          errorMessage =
              e.message ?? 'Sign-in error';
      }

      message(errorMessage);
    } catch (e) {
      message('Something went wrong while signing in');
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
          title: 'Sign In',
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
                          'Azal Soft Platform',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Sign in to continue',
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
                            labelText: 'Username or email',
                            hintText: 'Supervisor ID or manager email',

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
                            labelText: 'Password',

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
                                  ? 'Signing in…'
                                  : 'Sign in',

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
                              'Continue with the demo account',
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
                          'A demo account for evaluating the system',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Azal Soft Platform',
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
