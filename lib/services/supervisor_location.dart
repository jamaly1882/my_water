// ============================================================
// supervisor_location.dart
//
// خدمة موحدة لتحديد موقع المشرف:
// المحافظة / المديرية / العزلة / القرية / البئر
//
// المشكلة التي تعالجها:
// عند تسجيل الدخول كانت تُمرَّر المعرفات فقط (provinceId ...)
// بدون الأسماء، لذلك كانت صفحة "إضافة زبون" وبقية الصفحات
// تعرض "غير محدد".
//
// الحل:
// 1) قراءة الأسماء المحفوظة في مستند المستخدم (users).
// 2) إذا كان الاسم مفقوداً (حسابات قديمة) يتم جلبه من
//    مجموعة Firestore المطابقة عبر المعرف.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SupervisorLocation {
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

  const SupervisorLocation({
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

  // ==========================================================
  // هل الموقع مكتمل؟
  // ==========================================================

  bool get isComplete =>
      provinceId.isNotEmpty &&
      districtId.isNotEmpty &&
      hamletId.isNotEmpty &&
      villageId.isNotEmpty;

  // ==========================================================
  // قائمة الأسماء غير الفارغة بالترتيب
  // (تُستخدم في شريط الموقع الموحد)
  // ==========================================================

  List<String> get names {
    final List<String> result = <String>[];

    void add(String? value) {
      final String text = value?.trim() ?? '';
      if (text.isNotEmpty) {
        result.add(text);
      }
    }

    add(provinceName);
    add(districtName);
    add(hamletName);
    add(villageName);

    return result;
  }

  /// الأسماء مع البئر في النهاية
  List<String> get namesWithWell {
    final List<String> result = names;

    final String well = wellName.trim();
    if (well.isNotEmpty) {
      result.add(well);
    }

    return result;
  }

  /// نص مختصر: "المحافظة - المديرية - العزلة - القرية"
  String get summary => names.join(' - ');

  @override
  String toString() =>
      'SupervisorLocation($provinceName / $districtName / '
      '$hamletName / $villageName / $wellName)';
}

// ============================================================
// محلل الموقع
// ============================================================

class SupervisorLocationResolver {
  SupervisorLocationResolver._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // بناء الموقع من مستند المستخدم (users)
  // ==========================================================

  static Future<SupervisorLocation> fromUserData(
    Map<String, dynamic> data,
  ) async {
    String provinceId = _text(data['provinceId']);
    String districtId = _text(data['districtId']);
    String hamletId = _text(data['hamletId']);
    String villageId = _text(data['villageId']);
    String wellId = _text(data['wellId']);

    String provinceName = _text(data['provinceName']);
    String districtName = _text(data['districtName']);
    String hamletName = _text(data['hamletName']);
    String villageName = _text(data['villageName']);
    String wellName = _text(data['wellName']);

    // ========================================================
    // إكمال الأسماء الناقصة من Firestore
    // (حسابات المشرفين المُنشأة قبل إضافة حقول الأسماء)
    // ========================================================

    try {
      if (provinceName.isEmpty && provinceId.isNotEmpty) {
        provinceName = await _nameOf('provinces', provinceId);
      }

      if (districtName.isEmpty && districtId.isNotEmpty) {
        districtName = await _nameOf('districts', districtId);
      }

      if (hamletName.isEmpty && hamletId.isNotEmpty) {
        hamletName = await _nameOf('hamlets', hamletId);
      }

      if (villageName.isEmpty && villageId.isNotEmpty) {
        villageName = await _nameOf('villages', villageId);
      }

      if (wellName.isEmpty && wellId.isNotEmpty) {
        wellName = await _nameOf('wells', wellId);
      }

      // ======================================================
      // إذا كان المعرف نفسه مفقوداً وحقل الاسم موجود
      // (حالة نادرة) لا نفعل شيئاً، الأهم هو الاسم للعرض.
      // ======================================================
    } catch (e) {
      debugPrint('SupervisorLocationResolver: $e');
    }

    return SupervisorLocation(
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
    );
  }

  // ==========================================================
  // جلب اسم مستند واحد من مجموعة
  // ==========================================================

  static Future<String> _nameOf(
    String collection,
    String id,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(collection).doc(id).get();

      if (!doc.exists) {
        return '';
      }

      final Map<String, dynamic>? data = doc.data();

      if (data == null) {
        return '';
      }

      // بعض المجموعات تخزن الاسم في name وأخرى في arabicName
      final String name = _text(data['name']);

      if (name.isNotEmpty) {
        return name;
      }

      return _text(data['arabicName']);
    } catch (e) {
      debugPrint('SupervisorLocationResolver._nameOf($collection): $e');
      return '';
    }
  }

  // ==========================================================
  // تحويل أي قيمة إلى نص نظيف
  // ==========================================================

  static String _text(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    return value.toString().trim();
  }
}
