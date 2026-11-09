import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// أدوار المشرف الرئيسي — انتقلت إلى gm_roles.dart
// ============================================================
//
// الفئة هنا تُعاد تصديرها فقط، حتى تبقى كل الاستيرادات القديمة
// (import 'gm_dashboard_service.dart') تعمل كما هي.
//
// السبب: هذا الملف يستورد cloud_firestore، وشاشة الدخول تحتاج
// فحص الدور وحده — فصارت تستورد gm_roles.dart الصغير.
// ============================================================

export 'gm_roles.dart';

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

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String gmMonthName(int month) {
  if (month < 1 || month > 12) return '';

  return _monthNames[month - 1];
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
    if (!hasCoordinates) return 'Not set';

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
        _docs('provinces', warnings, 'Governorates'),
        _docs('districts', warnings, 'Districts'),
        _docs('hamlets', warnings, 'Sub-districts'),
        _docs('villages', warnings, 'Villages'),
        _docs('wells', warnings, 'Wells'),
        _docs('users', warnings, 'Supervisors'),
        _docs('customers', warnings, 'Subscribers'),
        _docs('well_customers', warnings, 'Subscriber links'),
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
          : (phone.isNotEmpty ? phone : 'Supervisor');

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
        name: name.isEmpty ? 'Unnamed well' : name,
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
        name: name.isEmpty ? 'Unnamed village' : name,
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
              ? 'Village not set'
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
            title: 'No closed cycles this month',
            message:
                'No cycle has been closed this month yet. '
                'Last month the consumption was '
                '${gmFormatNumber(previousMonthConsumption)} m³.',
            level: GmInsightLevel.info,
          ),
        );
      } else if (overallChange >= 10) {
        insights.add(
          GmInsight(
            title: 'Total consumption is up',
            message:
                'Total consumption rose by '
                '${gmFormatPercent(overallChange)} against last month '
                '(${gmFormatNumber(currentMonthConsumption)} m³ vs '
                '${gmFormatNumber(previousMonthConsumption)} m³).',
            level: GmInsightLevel.warning,
          ),
        );
      } else if (overallChange <= -10) {
        insights.add(
          GmInsight(
            title: 'Total consumption is down',
            message:
                'Total consumption fell by '
                '${gmFormatPercent(overallChange)} against last month '
                '(${gmFormatNumber(currentMonthConsumption)} m³ vs '
                '${gmFormatNumber(previousMonthConsumption)} m³).',
            level: GmInsightLevel.success,
          ),
        );
      } else {
        insights.add(
          GmInsight(
            title: 'Consumption is steady',
            message:
                'This month is close to last month '
                '(${gmFormatNumber(currentMonthConsumption)} m³).',
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
          title: 'Abnormal rise in a village',
          message:
              '${top.name} is up '
              '${gmFormatPercent(top.changePercent)} against last month '
              'and needs a review.',
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
          title: 'Wells needing review',
          message:
              '${_joinWellNames(reviewWells)} rose more than 30% '
              'against last month.',
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
          title: 'Wells without a supervisor',
          message:
              '${_joinWellNames(withoutSupervisor)} '
              'has no linked supervisor — add one in Supervisor Setup.',
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
            title: 'Areas needing a field visit',
            message:
                '${_joinWellNames(stale)} has had no closed cycle in 45 days.',
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
          title: 'Top well this month',
          message:
              '${topWellThisMonth.name} leads this month '
              'with ${gmFormatNumber(topWellThisMonth.currentMonthConsumption)} m³.',
          level: GmInsightLevel.info,
        ),
      );
    }

    if (closedCycleCount == 0) {
      insights.add(
        const GmInsight(
          title: 'No closed cycles yet',
          message:
              'Figures and analysis appear once the first reading cycle closes.',
          level: GmInsightLevel.info,
        ),
      );
    }

    if (insights.isEmpty) {
      insights.add(
        const GmInsight(
          title: 'Everything looks normal',
          message:
              'No alerts on well or village consumption right now.',
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
        warnings.add('Could not load the cycles');

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
      warnings.add('Could not load $label');

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
          ? 'Not set'
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
      names.add('and ${wells.length - max} more wells');
    }

    return names.join(', ');
  }
}
