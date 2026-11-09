
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/app_bootstrap.dart';
import '../services/gm_dashboard_service.dart';
import '../widgets/my_app_bar.dart';

// ============================================================
// تحميل مؤجَّل للشاشات الثقيلة
// ============================================================
//
// كانت شاشة الدخول تستورد HomeScreen و SetupMshrfScreen استيرادًا
// مباشرًا، فيُضطر المتصفح إلى تنزيل كل الشاشات والتقارير وOCR
// **قبل** أن تظهر شاشة الدخول. صار هذا الجزء يُنزَّل عند الضغط
// على الدخول فقط، فصار الملف الأولي أصغر بكثير.
// ============================================================

import '../home_screen.dart' deferred as home_screen;
import 'set_up_mshrf/setup_mshrf_screen.dart' deferred as setup_mshrf;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // Firebase تُقرأ عند الحاجة لا عند إنشاء الشاشة
  // ============================================================
  //
  // كان `FirebaseAuth.instance` يُقرأ في أوّل سطر من الحالة، وهذا
  // يرمي استثناءً إن لم تكتمل التهيئة بعد. صار القراءة عند
  // الضغط على الدخول فقط — بعد أن يصبح AppBootstrap جاهزًا.
  // ============================================================

  FirebaseAuth get auth => FirebaseAuth.instance;

  FirebaseFirestore get firestore =>
      FirebaseFirestore.instance;

  Timer? _prefetchTimer;

  @override
  void initState() {
    super.initState();

    // إن أُعيد تحميل الشاشة دون أن يكون main قد بدأ التهيئة.
    AppBootstrap.start();

    AppBootstrap.state.addListener(_onBootstrapChanged);

    if (AppBootstrap.isReady) {
      schedulePrefetch();
    }
  }

  void _onBootstrapChanged() {
    if (AppBootstrap.isReady) {
      schedulePrefetch();
    }
  }

  // ============================================================
  // تحميل صامت لشاشات ما بعد الدخول
  // ============================================================
  //
  // الانتظار بعد جهوزية الاتصال، ثم تنزيل جزء الشاشات في الخلفية.
  // النتيجة: عند الضغط على «تسجيل الدخول» يكون الجزء موجودًا،
  // فيكون الانتقال فوريًا بدل أن ينتظر التنزيل.
  // ============================================================

  void schedulePrefetch() {
    _prefetchTimer?.cancel();

    _prefetchTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (!mounted || !AppBootstrap.isReady) return;

        home_screen.loadLibrary().catchError((_) {});

        setup_mshrf.loadLibrary().catchError((_) {});
      },
    );
  }

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  /// نص المرحلة الحالية (مثل «جارٍ تحميل الشاشات…») يظهر على الزر.
  String stage = '';

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

    // Firebase قد تكون ما زالت تُهيَّأ (بدأت في الخلفية مع أول إطار).
    if (!AppBootstrap.isReady) {
      AppBootstrap.start();

      message('Preparing the connection… try again in a moment');

      return;
    }

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
        await openAdminScreens();

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
        await openAdminScreens();

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

      // تنزيل جزء الشاشات (مؤجَّل) — يحدث مرة واحدة في كل جلسة.
      await showLoading('Loading the dashboard…');

      await home_screen.loadLibrary();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => home_screen.HomeScreen(
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
          stage = '';
        });
      }
    }
  }

  // ============================================================
  // تحميل جزء مؤجَّل ثم فتح الشاشة
  // ============================================================
  //
  // جزء الشاشات يُنزَّل عند أول انتقال فقط؛ بعد ذلك يكون في الذاكرة
  // (أو في كاش المتصفح) فيكون الانتقال فوريًا في الجلسات التالية.
  // ============================================================

  Future<void> showLoading(String text) async {
    if (!mounted) return;

    setState(() {
      stage = text;
    });
  }

  Future<void> openAdminScreens() async {
    await showLoading('Loading the admin screens…');

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
    _prefetchTimer?.cancel();

    AppBootstrap.state.removeListener(_onBootstrapChanged);

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
          // نستمع لحالة Firebase: تظهر شاشة الدخول فورًا،
          // وتُفعَّل الأزرار لحظة جهوزيتها.
          child: ValueListenableBuilder<BootstrapState>(
            valueListenable: AppBootstrap.state,
            builder: (context, bootState, _) {
              final bool ready =
                  bootState == BootstrapState.ready;

              return Center(
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
                        // حالة التهيئة
                        //
                        // الشاشة ظاهرة بالفعل؛ هذا شريط صغير يقول
                        // إن الاتصال ما زال يُجهَّز، أو خطأ + إعادة
                        // محاولة. لا يحجب النموذج ولا يؤخّره.
                        // ======================================

                        if (!ready) ...[
                          _BootstrapNotice(state: bootState),
                          const SizedBox(height: 18),
                        ],

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
                            onPressed: (loading || !ready)
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
                                  ? (stage.isEmpty
                                      ? 'Signing in…'
                                      : stage)
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
                            onPressed: (loading || !ready)
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================
// شريط حالة التهيئة
// ============================================================

class _BootstrapNotice extends StatelessWidget {
  const _BootstrapNotice({
    required this.state,
  });

  final BootstrapState state;

  @override
  Widget build(BuildContext context) {
    // فشل التهيئة: سبب واضح وزر إعادة محاولة.
    if (state == BootstrapState.failed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFFB74D),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تعذّر الاتصال بخدمات Firebase',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B3D00),
              ),
            ),
            if (AppBootstrap.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                AppBootstrap.lastError!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF6B3D00),
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: FilledButton.icon(
                onPressed: () {
                  AppBootstrap.retry();
                },
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                ),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // قيد التهيئة: شريط رفيع لا يحجب النموذج.
    return Column(
      children: [
        const LinearProgressIndicator(
          minHeight: 3,
        ),
        const SizedBox(height: 8),
        Text(
          'جارٍ تجهيز الاتصال… يمكنك كتابة بياناتك الآن',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
