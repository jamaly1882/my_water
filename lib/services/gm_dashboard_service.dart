import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// أدوار المشرف الرئيسي (المدير العام)
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

// ============================================================
// تنسيق الأرقام والتواريخ
// ============================================================

String gmFormatNumber(num value, {int? decimals}) {
  final double number = value.toDouble();

  if (number.isNaN) return '0';
  if (number.isInfinite) return '∞';

  final int digits = decimals ??
      (number == number.roundToDouble() ? 0 : 1);

  final bool negative = number < 0;

  final String raw =
      number.abs().toStringAsFixed(digits);

  final List<String> parts = raw.split('.');

  final String whole = parts.first;

  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(whole[i]);
  }

  final String result = parts.length > 1
      ? '$buffer.${parts[1]}'
      : buffer.toString();

  return negative ? '-$result' : result;
}

String gmFormatPercent(num value) {
  final double number = value.toDouble();

  if (number.isNaN) return '0%';

  final String sign = number > 0 ? '+' : '';

  return '$sign${number.toStringAsFixed(1)}%';
}

const List<String> _arabicMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String gmMonthName(int month) {
  if (month < 1 || month > 12) return '';

  return _arabicMonths[month - 1];
}

String gmFormatDate(DateTime? date) {
  if (date == null) return '—';

  final String day =
      date.day.toString().padLeft(2, '0');

  final String month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String gmFormatDateTime(DateTime? date) {
  if (date == null) return '—';

  final String hour =
      date.hour.toString().padLeft(2, '0');

  final String minute =
      date.minute.toString().padLeft(2, '0');

  return '${gmFormatDate(date)} - $hour:$minute';
}

// ============================================================
// نماذج البيانات
// ============================================================

enum GmInsightLevel {
  info,
  success,
  warning,
  danger,
}

class GmInsight {
  final String title;
  final String message;
  final GmInsightLevel level;

  const GmInsight({
    required this.title,
    required this.message,
    this.level = GmInsightLevel.info,
  });
}

class GmWellData {
  final String id;
  final String name;

  final String provinceId;
  final String provinceName;

  final String districtName;
  final String hamletName;

  final String villageId;
  final String villageName;

  final double latitude;
  final double longitude;
  final bool hasCoordinates;

  // ----------------------------------------------------------
  // تُملأ من الدورات وربط المشتركين
  // ----------------------------------------------------------

  double consumption = 0;
  double currentMonthConsumption = 0;
  double previousMonthConsumption = 0;

  int subscribers = 0;
  int closedCycles = 0;

  DateTime? lastCycleDate;

  String supervisorName = '';

  // ----------------------------------------------------------
  // موقع تقريبي على الخريطة (0 - 1)
  // ----------------------------------------------------------

  double mapX = -1;
  double mapY = -1;

  GmWellData({
    required this.id,
    required this.name,
    this.provinceId = '',
    this.provinceName = '',
    this.districtName = '',
    this.hamletName = '',
    this.villageId = '',
    this.villageName = '',
    this.latitude = 0,
    this.longitude = 0,
    this.hasCoordinates = false,
  });

  double get changePercent {
    if (previousMonthConsumption <= 0) {
      return currentMonthConsumption > 0 ? 100 : 0;
    }

    return ((currentMonthConsumption -
                previousMonthConsumption) /
            previousMonthConsumption) *
        100;
  }

  double? get changePercentOrNull {
    if (previousMonthConsumption <= 0) {
      return null;
    }

    return changePercent;
  }

  bool get needsReview {
    return currentMonthConsumption > 0 &&
        previousMonthConsumption > 0 &&
        changePercent >= 30;
  }

  bool get hasSupervisor {
    return supervisorName.trim().isNotEmpty;
  }

  String get locationLabel {
    final List<String> parts = <String>[];

    if (provinceName.trim().isNotEmpty) {
      parts.add(provinceName.trim());
    }

    if (districtName.trim().isNotEmpty) {
      parts.add(districtName.trim());
    }

    if (hamletName.trim().isNotEmpty) {
      parts.add(hamletName.trim());
    }

    if (villageName.trim().isNotEmpty) {
      parts.add(villageName.trim());
    }

    return parts.join(' - ');
  }

  String get coordinatesLabel {
    if (!hasCoordinates) return 'غير محددة';

    return '${latitude.toStringAsFixed(5)}, '
        '${longitude.toStringAsFixed(5)}';
  }
}

class GmVillageData {
  final String id;
  final String name;

  final String provinceId;
  final String provinceName;

  final String districtName;
  final String hamletName;

  final List<GmWellData> wells = <GmWellData>[];

  double consumption = 0;
  double currentMonthConsumption = 0;
  double previousMonthConsumption = 0;

  int subscribers = 0;
  int closedCycles = 0;

  double mapX = -1;
  double mapY = -1;

  GmVillageData({
    required this.id,
    required this.name,
    this.provinceId = '',
    this.provinceName = '',
    this.districtName = '',
    this.hamletName = '',
  });

  int get wellCount => wells.length;

  bool get hasWells => wells.isNotEmpty;

  double get changePercent {
    if (previousMonthConsumption <= 0) {
      return currentMonthConsumption > 0 ? 100 : 0;
    }

    return ((currentMonthConsumption -
                previousMonthConsumption) /
            previousMonthConsumption) *
        100;
  }

  double? get changePercentOrNull {
    if (previousMonthConsumption <= 0) {
      return null;
    }

    return changePercent;
  }

  bool get needsAttention {
    return currentMonthConsumption > 0 &&
        previousMonthConsumption > 0 &&
        changePercent >= 20;
  }

  String get locationLabel {
    final List<String> parts = <String>[];

    if (provinceName.trim().isNotEmpty) {
      parts.add(provinceName.trim());
    }

    if (districtName.trim().isNotEmpty) {
      parts.add(districtName.trim());
    }

    if (hamletName.trim().isNotEmpty) {
      parts.add(hamletName.trim());
    }

    return parts.join(' - ');
  }
}

class GmSupervisorData {
  final String id;
  final String name;
  final String phone;
  final String wellId;

  String wellName;
  String provinceName;
  String villageName;

  final bool active;

  double consumption = 0;
  double currentMonthConsumption = 0;
  double previousMonthConsumption = 0;

  int subscribers = 0;

  GmSupervisorData({
    required this.id,
    required this.name,
    this.phone = '',
    this.wellId = '',
    this.wellName = '',
    this.provinceName = '',
    this.villageName = '',
    this.active = true,
  });

  bool get hasWell => wellId.trim().isNotEmpty;

  double? get changePercentOrNull {
    if (previousMonthConsumption <= 0) {
      return null;
    }

    return ((currentMonthConsumption -
                previousMonthConsumption) /
            previousMonthConsumption) *
        100;
  }

  String get locationLabel {
    final List<String> parts = <String>[];

    if (provinceName.trim().isNotEmpty) {
      parts.add(provinceName.trim());
    }

    if (villageName.trim().isNotEmpty) {
      parts.add(villageName.trim());
    }

    return parts.join(' - ');
  }
}

class GmMonthPoint {
  final DateTime month;
  final String label;
  final double value;

  const GmMonthPoint({
    required this.month,
    required this.label,
    required this.value,
  });
}

// ============================================================
// حزمة بيانات لوحة المدير العام
// ============================================================

class GmDashboardData {
  final int provinceCount;
  final int districtCount;
  final int hamletCount;
  final int villageCount;
  final int wellCount;
  final int supervisorCount;

  final int subscriberCount;
  final int linkedSubscriberCount;

  final int closedCycleCount;

  final double totalConsumption;
  final double currentMonthConsumption;
  final double previousMonthConsumption;

  final List<GmMonthPoint> monthly;
  final List<GmWellData> wells;
  final List<GmVillageData> villages;
  final List<GmSupervisorData> supervisors;
  final List<GmInsight> insights;

  final bool hasCoordinates;

  final DateTime generatedAt;

  final List<String> warnings;

  const GmDashboardData({
    required this.provinceCount,
    required this.districtCount,
    required this.hamletCount,
    required this.villageCount,
    required this.wellCount,
    required this.supervisorCount,
    required this.subscriberCount,
    required this.linkedSubscriberCount,
    required this.closedCycleCount,
    required this.totalConsumption,
    required this.currentMonthConsumption,
    required this.previousMonthConsumption,
    required this.monthly,
    required this.wells,
    required this.villages,
    required this.supervisors,
    required this.insights,
    required this.hasCoordinates,
    required this.generatedAt,
    required this.warnings,
  });

  double get overallChangePercent {
    if (previousMonthConsumption <= 0) {
      return currentMonthConsumption > 0 ? 100 : 0;
    }

    return ((currentMonthConsumption -
                previousMonthConsumption) /
            previousMonthConsumption) *
        100;
  }

  GmWellData? get topWell {
    if (wells.isEmpty) return null;

    return wells.first;
  }

  GmWellData? get topWellThisMonth {
    GmWellData? best;

    for (final GmWellData well in wells) {
      if (well.currentMonthConsumption <= 0) {
        continue;
      }

      if (best == null ||
          well.currentMonthConsumption >
              best.currentMonthConsumption) {
        best = well;
      }
    }

    return best;
  }

  GmVillageData? get topVillage {
    if (villages.isEmpty) return null;

    return villages.first;
  }

  double get maxWellConsumption {
    if (wells.isEmpty) return 0;

    return wells.first.consumption;
  }

  double get maxVillageConsumption {
    if (villages.isEmpty) return 0;

    return villages.first.consumption;
  }

  int get activeWellCount {
    return wells
        .where((GmWellData well) => well.consumption > 0)
        .length;
  }

  List<GmWellData> topWells(int count) {
    return wells.take(count).toList();
  }

  List<GmVillageData> topVillages(int count) {
    return villages.take(count).toList();
  }

  List<GmWellData> get wellsNeedingReview {
    final List<GmWellData> result = wells
        .where((GmWellData well) => well.needsReview)
        .toList();

    result.sort(
      (GmWellData a, GmWellData b) =>
          b.changePercent.compareTo(a.changePercent),
    );

    return result;
  }

  List<GmVillageData> get villagesRising {
    final List<GmVillageData> result = villages
        .where(
          (GmVillageData village) =>
              village.needsAttention,
        )
        .toList();

    result.sort(
      (GmVillageData a, GmVillageData b) =>
          b.changePercent.compareTo(a.changePercent),
    );

    return result;
  }

  List<GmWellData> get wellsWithoutSupervisor {
    return wells
        .where((GmWellData well) => !well.hasSupervisor)
        .toList();
  }

  List<GmWellData> get staleWells {
    final DateTime now = DateTime.now();

    return wells
        .where((GmWellData well) {
          if (well.lastCycleDate == null) return true;

          return now
                  .difference(well.lastCycleDate!)
                  .inDays >
              45;
        })
        .toList();
  }

  List<GmWellData> get wellsWithCoordinates {
    return wells
        .where((GmWellData well) => well.hasCoordinates)
        .toList();
  }
}

// ============================================================
// إجمالي دورات بئر أو قرية
// ============================================================

class _CycleTotals {
  double total = 0;
  double current = 0;
  double previous = 0;

  int count = 0;

  DateTime? last;
}

// ============================================================
// خدمة قراءة البيانات من Firestore
// ============================================================

class GmDashboardService {
  final FirebaseFirestore firestore;

  GmDashboardService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  static const int _cycleLimit = 3000;

  Future<GmDashboardData> load() async {
    final List<String> warnings = <String>[];

    final List<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        results = await Future.wait(
      <Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>[
        _docs('provinces', warnings, 'المحافظات'),
        _docs('districts', warnings, 'المديريات'),
        _docs('hamlets', warnings, 'العُزل'),
        _docs('villages', warnings, 'القرى'),
        _docs('wells', warnings, 'الآبار'),
        _docs('users', warnings, 'المشرفين'),
        _docs('customers', warnings, 'المشتركين'),
        _docs('well_customers', warnings, 'ربط المشتركين'),
        _loadCycles(warnings),
      ],
    );

    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        provinceDocs = results[0];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        districtDocs = results[1];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        hamletDocs = results[2];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        villageDocs = results[3];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        wellDocs = results[4];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        userDocs = results[5];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        customerDocs = results[6];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        wellCustomerDocs = results[7];
    final List<QueryDocumentSnapshot<Map<String, dynamic>>>
        cycleDocs = results[8];

    // ========================================================
    // المشرفون
    // ========================================================

    final Map<String, String> supervisorByWell =
        <String, String>{};

    final List<GmSupervisorData> supervisors =
        <GmSupervisorData>[];

    int supervisorCount = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        doc in userDocs) {
      final Map<String, dynamic> data = doc.data();

      final String role = _text(data, <String>['role'])
          .trim()
          .toLowerCase();

      final bool isSupervisor =
          role == 'supervisor' ||
              role == 'مشرف' ||
              role == 'well_supervisor';

      if (!isSupervisor) continue;
      if (data['active'] == false) continue;

      supervisorCount++;

      final String wellId =
          _text(data, <String>['wellId']);

      final String name = _text(
        data,
        <String>[
          'name',
          'fullName',
          'supervisorName',
          'username',
        ],
      );

      final String phone = _text(
        data,
        <String>['phone', 'username'],
      );

      final String displayName = name.isNotEmpty
          ? name
          : (phone.isNotEmpty ? phone : 'مشرف');

      supervisors.add(
        GmSupervisorData(
          id: doc.id,
          name: displayName,
          phone: phone,
          wellId: wellId,
          wellName: _text(data, <String>['wellName']),
          provinceName:
              _text(data, <String>['provinceName']),
          villageName:
              _text(data, <String>['villageName']),
        ),
      );

      if (wellId.isEmpty) continue;

      if (!supervisorByWell.containsKey(wellId)) {
        supervisorByWell[wellId] = displayName;
      }
    }

    // ========================================================
    // المشتركون حسب البئر وحسب القرية
    // ========================================================

    final Map<String, Set<String>> subscribersByWell =
        <String, Set<String>>{};

    final Map<String, Set<String>> subscribersByVillage =
        <String, Set<String>>{};

    final Set<String> linkedCustomers = <String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        doc in wellCustomerDocs) {
      final Map<String, dynamic> data = doc.data();

      final String wellId =
          _text(data, <String>['wellId']);

      final String villageId =
          _text(data, <String>['villageId']);

      final String customerId =
          _text(data, <String>['customerId']);

      final String key =
          customerId.isEmpty ? doc.id : customerId;

      linkedCustomers.add(key);

      if (wellId.isNotEmpty) {
        (subscribersByWell[wellId] ??= <String>{}).add(key);
      }

      if (villageId.isNotEmpty) {
        (subscribersByVillage[villageId] ??=
                <String>{})
            .add(key);
      }
    }

    final int subscriberCount =
        customerDocs.isNotEmpty
            ? customerDocs.length
            : linkedCustomers.length;

    // ========================================================
    // الآبار
    // ========================================================

    final List<GmWellData> wells = <GmWellData>[];

    final Map<String, String> wellIdByName =
        <String, String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        doc in wellDocs) {
      final Map<String, dynamic> data = doc.data();

      final String name = _text(
        data,
        <String>['name', 'wellName', 'wellNumber'],
      );

      final double latitude =
          _number(data, <String>['latitude', 'lat']);

      final double longitude = _number(
        data,
        <String>['longitude', 'lng', 'lon'],
      );

      final bool coordinatesValid =
          _hasValue(data, 'latitude') ||
              _hasValue(data, 'lat');

      final bool hasLongitude =
          _hasValue(data, 'longitude') ||
              _hasValue(data, 'lng') ||
              _hasValue(data, 'lon');

      final bool hasCoordinates =
          coordinatesValid &&
              hasLongitude &&
              latitude >= -90 &&
              latitude <= 90 &&
              longitude >= -180 &&
              longitude <= 180;

      final GmWellData well = GmWellData(
        id: doc.id,
        name: name.isEmpty ? 'بئر بدون اسم' : name,
        provinceId:
            _text(data, <String>['provinceId']),
        provinceName:
            _text(data, <String>['provinceName']),
        districtName:
            _text(data, <String>['districtName']),
        hamletName:
            _text(data, <String>['hamletName']),
        villageId:
            _text(data, <String>['villageId']),
        villageName:
            _text(data, <String>['villageName']),
        latitude: latitude,
        longitude: longitude,
        hasCoordinates: hasCoordinates,
      );

      well.supervisorName =
          supervisorByWell[well.id] ?? '';

      well.subscribers =
          subscribersByWell[well.id]?.length ?? 0;

      wells.add(well);

      if (name.isNotEmpty) {
        wellIdByName[name] = well.id;
      }
    }

    // ========================================================
    // الدورات (الاستهلاك)
    // ========================================================

    final DateTime now = DateTime.now();

    final DateTime currentMonthStart =
        DateTime(now.year, now.month, 1);

    final DateTime nextMonthStart =
        DateTime(now.year, now.month + 1, 1);

    final DateTime previousMonthStart =
        DateTime(now.year, now.month - 1, 1);

    final Map<String, _CycleTotals> wellTotals =
        <String, _CycleTotals>{};

    final Map<DateTime, double> monthlyTotals =
        <DateTime, double>{};

    int closedCycleCount = 0;

    double totalConsumption = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        doc in cycleDocs) {
      final Map<String, dynamic> data = doc.data();

      final String status =
          _text(data, <String>['status']);

      if (!_isClosedStatus(status)) {
        continue;
      }

      final double consumption = _number(
        data,
        <String>['consumption', 'energy_consumption'],
      );

      String wellId =
          _text(data, <String>['wellId']);

      if (wellId.isEmpty) {
        final String wellName =
            _text(data, <String>['wellName']);

        wellId = wellIdByName[wellName] ?? '';
      }

      final DateTime? date = _date(data['endDate']) ??
          _date(data['closedAt']) ??
          _date(data['startDate']) ??
          _date(data['createdAt']);

      closedCycleCount++;
      totalConsumption += consumption;

      if (date != null) {
        final DateTime month =
            DateTime(date.year, date.month);

        monthlyTotals[month] =
            (monthlyTotals[month] ?? 0) + consumption;

        final _CycleTotals totals =
            wellTotals.putIfAbsent(
          wellId,
          () => _CycleTotals(),
        );

        totals.total += consumption;
        totals.count++;

        if (totals.last == null ||
            date.isAfter(totals.last!)) {
          totals.last = date;
        }

        if (!date.isBefore(currentMonthStart) &&
            date.isBefore(nextMonthStart)) {
          totals.current += consumption;
        } else if (!date.isBefore(previousMonthStart) &&
            date.isBefore(currentMonthStart)) {
          totals.previous += consumption;
        }
      } else if (wellId.isNotEmpty) {
        final _CycleTotals totals =
            wellTotals.putIfAbsent(
          wellId,
          () => _CycleTotals(),
        );

        totals.total += consumption;
        totals.count++;
      }
    }

    for (final GmWellData well in wells) {
      final _CycleTotals? totals =
          wellTotals[well.id];

      if (totals == null) continue;

      well.consumption = totals.total;
      well.currentMonthConsumption = totals.current;
      well.previousMonthConsumption =
          totals.previous;
      well.closedCycles = totals.count;
      well.lastCycleDate = totals.last;
    }

    // ========================================================
    // ربط المشرفين ببيانات الآبار
    // ========================================================

    final Map<String, GmWellData> wellById =
        <String, GmWellData>{};

    for (final GmWellData well in wells) {
      wellById[well.id] = well;
    }

    for (final GmSupervisorData supervisor in supervisors) {
      final GmWellData? well =
          wellById[supervisor.wellId];

      if (well == null) continue;

      supervisor.wellName = well.name;

      if (supervisor.provinceName.isEmpty) {
        supervisor.provinceName = well.provinceName;
      }

      if (supervisor.villageName.isEmpty) {
        supervisor.villageName = well.villageName;
      }

      supervisor.consumption = well.consumption;
      supervisor.currentMonthConsumption =
          well.currentMonthConsumption;
      supervisor.previousMonthConsumption =
          well.previousMonthConsumption;
      supervisor.subscribers = well.subscribers;
    }

    supervisors.sort(
      (GmSupervisorData a, GmSupervisorData b) =>
          b.currentMonthConsumption.compareTo(
        a.currentMonthConsumption,
      ),
    );

    // ========================================================
    // القرى
    // ========================================================

    final Map<String, GmVillageData> villageMap =
        <String, GmVillageData>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>>
        doc in villageDocs) {
      final Map<String, dynamic> data = doc.data();

      final String name = _text(
        data,
        <String>['name', 'villageName'],
      );

      villageMap[doc.id] = GmVillageData(
        id: doc.id,
        name: name.isEmpty ? 'قرية بدون اسم' : name,
        provinceId:
            _text(data, <String>['provinceId']),
        provinceName:
            _text(data, <String>['provinceName']),
        districtName:
            _text(data, <String>['districtName']),
        hamletName:
            _text(data, <String>['hamletName']),
      );
    }

    for (final GmWellData well in wells) {
      if (well.villageId.isEmpty) {
        continue;
      }

      final GmVillageData village =
          villageMap.putIfAbsent(
        well.villageId,
        () => GmVillageData(
          id: well.villageId,
          name: well.villageName.isEmpty
              ? 'قرية غير محددة'
              : well.villageName,
          provinceId: well.provinceId,
          provinceName: well.provinceName,
          districtName: well.districtName,
          hamletName: well.hamletName,
        ),
      );

      village.wells.add(well);
    }

    for (final GmVillageData village
        in villageMap.values) {
      double total = 0;
      double current = 0;
      double previous = 0;

      int closed = 0;

      for (final GmWellData well in village.wells) {
        total += well.consumption;
        current += well.currentMonthConsumption;
        previous += well.previousMonthConsumption;
        closed += well.closedCycles;
      }

      village.consumption = total;
      village.currentMonthConsumption = current;
      village.previousMonthConsumption = previous;
      village.closedCycles = closed;

      village.subscribers =
          subscribersByVillage[village.id]?.length ??
              0;

      if (village.subscribers == 0) {
        for (final GmWellData well in village.wells) {
          village.subscribers += well.subscribers;
        }
      }
    }

    // ========================================================
    // الترتيب
    // ========================================================

    wells.sort(
      (GmWellData a, GmWellData b) =>
          b.consumption.compareTo(a.consumption),
    );

    final List<GmVillageData> villages =
        villageMap.values.toList();

    villages.sort(
      (GmVillageData a, GmVillageData b) =>
          b.consumption.compareTo(a.consumption),
    );

    // ========================================================
    // مواقع الخريطة
    // ========================================================

    _assignMapPositions(wells, villages);

    // ========================================================
    // آخر 6 أشهر
    // ========================================================

    final List<GmMonthPoint> monthly =
        <GmMonthPoint>[];

    for (int i = 5; i >= 0; i--) {
      final DateTime month =
          DateTime(now.year, now.month - i, 1);

      monthly.add(
        GmMonthPoint(
          month: month,
          label: gmMonthName(month.month),
          value: monthlyTotals[month] ?? 0,
        ),
      );
    }

    final double currentMonthConsumption =
        monthlyTotals[
                DateTime(now.year, now.month)] ??
            0;

    final double previousMonthConsumption =
        monthlyTotals[DateTime(
              now.year,
              now.month - 1,
            )] ??
            0;

    // ========================================================
    // التنبيهات الذكية
    // ========================================================

    final List<GmInsight> insights = <GmInsight>[];

    final double overallChange =
        previousMonthConsumption <= 0
            ? (currentMonthConsumption > 0 ? 100 : 0)
            : ((currentMonthConsumption -
                        previousMonthConsumption) /
                    previousMonthConsumption) *
                100;

    if (currentMonthConsumption > 0 ||
        previousMonthConsumption > 0) {
      if (currentMonthConsumption <= 0) {
        insights.add(
          GmInsight(
            title: 'لا توجد دورات مغلقة هذا الشهر',
            message:
                'لم تُغلق أي دورة خلال الشهر الحالي بعد. '
                'استهلاك الشهر الماضي كان '
                '${gmFormatNumber(previousMonthConsumption)} م³.',
            level: GmInsightLevel.info,
          ),
        );
      } else if (overallChange >= 10) {
        insights.add(
          GmInsight(
            title: 'ارتفاع في إجمالي الاستهلاك',
            message:
                'ارتفع إجمالي الاستهلاك هذا الشهر بنسبة '
                '${gmFormatPercent(overallChange)} مقارنة بالشهر الماضي '
                '(${gmFormatNumber(currentMonthConsumption)} م³ مقابل '
                '${gmFormatNumber(previousMonthConsumption)} م³).',
            level: GmInsightLevel.warning,
          ),
        );
      } else if (overallChange <= -10) {
        insights.add(
          GmInsight(
            title: 'انخفاض في إجمالي الاستهلاك',
            message:
                'انخفض إجمالي الاستهلاك هذا الشهر بنسبة '
                '${gmFormatPercent(overallChange)} مقارنة بالشهر الماضي '
                '(${gmFormatNumber(currentMonthConsumption)} م³ مقابل '
                '${gmFormatNumber(previousMonthConsumption)} م³).',
            level: GmInsightLevel.success,
          ),
        );
      } else {
        insights.add(
          GmInsight(
            title: 'استهلاك مستقر',
            message:
                'إجمالي استهلاك هذا الشهر قريب من الشهر الماضي '
                '(${gmFormatNumber(currentMonthConsumption)} م³).',
            level: GmInsightLevel.info,
          ),
        );
      }
    }

    final List<GmVillageData> risingVillages = villages
        .where(
          (GmVillageData village) =>
              village.needsAttention,
        )
        .toList()
      ..sort(
        (GmVillageData a, GmVillageData b) =>
            b.changePercent.compareTo(a.changePercent),
      );

    if (risingVillages.isNotEmpty) {
      final GmVillageData top = risingVillages.first;

      insights.add(
        GmInsight(
          title: 'ارتفاع غير طبيعي في قرية',
          message:
              'سجلت قرية ${top.name} ارتفاعاً بنسبة '
              '${gmFormatPercent(top.changePercent)} مقارنة بالشهر الماضي، '
              'وهي تحتاج إلى مراجعة.',
          level: GmInsightLevel.warning,
        ),
      );
    }

    final List<GmWellData> reviewWells = wells
        .where((GmWellData well) => well.needsReview)
        .toList()
      ..sort(
        (GmWellData a, GmWellData b) =>
            b.changePercent.compareTo(a.changePercent),
      );

    if (reviewWells.isNotEmpty) {
      insights.add(
        GmInsight(
          title: 'آبار تحتاج إلى مراجعة',
          message:
              '${_joinWellNames(reviewWells)} سجلت ارتفاعاً في الاستهلاك '
              'يتجاوز 30% مقارنة بالشهر الماضي.',
          level: GmInsightLevel.danger,
        ),
      );
    }

    final List<GmWellData> withoutSupervisor = wells
        .where((GmWellData well) => !well.hasSupervisor)
        .toList();

    if (withoutSupervisor.isNotEmpty) {
      insights.add(
        GmInsight(
          title: 'آبار بدون مشرف',
          message:
              '${_joinWellNames(withoutSupervisor)} '
              'لا يوجد لها مشرف مرتبط، أضف مشرفاً من تهيئة المشرفين.',
          level: GmInsightLevel.warning,
        ),
      );
    }

    if (wells.isNotEmpty) {
      final DateTime nowDate = DateTime.now();

      final List<GmWellData> stale = wells
          .where((GmWellData well) {
            if (well.lastCycleDate == null) return true;

            return nowDate
                    .difference(well.lastCycleDate!)
                    .inDays >
                45;
          })
          .toList();

      if (stale.isNotEmpty) {
        insights.add(
          GmInsight(
            title: 'مناطق تحتاج إلى متابعة ميدانية',
            message:
                '${_joinWellNames(stale)} ليس لها دورة مغلقة خلال آخر 45 يوماً.',
            level: GmInsightLevel.info,
          ),
        );
      }
    }

    GmWellData? topWellThisMonth;

    for (final GmWellData well in wells) {
      if (well.currentMonthConsumption <= 0) {
        continue;
      }

      if (topWellThisMonth == null ||
          well.currentMonthConsumption >
              topWellThisMonth.currentMonthConsumption) {
        topWellThisMonth = well;
      }
    }

    if (topWellThisMonth != null) {
      insights.add(
        GmInsight(
          title: 'أعلى بئر هذا الشهر',
          message:
              '${topWellThisMonth.name} هو الأعلى استهلاكاً هذا الشهر '
              'بمقدار ${gmFormatNumber(topWellThisMonth.currentMonthConsumption)} م³.',
          level: GmInsightLevel.info,
        ),
      );
    }

    if (closedCycleCount == 0) {
      insights.add(
        const GmInsight(
          title: 'لا توجد دورات مغلقة بعد',
          message:
              'ستظهر المؤشرات والتحليلات بعد إغلاق أول دورة قراءة.',
          level: GmInsightLevel.info,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const GmInsight(
          title: 'كل شيء طبيعي',
          message:
              'لا توجد تنبيهات حالياً على استهلاك الآبار أو القرى.',
          level: GmInsightLevel.success,
        ),
      );
    }

    return GmDashboardData(
      provinceCount: provinceDocs.length,
      districtCount: districtDocs.length,
      hamletCount: hamletDocs.length,
      villageCount: villages.length,
      wellCount: wells.length,
      supervisorCount: supervisorCount,
      subscriberCount: subscriberCount,
      linkedSubscriberCount: linkedCustomers.length,
      closedCycleCount: closedCycleCount,
      totalConsumption: totalConsumption,
      currentMonthConsumption:
          currentMonthConsumption,
      previousMonthConsumption:
          previousMonthConsumption,
      monthly: monthly,
      wells: wells,
      villages: villages,
      supervisors: supervisors,
      insights: insights,
      hasCoordinates: wells
          .any((GmWellData well) => well.hasCoordinates),
      generatedAt: now,
      warnings: warnings,
    );
  }

  // ============================================================
  // قراءة الدورات (الأحدث أولاً)
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadCycles(List<String> warnings) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await firestore
              .collection('cycles')
              .orderBy('startDate', descending: true)
              .limit(_cycleLimit)
              .get();

      return snapshot.docs;
    } catch (_) {
      // ------------------------------------------------------
      // في حال عدم توفر فهرس أو حقل startDate
      // ------------------------------------------------------

      try {
        final QuerySnapshot<Map<String, dynamic>>
            snapshot = await firestore
                .collection('cycles')
                .limit(_cycleLimit)
                .get();

        return snapshot.docs;
      } catch (error) {
        warnings.add('تعذر تحميل الدورات');

        return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      }
    }
  }

  // ============================================================
  // قراءة مجموعة
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _docs(
    String collection,
    List<String> warnings,
    String label,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await firestore.collection(collection).get();

      return snapshot.docs;
    } catch (error) {
      warnings.add('تعذر تحميل $label');

      return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }
  }

  // ============================================================
  // مواقع تقريبية على الخريطة
  // ============================================================

  void _assignMapPositions(
    List<GmWellData> wells,
    List<GmVillageData> villages,
  ) {
    final List<GmWellData> geoWells = wells
        .where((GmWellData well) => well.hasCoordinates)
        .toList();

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;

    for (final GmWellData well in geoWells) {
      minLat = minLat == null
          ? well.latitude
          : math.min(minLat, well.latitude);
      maxLat = maxLat == null
          ? well.latitude
          : math.max(maxLat, well.latitude);
      minLng = minLng == null
          ? well.longitude
          : math.min(minLng, well.longitude);
      maxLng = maxLng == null
          ? well.longitude
          : math.max(maxLng, well.longitude);
    }

    final bool geographic = geoWells.length >= 2;

    if (geographic &&
        minLat != null &&
        maxLat != null &&
        minLng != null &&
        maxLng != null) {
      final double latSpan =
          (maxLat - minLat).abs() < 0.0001
              ? 1.0
              : (maxLat - minLat).abs();

      final double lngSpan =
          (maxLng - minLng).abs() < 0.0001
              ? 1.0
              : (maxLng - minLng).abs();

      for (final GmWellData well in wells) {
        if (!well.hasCoordinates) continue;

        well.mapX = _clampUnit(
          (well.longitude - minLng) / lngSpan,
        );

        well.mapY = _clampUnit(
          1 - (well.latitude - minLat) / latSpan,
        );
      }
    }

    // تجميع القرى حسب المحافظة
    final Map<String, List<GmVillageData>> groups =
        <String, List<GmVillageData>>{};

    for (final GmVillageData village in villages) {
      final String key = village.provinceId.isEmpty
          ? 'غير محدد'
          : village.provinceId;

      (groups[key] ??= <GmVillageData>[]).add(village);

      // ------------------------------------------------------
      // موقع القرية = متوسط مواقع آبارها ذات الإحداثيات
      // ------------------------------------------------------

      final List<GmWellData> positioned = village.wells
          .where((GmWellData well) => well.hasCoordinates)
          .toList();

      if (positioned.isNotEmpty) {
        double sumX = 0;
        double sumY = 0;

        for (final GmWellData well in positioned) {
          sumX += well.mapX;
          sumY += well.mapY;
        }

        village.mapX =
            _clampUnit(sumX / positioned.length);

        village.mapY =
            _clampUnit(sumY / positioned.length);
      }
    }

    final List<String> keys =
        groups.keys.toList()..sort();

    for (int p = 0; p < keys.length; p++) {
      final List<GmVillageData> group =
          groups[keys[p]]!;

      final double provinceAngle = keys.length <= 1
          ? 0
          : (2 * math.pi * p / keys.length) -
              (math.pi / 2);

      final double provinceRadius =
          keys.length <= 1 ? 0 : 0.27;

      final double centerX =
          0.5 + provinceRadius * math.cos(provinceAngle);

      final double centerY =
          0.5 + provinceRadius * math.sin(provinceAngle);

      for (int v = 0; v < group.length; v++) {
        final GmVillageData village = group[v];

        if (village.mapX < 0 || village.mapY < 0) {
          final double villageAngle =
              group.length <= 1
                  ? 0
                  : (2 * math.pi * v / group.length) +
                      (p * 0.7);

          final double villageRadius =
              group.length <= 1 ? 0 : 0.115;

          village.mapX = _clampUnit(
            centerX +
                villageRadius *
                    math.cos(villageAngle),
          );

          village.mapY = _clampUnit(
            centerY +
                villageRadius *
                    math.sin(villageAngle),
          );
        }

        for (int i = 0;
            i < village.wells.length;
            i++) {
          final GmWellData well = village.wells[i];

          if (well.hasCoordinates) continue;

          final double wellAngle =
              (2 * math.pi * i /
                      math.max(village.wells.length, 1)) +
                  0.5;

          final double wellRadius =
              0.032 + 0.02 * (i ~/ 8);

          well.mapX = _clampUnit(
            village.mapX +
                wellRadius * math.cos(wellAngle),
          );

          well.mapY = _clampUnit(
            village.mapY +
                wellRadius * math.sin(wellAngle),
          );
        }
      }
    }

    // آبار بلا قرية
    final List<GmWellData> orphans = wells
        .where(
          (GmWellData well) =>
              well.mapX < 0 || well.mapY < 0,
        )
        .toList();

    for (int i = 0; i < orphans.length; i++) {
      final double angle =
          2 * math.pi * i / math.max(orphans.length, 1);

      orphans[i].mapX = _clampUnit(
        0.5 + 0.40 * math.cos(angle),
      );

      orphans[i].mapY = _clampUnit(
        0.5 + 0.40 * math.sin(angle),
      );
    }
  }

  double _clampUnit(double value) {
    return value.clamp(0.06, 0.94).toDouble();
  }

  // ============================================================
  // قراءة الحقول
  // ============================================================

  static String _text(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) continue;

      final String text = value.toString().trim();

      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }

    return '';
  }

  static double _number(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value != null) {
        final double? parsed =
            double.tryParse(value.toString().trim());

        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  static bool _hasValue(
    Map<String, dynamic> data,
    String key,
  ) {
    if (!data.containsKey(key)) return false;

    final dynamic value = data[key];

    if (value == null) return false;

    if (value is num) return true;

    return value.toString().trim().isNotEmpty;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    return DateTime.tryParse(value.toString());
  }

  static bool _isClosedStatus(String status) {
    final String value =
        status.trim().toLowerCase();

    if (value.isEmpty) return false;

    return value == 'مغلق' ||
        value == 'closed' ||
        value == 'منتهي' ||
        value == 'مكتمل' ||
        value.contains('مغلق') ||
        value.contains('closed');
  }

  static String _joinWellNames(
    List<GmWellData> wells, {
    int max = 3,
  }) {
    final List<String> names = wells
        .take(max)
        .map((GmWellData well) => well.name)
        .toList();

    if (wells.length > max) {
      names.add('و${wells.length - max} آبار أخرى');
    }

    return names.join('، ');
  }
}

// ============================================================
// المساعد الذكي (إجابات من بيانات النظام)
// ============================================================

class GmAssistant {
  static String answer(
    String question,
    GmDashboardData data,
  ) {
    final String query = _normalize(question);

    if (query.isEmpty) {
      return 'اكتب سؤالاً عن الآبار أو القرى أو الاستهلاك.';
    }

    if (_hasAny(query, <String>[
      'اعلي',
      'اكثر',
    ]) &&
        _hasAny(query, <String>['بئر', 'ابار'])) {
      return _topWellAnswer(data);
    }

    if (_hasAny(query, <String>[
      'اعلي',
      'اكثر',
    ]) &&
        _hasAny(query, <String>['قريه', 'قري'])) {
      return _topVillageAnswer(data);
    }

    if (_hasAny(query, <String>[
      'ارتفع',
      'ارتفاع',
      'زاد',
      'زياده',
      'مقارنه',
      'مقارنة',
    ]) &&
        _hasAny(query, <String>['قريه', 'قري'])) {
      return _risingVillagesAnswer(data);
    }

    if (_hasAny(query, <String>[
      'مراجعه',
      'مراجعة',
      'تحتاج',
      'خطير',
      'تنبيه',
      'تنبيهات',
      'غير طبيعي',
    ])) {
      return _reviewAnswer(data);
    }

    if (_hasAny(query, <String>[
      'سته اشهر',
      'ست اشهر',
      'ست شهور',
      '6 اشهر',
      '6 شهور',
      'اخر 6',
      'اخر سته',
      'اشهر',
      'شهور',
      'تغير',
      'اتجاه',
      'ترند',
    ])) {
      return _trendAnswer(data);
    }

    if (_hasAny(query, <String>[
      'مشترك',
      'مشتركين',
      'زبون',
      'زباين',
    ])) {
      return _subscribersAnswer(data);
    }

    if (_hasAny(query, <String>['مشرف', 'مشرفين'])) {
      return _supervisorsAnswer(data);
    }

    if (_hasAny(query, <String>[
      'قارن',
      'مقارنه',
      'مقارنة',
      'افضل',
      'ترتيب',
    ])) {
      return _comparisonAnswer(data);
    }

    if (_hasAny(query, <String>[
      'كم',
      'عدد',
      'احصائ',
      'اجمالي',
      'ملخص',
      'وضع',
    ])) {
      return _summaryAnswer(data);
    }

    if (_hasAny(query, <String>[
      'اين',
      'موقع',
      'خريطه',
      'خريطة',
    ])) {
      return _locationAnswer(data);
    }

    return '${_summaryAnswer(data)}\n\n'
        'يمكنك أيضاً السؤال عن: أعلى بئر، أعلى قرية، '
        'الآبار التي تحتاج مراجعة، أو اتجاه الاستهلاك.';
  }

  // ==========================================================
  // الإجابات
  // ==========================================================

  static String _topWellAnswer(GmDashboardData data) {
    final GmWellData? well = data.topWellThisMonth;

    if (well == null) {
      return 'لا توجد قراءات مغلقة هذا الشهر بعد. '
          '${data.topWell != null ? 'أعلى بئر إجمالاً هو ${data.topWell!.name} بمقدار ${gmFormatNumber(data.topWell!.consumption)} م³.' : ''}';
    }

    final StringBuffer buffer = StringBuffer();

    buffer.writeln(
      'أعلى بئر استهلاكاً هذا الشهر هو "${well.name}" '
      'بمقدار ${gmFormatNumber(well.currentMonthConsumption)} م³.',
    );

    if (well.villageName.isNotEmpty) {
      buffer.writeln('القرية: ${well.villageName}');
    }

    buffer.writeln(
      'المشرف: ${well.hasSupervisor ? well.supervisorName : 'غير مرتبط'}',
    );

    if (well.previousMonthConsumption > 0) {
      buffer.writeln(
        'مقارنة بالشهر الماضي: ${gmFormatPercent(well.changePercent)}',
      );
    }

    return buffer.toString().trim();
  }

  static String _topVillageAnswer(
    GmDashboardData data,
  ) {
    final GmVillageData? village = data.villages.isEmpty
        ? null
        : (data.villages.toList()
              ..sort(
                (GmVillageData a, GmVillageData b) =>
                    b.currentMonthConsumption.compareTo(
                  a.currentMonthConsumption,
                ),
              ))
            .first;

    if (village == null) {
      return 'لا توجد قرى مسجلة بعد.';
    }

    final StringBuffer buffer = StringBuffer();

    buffer.writeln(
      'أعلى قرية استهلاكاً هذا الشهر هي "${village.name}" '
      'بمقدار ${gmFormatNumber(village.currentMonthConsumption)} م³.',
    );

    buffer.writeln(
      'عدد الآبار: ${village.wellCount} — '
      'المشتركون: ${gmFormatNumber(village.subscribers)}',
    );

    if (village.previousMonthConsumption > 0) {
      buffer.writeln(
        'مقارنة بالشهر الماضي: ${gmFormatPercent(village.changePercent)}',
      );
    }

    return buffer.toString().trim();
  }

  static String _risingVillagesAnswer(
    GmDashboardData data,
  ) {
    final List<GmVillageData> rising = data.villagesRising;

    if (rising.isEmpty) {
      return 'لا توجد قرى سجلت ارتفاعاً يتجاوز 20% '
          'مقارنة بالشهر الماضي حتى الآن.';
    }

    final StringBuffer buffer = StringBuffer(
      'القرى التي ارتفع استهلاكها مقارنة بالشهر الماضي:',
    );

    for (final GmVillageData village in rising.take(5)) {
      buffer.writeln(
        '\n• ${village.name}: '
        '${gmFormatPercent(village.changePercent)} '
        '(${gmFormatNumber(village.currentMonthConsumption)} م³)',
      );
    }

    return buffer.toString().trim();
  }

  static String _reviewAnswer(GmDashboardData data) {
    final List<GmWellData> review =
        data.wellsNeedingReview;

    final List<GmWellData> withoutSupervisor =
        data.wellsWithoutSupervisor;

    final List<String> parts = <String>[];

    if (review.isEmpty) {
      parts.add(
        'لا توجد آبار تجاوزت نسبة الارتفاع 30% '
        'مقارنة بالشهر الماضي.',
      );
    } else {
      final StringBuffer buffer = StringBuffer(
        'الآبار التي تحتاج إلى مراجعة:',
      );

      for (final GmWellData well in review.take(5)) {
        buffer.writeln(
          '\n• ${well.name}: '
          '${gmFormatPercent(well.changePercent)} '
          '(${gmFormatNumber(well.currentMonthConsumption)} م³)',
        );
      }

      parts.add(buffer.toString().trim());
    }

    if (withoutSupervisor.isNotEmpty) {
      parts.add(
        'آبار بدون مشرف: '
        '${withoutSupervisor.take(5).map((GmWellData well) => well.name).join('، ')}',
      );
    }

    final List<GmWellData> stale = data.staleWells;

    if (stale.isNotEmpty) {
      parts.add(
        'بحاجة إلى متابعة ميدانية: '
        '${stale.take(5).map((GmWellData well) => well.name).join('، ')}',
      );
    }

    return parts.join('\n\n');
  }

  static String _trendAnswer(GmDashboardData data) {
    if (data.closedCycleCount == 0) {
      return 'لا توجد دورات مغلقة بعد، لذلك لا يمكن '
          'حساب اتجاه الاستهلاك.';
    }

    final StringBuffer buffer = StringBuffer(
      'استهلاك المياه خلال الأشهر الستة الماضية:',
    );

    for (final GmMonthPoint point in data.monthly) {
      buffer.writeln(
        '\n• ${point.label} ${point.month.year}: '
        '${gmFormatNumber(point.value)} م³',
      );
    }

    final double change = data.overallChangePercent;

    buffer.writeln(
      '\n\nالاتجاه الحالي: ${change >= 0 ? 'ارتفاع' : 'انخفاض'} '
      'بنسبة ${gmFormatPercent(change)} مقارنة بالشهر الماضي.',
    );

    return buffer.toString().trim();
  }

  static String _subscribersAnswer(
    GmDashboardData data,
  ) {
    return 'إجمالي المشتركين في النظام: '
        '${gmFormatNumber(data.subscriberCount)} مشترك.\n'
        'المشتركون المرتبطون بآبار: '
        '${gmFormatNumber(data.linkedSubscriberCount)}.\n'
        'عدد الآبار: ${gmFormatNumber(data.wellCount)} — '
        'عدد القرى: ${gmFormatNumber(data.villageCount)}.';
  }

  static String _supervisorsAnswer(
    GmDashboardData data,
  ) {
    final List<GmWellData> withoutSupervisor =
        data.wellsWithoutSupervisor;

    final StringBuffer buffer = StringBuffer(
      'عدد المشرفين المسجلين: '
      '${gmFormatNumber(data.supervisorCount)}.',
    );

    if (withoutSupervisor.isEmpty) {
      buffer.writeln(
        '\nكل الآبار مرتبطة بمشرفين.',
      );
    } else {
      buffer.writeln(
        '\nآبار بدون مشرف (${withoutSupervisor.length}): '
        '${withoutSupervisor.take(6).map((GmWellData well) => well.name).join('، ')}',
      );
    }

    return buffer.toString().trim();
  }

  static String _comparisonAnswer(
    GmDashboardData data,
  ) {
    final List<GmWellData> wells = data.topWells(5);

    if (wells.isEmpty) {
      return 'لا توجد آبار مسجلة للمقارنة.';
    }

    final StringBuffer buffer = StringBuffer(
      'مقارنة استهلاك الآبار (الأعلى استهلاكاً):',
    );

    for (int i = 0; i < wells.length; i++) {
      final GmWellData well = wells[i];

      buffer.writeln(
        '\n${i + 1}. ${well.name}: '
        '${gmFormatNumber(well.consumption)} م³',
      );
    }

    buffer.writeln(
      '\n\nإجمالي استهلاك هذا الشهر: '
      '${gmFormatNumber(data.currentMonthConsumption)} م³.',
    );

    return buffer.toString().trim();
  }

  static String _summaryAnswer(
    GmDashboardData data,
  ) {
    final StringBuffer buffer = StringBuffer(
      'ملخص النظام الحالي:',
    );

    buffer.writeln(
      '\n• المحافظات: ${gmFormatNumber(data.provinceCount)} — '
      'المديريات: ${gmFormatNumber(data.districtCount)} — '
      'العُزل: ${gmFormatNumber(data.hamletCount)}',
    );

    buffer.writeln(
      '• القرى: ${gmFormatNumber(data.villageCount)} — '
      'الآبار: ${gmFormatNumber(data.wellCount)}',
    );

    buffer.writeln(
      '• المشرفون: ${gmFormatNumber(data.supervisorCount)} — '
      'المشتركون: ${gmFormatNumber(data.subscriberCount)}',
    );

    buffer.writeln(
      '• إجمالي الاستهلاك: '
      '${gmFormatNumber(data.totalConsumption)} م³',
    );

    buffer.writeln(
      '• استهلاك هذا الشهر: '
      '${gmFormatNumber(data.currentMonthConsumption)} م³ '
      '(${gmFormatPercent(data.overallChangePercent)} مقارنة بالشهر الماضي)',
    );

    final GmWellData? topWell = data.topWellThisMonth;

    if (topWell != null) {
      buffer.writeln(
        '• أعلى بئر هذا الشهر: ${topWell.name} '
        '(${gmFormatNumber(topWell.currentMonthConsumption)} م³)',
      );
    }

    return buffer.toString().trim();
  }

  static String _locationAnswer(
    GmDashboardData data,
  ) {
    final int positioned =
        data.wellsWithCoordinates.length;

    final int total = data.wellCount;

    final StringBuffer buffer = StringBuffer(
      'يمكنك فتح تبويب "الخريطة" لمشاهدة مواقع الآبار والقرى '
      'ومؤشرات الاستهلاك لكل موقع.',
    );

    buffer.writeln(
      '\n\nالآبار ذات الإحداثيات: $positioned من $total.',
    );

    if (positioned < total) {
      buffer.writeln(
        'الآبار بدون إحداثيات تظهر بموقع تخطيطي، '
        'ويمكنك تحديد موقعها من بطاقة البئر على الخريطة.',
      );
    }

    return buffer.toString().trim();
  }

  // ==========================================================
  // أدوات النص
  // ==========================================================

  static String _normalize(String value) {
    return value
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '')
        .trim()
        .toLowerCase();
  }

  static bool _hasAny(
    String query,
    List<String> words,
  ) {
    for (final String word in words) {
      if (query.contains(word)) return true;
    }

    return false;
  }
}
