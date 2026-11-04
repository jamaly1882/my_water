// ============================================================
// supervisor_insight_service.dart
// تحليل ذكي لكل مشرف بئر — محلي بالكامل، بلا خدمة خارجية.
//
// يقرأ: users (المشرفون) · wells · customers · well_customers · cycles
// ويحسب لكل مشرف: النشاط، الانتظام، التغطية، جودة البيانات
// ثم يترجمها إلى درجة من 100، وقراءة نصية، ومخاطر، وخطوات مقترحة.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// مؤشرات المشرف الخام
// ============================================================

class SupervisorKpi {
  final String id;
  final String name;
  final String phone;
  final String wellId;

  String wellName;
  String villageName;
  String provinceName;

  int subscribers;
  int closedCycles;
  int cyclesLast90;

  double consumption;
  double lastCycleConsumption;

  DateTime? lastCycleDate;

  SupervisorKpi({
    required this.id,
    required this.name,
    this.phone = '',
    this.wellId = '',
    this.wellName = '',
    this.villageName = '',
    this.provinceName = '',
    this.subscribers = 0,
    this.closedCycles = 0,
    this.cyclesLast90 = 0,
    this.consumption = 0,
    this.lastCycleConsumption = 0,
    this.lastCycleDate,
  });

  bool get hasWell => wellId.trim().isNotEmpty;

  bool get hasPhone => phone.trim().isNotEmpty;

  /// عدد الأيام منذ آخر دورة مغلقة (null إن لم توجد دورة).
  int? get daysSinceLastCycle {
    if (lastCycleDate == null) return null;

    return DateTime.now().difference(lastCycleDate!).inDays;
  }

  String get locationLabel {
    final List<String> parts = <String>[];

    if (villageName.trim().isNotEmpty) parts.add(villageName.trim());
    if (provinceName.trim().isNotEmpty) parts.add(provinceName.trim());

    return parts.join(' · ');
  }
}

// ============================================================
// نتيجة التحليل
// ============================================================

class SupervisorScore {
  final SupervisorKpi kpi;

  /// الدرجة الكلية 0..100
  final int total;

  /// المكوّنات
  final int activity; // 30
  final int regularity; // 25
  final int coverage; // 25
  final int dataQuality; // 20

  /// التصنيف: متميز · جيد · يحتاج متابعة · خطر
  final String grade;

  /// سطر واحد يقرأ الحالة
  final String headline;

  final List<String> strengths;
  final List<String> risks;
  final List<String> actions;

  const SupervisorScore({
    required this.kpi,
    required this.total,
    required this.activity,
    required this.regularity,
    required this.coverage,
    required this.dataQuality,
    required this.grade,
    required this.headline,
    required this.strengths,
    required this.risks,
    required this.actions,
  });

  /// لون التصنيف يُحدَّد في الواجهة.
  bool get needsFollowUp => total < 70;
}

class SupervisorInsightResult {
  final List<SupervisorScore> scores;
  final int supervisorCount;
  final int needsFollowUp;
  final int withoutCycles;
  final double averageScore;
  final List<String> warnings;
  final DateTime generatedAt;

  const SupervisorInsightResult({
    required this.scores,
    required this.supervisorCount,
    required this.needsFollowUp,
    required this.withoutCycles,
    required this.averageScore,
    required this.warnings,
    required this.generatedAt,
  });
}

// ============================================================
// الخدمة
// ============================================================

class SupervisorInsightService {
  SupervisorInsightService({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  static const int _cycleLimit = 500;

  Future<SupervisorInsightResult> load() async {
    final List<String> warnings = <String>[];

    final List<Map<String, dynamic>> users =
        await _docs('users', warnings, 'supervisors');
    final List<Map<String, dynamic>> wells =
        await _docs('wells', warnings, 'wells');
    final List<Map<String, dynamic>> links =
        await _docs('well_customers', warnings, 'subscriber links');
    final List<Map<String, dynamic>> cycles =
        await _cycles(warnings);

    // ------------------------------------------------------
    // الآبار: اسم + قرية + محافظة
    // ------------------------------------------------------
    final Map<String, Map<String, String>> wellInfo =
        <String, Map<String, String>>{};

    for (final Map<String, dynamic> data in wells) {
      final String id = _id(data);

      if (id.isEmpty) continue;

      wellInfo[id] = <String, String>{
        'name': _text(data, <String>['name', 'wellName']),
        'village': _text(data, <String>['villageName']),
        'province': _text(data, <String>['provinceName']),
      };
    }

    // ------------------------------------------------------
    // المشتركون لكل بئر
    // ------------------------------------------------------
    final Map<String, Set<String>> subscribersByWell =
        <String, Set<String>>{};

    for (final Map<String, dynamic> data in links) {
      final String wellId = _text(data, <String>['wellId']);

      if (wellId.isEmpty) continue;

      final String customerId =
          _text(data, <String>['customerId', 'id']);

      (subscribersByWell[wellId] ??= <String>{}).add(
        customerId.isEmpty ? wellId : customerId,
      );
    }

    // ------------------------------------------------------
    // الدورات: عدد + استهلاك + آخر تاريخ لكل بئر
    // ------------------------------------------------------
    final DateTime now = DateTime.now();
    final DateTime last90 = now.subtract(const Duration(days: 90));

    final Map<String, int> cyclesByWell = <String, int>{};
    final Map<String, int> cycles90ByWell = <String, int>{};
    final Map<String, double> consumptionByWell = <String, double>{};
    final Map<String, double> lastConsumptionByWell = <String, double>{};
    final Map<String, DateTime> lastDateByWell = <String, DateTime>{};

    for (final Map<String, dynamic> data in cycles) {
      final String wellId = _text(data, <String>['wellId']);

      if (wellId.isEmpty) continue;

      final double consumption = _number(
        data,
        <String>['consumption', 'energy_consumption', 'totalConsumption'],
      );

      final DateTime? date = _date(data['endDate']) ??
          _date(data['closedAt']) ??
          _date(data['startDate']) ??
          _date(data['createdAt']);

      cyclesByWell[wellId] = (cyclesByWell[wellId] ?? 0) + 1;
      consumptionByWell[wellId] =
          (consumptionByWell[wellId] ?? 0) + consumption;

      if (date != null && !date.isBefore(last90)) {
        cycles90ByWell[wellId] = (cycles90ByWell[wellId] ?? 0) + 1;
      }

      final DateTime? previous = lastDateByWell[wellId];

      if (date != null && (previous == null || date.isAfter(previous))) {
        lastDateByWell[wellId] = date;
        lastConsumptionByWell[wellId] = consumption;
      }
    }

    // ------------------------------------------------------
    // بناء مؤشرات كل مشرف
    // ------------------------------------------------------
    final List<SupervisorKpi> kpis = <SupervisorKpi>[];

    for (final Map<String, dynamic> data in users) {
      final String role =
          _text(data, <String>['role']).trim().toLowerCase();

      final bool isSupervisor = role == 'supervisor' ||
          role == 'well_supervisor' ||
          role == 'مشرف';

      if (!isSupervisor) continue;
      if (data['active'] == false) continue;

      final String wellId = _text(data, <String>['wellId']);

      final String name = _text(
        data,
        <String>['name', 'fullName', 'supervisorName', 'username'],
      );

      final String phone = _text(
        data,
        <String>['phone', 'username', 'mobile'],
      );

      final Map<String, String>? info = wellInfo[wellId];

      kpis.add(
        SupervisorKpi(
          id: _id(data),
          name: name.isNotEmpty
              ? name
              : (phone.isNotEmpty ? phone : 'Unnamed supervisor'),
          phone: phone,
          wellId: wellId,
          wellName: info?['name'] ?? '',
          villageName: info?['village'] ?? '',
          provinceName: info?['province'] ?? '',
          subscribers: subscribersByWell[wellId]?.length ?? 0,
          closedCycles: cyclesByWell[wellId] ?? 0,
          cyclesLast90: cycles90ByWell[wellId] ?? 0,
          consumption: consumptionByWell[wellId] ?? 0,
          lastCycleConsumption: lastConsumptionByWell[wellId] ?? 0,
          lastCycleDate: lastDateByWell[wellId],
        ),
      );
    }

    // ------------------------------------------------------
    // التحليل
    // ------------------------------------------------------
    final List<SupervisorScore> scores =
        kpis.map(_analyze).toList();

    scores.sort((SupervisorScore a, SupervisorScore b) {
      return a.total.compareTo(b.total);
    });

    final int needsFollowUp =
        scores.where((SupervisorScore s) => s.needsFollowUp).length;

    final int withoutCycles = scores
        .where((SupervisorScore s) => s.kpi.closedCycles == 0)
        .length;

    final double average = scores.isEmpty
        ? 0
        : scores.fold<int>(
              0,
              (int sum, SupervisorScore s) => sum + s.total,
            ) /
            scores.length;

    return SupervisorInsightResult(
      scores: scores,
      supervisorCount: scores.length,
      needsFollowUp: needsFollowUp,
      withoutCycles: withoutCycles,
      averageScore: average,
      warnings: warnings,
      generatedAt: DateTime.now(),
    );
  }

  // ==========================================================
  // التحليل الفردي
  // ==========================================================

  SupervisorScore _analyze(SupervisorKpi kpi) {
    // ------------------------------------------------------
    // 1) النشاط (30): قرب آخر دورة مغلقة
    // ------------------------------------------------------
    final int? days = kpi.daysSinceLastCycle;
    final int activity;

    if (days == null) {
      activity = 0;
    } else if (days <= 7) {
      activity = 30;
    } else if (days <= 14) {
      activity = 24;
    } else if (days <= 30) {
      activity = 16;
    } else if (days <= 60) {
      activity = 8;
    } else {
      activity = 0;
    }

    // ------------------------------------------------------
    // 2) الانتظام (25): عدد الدورات في 90 يوماً
    // ------------------------------------------------------
    final int cycles90 = kpi.cyclesLast90;
    final int regularity;

    if (cycles90 >= 3) {
      regularity = 25;
    } else if (cycles90 == 2) {
      regularity = 18;
    } else if (cycles90 == 1) {
      regularity = 10;
    } else {
      regularity = 0;
    }

    // ------------------------------------------------------
    // 3) التغطية (25): مشتركون مربوطون + دورة فيها استهلاك
    // ------------------------------------------------------
    int coverage = 0;

    if (kpi.subscribers > 0) coverage += 10;
    if (kpi.subscribers >= 15) coverage += 5;
    if (kpi.closedCycles > 0) coverage += 4;
    if (kpi.lastCycleConsumption > 0) coverage += 6;

    // ------------------------------------------------------
    // 4) جودة البيانات (20)
    // ------------------------------------------------------
    int dataQuality = 0;

    if (kpi.hasWell) dataQuality += 8;
    if (kpi.hasPhone) dataQuality += 5;
    if (kpi.name.trim().isNotEmpty && !kpi.name.contains('No name')) {
      dataQuality += 3;
    }
    if (kpi.lastCycleConsumption > 0) dataQuality += 4;

    final int total =
        activity + regularity + coverage + dataQuality;

    final String grade = total >= 85
        ? 'Excellent'
        : total >= 70
            ? 'Good'
            : total >= 50
                ? 'Needs follow-up'
                : 'At risk';

    // ------------------------------------------------------
    // القراءة النصية
    // ------------------------------------------------------
    final String headline;

    if (!kpi.hasWell) {
      headline = 'Not linked to a well — no metric can be computed before linking.';
    } else if (kpi.closedCycles == 0) {
      headline = 'No closed cycle on their well yet; the metrics are zero, not negative.';
    } else if (days == null) {
      headline = 'Cycles exist but carry no close date, so activity cannot be measured.';
    } else if (days > 60) {
      headline = 'Has not closed a cycle for $days days — longer than two full cycles.';
    } else if (days > 30) {
      headline = 'Last cycle was $days days ago, with '
          '${_num(kpi.lastCycleConsumption)} m³.';
    } else {
      headline = 'Last cycle was $days days ago at '
          '${_num(kpi.lastCycleConsumption)} m³, '
          'with ${kpi.closedCycles} closed cycles in total.';
    }

    // ------------------------------------------------------
    // القوة والضعف والخطوات
    // ------------------------------------------------------
    final List<String> strengths = <String>[];
    final List<String> risks = <String>[];
    final List<String> actions = <String>[];

    if (activity >= 24) {
      strengths.add('Highly regular: closed the last cycle within two weeks.');
    }

    if (regularity >= 18) {
      strengths.add('$cycles90 cycles in the last 90 days — a steady operating rhythm.');
    }

    if (kpi.subscribers >= 15) {
      strengths.add('${kpi.subscribers} subscribers linked to their well.');
    }

    if (kpi.lastCycleConsumption > 0) {
      strengths.add(
        'Records real consumption (${_num(kpi.lastCycleConsumption)} m³ in the last cycle).',
      );
    }

    if (!kpi.hasWell) {
      risks.add('No well is linked to this account: every reading counts against no well.');
      actions.add('Link the account to a well in Supervisor Setup.');
    }

    if (!kpi.hasPhone) {
      risks.add('No phone number — they cannot be alerted or followed up.');
      actions.add('Add the phone number on the supervisor card.');
    }

    if (kpi.subscribers == 0 && kpi.hasWell) {
      risks.add('Not a single subscriber is linked, so no readings are expected.');
      actions.add('Add and link the well subscribers before the next cycle.');
    }

    if (kpi.closedCycles == 0) {
      risks.add('Has never closed a cycle: no consumption, no invoice, no collection.');
      actions.add('Run a trial cycle together to settle the working method.');
    } else if (days != null && days > 30) {
      risks.add('Last close was $days days ago — readings may be piling up unrecorded.');
      actions.add('Call them today and set a date for the overdue cycle.');
    } else if (days != null && days > 14) {
      risks.add('The close is $days days late against the monthly rhythm.');
      actions.add('Remind them before the end of the week.');
    }

    if (cycles90 == 0 && kpi.closedCycles > 0) {
      risks.add('No cycles in the last 90 days although older cycles exist.');
      actions.add('Review the older cycles: were they closed or cancelled?');
    }

    if (kpi.lastCycleConsumption <= 0 && kpi.closedCycles > 0) {
      risks.add('The last closed cycle has zero consumption — missing readings or a faulty meter.');
      actions.add('Review the last cycle readings and check the meter.');
    }

    if (strengths.isEmpty) {
      strengths.add('No measurable strengths yet — this is not a verdict on the person, '
          'it is missing data.');
    }

    if (actions.isEmpty) {
      actions.add('Keep the current rhythm and review the monthly report for the well.');
    }

    return SupervisorScore(
      kpi: kpi,
      total: total,
      activity: activity,
      regularity: regularity,
      coverage: coverage,
      dataQuality: dataQuality,
      grade: grade,
      headline: headline,
      strengths: strengths,
      risks: risks,
      actions: actions,
    );
  }

  // ==========================================================
  // قراءة البيانات
  // ==========================================================

  Future<List<Map<String, dynamic>>> _docs(
    String collection,
    List<String> warnings,
    String label,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection(collection).get();

      return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final Map<String, dynamic> data = d.data();

        data['__id'] = d.id;

        return data;
      }).toList();
    } catch (_) {
      warnings.add('Could not load $label');

      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _cycles(
    List<String> warnings,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('cycles')
          .orderBy('startDate', descending: true)
          .limit(_cycleLimit)
          .get();

      return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final Map<String, dynamic> data = d.data();

        data['__id'] = d.id;

        return data;
      }).toList();
    } catch (_) {
      try {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
            .collection('cycles')
            .limit(_cycleLimit)
            .get();

        return snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final Map<String, dynamic> data = d.data();

          data['__id'] = d.id;

          return data;
        }).toList();
      } catch (_) {
        warnings.add('Could not load the cycles');

        return <Map<String, dynamic>>[];
      }
    }
  }

  // ==========================================================
  // أدوات
  // ==========================================================

  static String _id(Map<String, dynamic> data) {
    final String value = (data['__id'] ?? '').toString();

    if (value.isNotEmpty) return value;

    return _text(data, <String>['id', 'uid', 'supervisorId']);
  }

  static String _text(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) continue;

      final String text = value.toString().trim();

      if (text.isNotEmpty && text != 'null') return text;
    }

    return '';
  }

  static double _number(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is num) return value.toDouble();

      if (value != null) {
        final double? parsed =
            double.tryParse(value.toString().trim());

        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }

  static String _num(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}
