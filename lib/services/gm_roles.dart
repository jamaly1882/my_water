// ============================================================
// gm_roles.dart
// ============================================================
//
// كانت هذه الفئة داخل gm_dashboard_service.dart، وهذا الملف
// يستورد cloud_firestore. فكل من يريد فحص الدور فقط — شاشة
// الدخول وشاشة الإقلاع — كان يجرّ معه Firestore كاملًا إلى
// الحزمة الأولى التي ينزّلها الزائر قبل أن يرى صفحة الدخول.
//
// هنا لا يوجد أي استيراد: ملف صغير يُضمَّن في الحزمة الأولى
// بحجمه الحقيقي وحده.
// ============================================================

class GmRoles {
  /// البريد الرئيسي للمشرف العام في النظام.
  static const String mainSupervisorEmail = 'ahmedul2020@gmail.com';

  /// أدوار تعامل كمدير عام وتملك كل الصلاحيات.
  static const Set<String> mainRoles = <String>{
    'main_supervisor',
    'general_manager',
    'admin',
    'manager',
  };

  static bool isMainSupervisorEmail(String? email) {
    return (email ?? '').trim().toLowerCase() ==
        mainSupervisorEmail;
  }

  static bool isMainSupervisorRole(String? role) {
    final String value =
        (role ?? '').trim().toLowerCase();

    if (value.isEmpty) return false;

    return mainRoles.contains(value) ||
        value == 'مدير عام' ||
        value == 'المشرف الرئيسي' ||
        value == 'مدير';
  }

  static bool isMainSupervisor({
    String? email,
    String? role,
  }) {
    return isMainSupervisorEmail(email) ||
        isMainSupervisorRole(role);
  }
}
