// ============================================================
// sign_in_flow.dart — يُستورد دائمًا كتحميل مؤجَّل
// ============================================================
//
// هذا الملف يستورد cloud_firestore، وهو أثقل ما في مسار الدخول.
// نقله إلى مكتبة مؤجَّلة يعني أن الزائر ينزّل Firebase Auth فقط
// ليرى صفحة الدخول، ثم يُنزَّل Firestore + الشاشات بعد نجاح
// المصادقة — حيث ينتظر المستخدم أصلًا.
//
// الاستخدام في الشاشات:
//   import '../services/sign_in_flow.dart' deferred as sign_in_flow;
//   await sign_in_flow.loadLibrary();
//   final result = await sign_in_flow.resolveProfile(uid: ..., email: ...);
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'gm_roles.dart';
import 'sign_in_result.dart';

/// يقرأ وثيقة المستخدم ويحدد إلى أين يذهب بعد نجاح المصادقة.
///
/// [requireLocation] يُستخدم في شاشة الدخول: تمنع الدخول إذا كانت
/// بيانات الموقع ناقصة. شاشة الإقلاع على الجوال تتركه false
/// (سلوكها السابق).
Future<SignInResult> resolveProfile({
  required String uid,
  required String? email,
  bool demo = false,
  bool requireLocation = false,
}) async {
  // المدير الرئيسي يُعرف من بريده بلا أي قراءة من Firestore.
  if (GmRoles.isMainSupervisorEmail(email)) {
    return const SignInResult(SignInOutcome.admin);
  }

  final DocumentSnapshot<Map<String, dynamic>> userDoc;

  try {
    userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
  } catch (error) {
    return SignInResult(
      SignInOutcome.error,
      message: error.toString(),
    );
  }

  if (!userDoc.exists) {
    return const SignInResult(SignInOutcome.userNotFound);
  }

  final Map<String, dynamic> data =
      userDoc.data() ?? <String, dynamic>{};

  if (data['active'] == false) {
    return const SignInResult(SignInOutcome.inactive);
  }

  final String role = data['role']?.toString() ?? '';

  if (GmRoles.isMainSupervisorRole(role)) {
    return const SignInResult(SignInOutcome.admin);
  }

  if (role != 'supervisor') {
    return const SignInResult(SignInOutcome.notSupervisor);
  }

  if (demo && data['isDemo'] != true) {
    return const SignInResult(SignInOutcome.notDemo);
  }

  final SupervisorProfile profile = SupervisorProfile(
    uid: uid,
    provinceId: data['provinceId']?.toString() ?? '',
    provinceName: data['provinceName']?.toString() ?? '',
    districtId: data['districtId']?.toString() ?? '',
    districtName: data['districtName']?.toString() ?? '',
    hamletId: data['hamletId']?.toString() ?? '',
    hamletName: data['hamletName']?.toString() ?? '',
    villageId: data['villageId']?.toString() ?? '',
    villageName: data['villageName']?.toString() ?? '',
    wellId: data['wellId']?.toString() ?? '',
    wellName: data['wellName']?.toString() ?? '',
  );

  if (requireLocation && !profile.hasLocation) {
    return SignInResult(
      SignInOutcome.incompleteLocation,
      profile: profile,
    );
  }

  return SignInResult(
    SignInOutcome.supervisor,
    profile: profile,
  );
}
