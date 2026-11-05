// ============================================================
// location_text.dart
// ============================================================
//
// أسماء الموقع التي تُعرض بجانب الزبون:
// المحافظة · المديرية · العزلة (sub-district).
//
// الأولوية لوثيقة الزبون نفسها، فإن كانت القيمة القديمة
// غير محفوظة فيها نرجع إلى موقع المشرف (قيم الشاشة).
//
// ملف واحد يخدم كل الشاشات حتى يظهر الموقع بصيغة موحّدة.
// ============================================================

class LocationNames {
  final String province;
  final String district;
  final String hamlet;

  const LocationNames({
    required this.province,
    required this.district,
    required this.hamlet,
  });

  bool get isEmpty =>
      province.isEmpty && district.isEmpty && hamlet.isEmpty;

  /// سطر واحد جاهز للعرض.
  String get line {
    final List<String> parts = <String>[
      if (province.isNotEmpty) 'Governorate: $province',
      if (district.isNotEmpty) 'District: $district',
      if (hamlet.isNotEmpty) 'Sub-district: $hamlet',
    ];

    return parts.join('  ·  ');
  }

  /// أسماء مختصرة بلا عناوين: «إب · الرضمة · ...».
  String get shortLine {
    final List<String> parts = <String>[
      if (province.isNotEmpty) province,
      if (district.isNotEmpty) district,
      if (hamlet.isNotEmpty) hamlet,
    ];

    return parts.join(' · ');
  }
}

/// يقرأ موقع الزبون من وثيقة Firestore، ويستخدم قيم الشاشة عند الغياب.
LocationNames resolveLocation(
  Map<String, dynamic>? data, {
  String? provinceName,
  String? districtName,
  String? hamletName,
}) {
  String pick(String key, String? fallback) {
    final String stored = (data == null ? '' : (data[key]?.toString() ?? ''))
        .trim();

    if (stored.isNotEmpty) return stored;

    return (fallback ?? '').trim();
  }

  return LocationNames(
    province: pick('provinceName', provinceName),
    district: pick('districtName', districtName),
    hamlet: pick('hamletName', hamletName),
  );
}
