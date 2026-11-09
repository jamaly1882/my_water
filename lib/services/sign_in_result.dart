// ============================================================
// sign_in_result.dart
// ============================================================
//
// أنواع نتيجة الدخول — ملف صغير بلا أي استيراد، يُستورد
// استيرادًا عاديًا من شاشة الدخول وشاشة الإقلاع.
//
// سبب وجوده منفصلًا: مكتبة sign_in_flow.dart (التي تقرأ
// Firestore) مؤجَّلة التحميل، ولا يجوز استخدام نوع من مكتبة
// مؤجَّلة في توقيع دالة في مكتبة عادية. فالأنواع هنا، والمنطق هناك.
// ============================================================

enum SignInOutcome {
  /// مدير عام — يذهب إلى شاشات الإعداد.
  admin,

  /// مشرف — يذهب إلى الرئيسية.
  supervisor,

  /// لا توجد وثيقة للمستخدم في مجموعة users.
  userNotFound,

  /// الحساب موقوف (active == false).
  inactive,

  /// الدور ليس supervisor ولا دور مدير.
  notSupervisor,

  /// الحساب التجريبي غير معلَّم بـ isDemo.
  notDemo,

  /// بيانات الموقع ناقصة (محافظة/مديرية/عزلة/قرية/بئر).
  incompleteLocation,

  /// خطأ غير متوقع أثناء القراءة.
  error,
}

class SupervisorProfile {
  const SupervisorProfile({
    required this.uid,
    this.provinceId = '',
    this.provinceName = '',
    this.districtId = '',
    this.districtName = '',
    this.hamletId = '',
    this.hamletName = '',
    this.villageId = '',
    this.villageName = '',
    this.wellId = '',
    this.wellName = '',
  });

  final String uid;

  final String provinceId;
  final String provinceName;

  final String districtId;
  final String districtName;

  final String hamletId;
  final String hamletName;

  final String villageId;
  final String villageName;

  final String wellId;
  final String wellName;

  bool get hasLocation =>
      provinceId.isNotEmpty &&
      districtId.isNotEmpty &&
      hamletId.isNotEmpty &&
      villageId.isNotEmpty &&
      wellId.isNotEmpty;
}

class SignInResult {
  const SignInResult(
    this.outcome, {
    this.profile,
    this.message = '',
  });

  final SignInOutcome outcome;

  final SupervisorProfile? profile;

  /// نص الخطأ التقني إن وُجد (يظهر للمستخدم في شاشة الدخول).
  final String message;

  bool get isAdmin => outcome == SignInOutcome.admin;

  bool get isSupervisor => outcome == SignInOutcome.supervisor;
}
