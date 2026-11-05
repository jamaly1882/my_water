import 'gm_dashboard_service.dart';

// ============================================================
// محرك التحليل الذكي المحلي — Local insight engine
//
// كل الإجابات تُحسب من بيانات Firestore نفسها داخل التطبيق.
// لا خدمة خارجية، لا Ollama، لا HTTP، لا مفتاح API.
// الأسئلة تُفهم بمطابقة كلمات إنجليزية وعربية، والإجابة بالإنجليزية.
// ============================================================

class LocalInsightService {
  // ----------------------------------------------------------
  // ذاكرة مؤقتة: لا نُعيد قراءة Firestore مع كل سؤال
  // ----------------------------------------------------------

  static GmDashboardData? _cachedData;
  static DateTime? _cachedAt;

  static const Duration _cacheTtl = Duration(minutes: 2);

  static Future<GmDashboardData> load({
    bool forceRefresh = false,
  }) async {
    final DateTime now = DateTime.now();

    final bool fresh = _cachedData != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl;

    if (fresh && !forceRefresh) {
      return _cachedData!;
    }

    final GmDashboardData data =
        await GmDashboardService().load();

    _cachedData = data;
    _cachedAt = now;

    return data;
  }

  static void clearCache() {
    _cachedData = null;
    _cachedAt = null;
  }

  // ----------------------------------------------------------
  // نقطة الدخول
  // ----------------------------------------------------------

  static Future<Map<String, dynamic>> ask(
    String message, {
    bool forceRefresh = false,
  }) async {
    final GmDashboardData data = await load(
      forceRefresh: forceRefresh,
    );

    return <String, dynamic>{
      'answer': answerFor(message, data),
      'source': 'local',
      'generatedAt': data.generatedAt.toIso8601String(),
      'wellName': '',
    };
  }

  /// إجابة فورية من بيانات محمّلة مسبقاً (بلا انتظار).
  static String answerFor(
    String question,
    GmDashboardData data,
  ) {
    final String q = _normalize(question);

    if (q.isEmpty) {
      return 'Ask me about wells, villages, consumption, '
          'subscribers or supervisors.';
    }

    if (_hasAny(q, <String>['help', 'what can you', 'how do i',
          'مساعده', 'ماذا تستطيع', 'كيف'])) {
      return _help(data);
    }

    if (_hasAny(q, <String>['summary', 'overview', 'status',
          'ملخص', 'نظره عامه', 'الوضع'])) {
      return _summary(data);
    }

    if (_hasAny(q, <String>['coordinate', 'location', 'map',
          'موقع', 'خريطه', 'احداثيات'])) {
      return _location(data);
    }

    if (_hasAny(q, <String>['review', 'late', 'overdue', 'inactive',
          'مراجعه', 'متاخر', 'متأخر', 'متوقف'])) {
      return _needsReview(data);
    }

    if (_hasAny(q, <String>['rise', 'rising', 'increase', 'grew', 'up',
          'ارتفع', 'ارتفاع', 'زاد', 'زياده', 'زيادة'])) {
      return _risingVillages(data);
    }

    if (_hasAny(q, <String>['compare', 'comparison', 'versus', 'vs',
          'مقارنه', 'مقارنة'])) {
      return _comparison(data);
    }

    if (_hasAny(q, <String>['trend', 'monthly', 'month', 'last months',
          'اتجاه', 'شهري', 'اشهر', 'أشهر'])) {
      return _trend(data);
    }

    if (_hasAny(q, <String>['subscriber', 'customer', 'مشترك', 'مشتركين'])) {
      return _subscribers(data);
    }

    if (_hasAny(q, <String>['supervisor', 'مشرف', 'مشرفين'])) {
      return _supervisors(data);
    }

    if (_hasAny(q, <String>['well', 'بئر', 'ابار', 'آبار'])) {
      if (_hasAny(q, <String>['top', 'highest', 'most', 'biggest', 'best',
            'اعلى', 'أعلى', 'اكثر', 'أكثر'])) {
        return _topWell(data);
      }

      return _wellsList(data);
    }

    if (_hasAny(q, <String>['village', 'قريه', 'قرية', 'قري'])) {
      if (_hasAny(q, <String>['top', 'highest', 'most', 'biggest', 'best',
            'اعلى', 'أعلى', 'اكثر', 'أكثر'])) {
        return _topVillage(data);
      }

      return _villagesList(data);
    }

    if (_hasAny(q, <String>['consumption', 'water', 'usage',
          'استهلاك', 'مياه'])) {
      return _consumption(data);
    }

    // ------------------------------------------------------
    // لا نعرف القصد: نعطي الملخص وأمثلة أسئلة
    // ------------------------------------------------------

    return '${_summary(data)}\n\n'
        'I did not catch which figure you meant. Try:\n'
        '• Which well consumes the most?\n'
        '• Which villages are rising?\n'
        '• How many subscribers are linked?\n'
        '• What needs review?';
  }

  // ==========================================================
  // الإجابات
  // ==========================================================

  static String _help(GmDashboardData data) {
    return 'I answer from your live Firestore data — '
        'no external AI service.\n\n'
        'Try:\n'
        '• Summary of the portfolio\n'
        '• Which well consumes the most?\n'
        '• Which villages are rising?\n'
        '• What needs review?\n'
        '• How many subscribers are linked?\n'
        '• Consumption trend\n'
        '• Where are the wells?'
        '\n\nCoverage right now: ${data.wellCount} wells, '
        '${data.villageCount} villages, '
        '${data.subscriberCount} subscribers.';
  }

  static String _summary(GmDashboardData data) {
    final StringBuffer b = StringBuffer();

    b.writeln('Portfolio summary '
        '(${_date(data.generatedAt)}):');
    b.writeln('• Wells: ${data.wellCount}');
    b.writeln('• Villages: ${data.villageCount} · '
        'districts: ${data.districtCount} · '
        'provinces: ${data.provinceCount}');
    b.writeln('• Subscribers: ${data.subscriberCount} '
        '(${data.linkedSubscriberCount} linked to a well)');
    b.writeln('• Supervisors: ${data.supervisorCount}');
    b.writeln('• Closed cycles: ${data.closedCycleCount}');
    b.writeln('• Total consumption: '
        '${_num(data.totalConsumption)} m³');

    if (data.previousMonthConsumption > 0) {
      b.writeln('• This month: ${_num(data.currentMonthConsumption)} m³ '
          'against ${_num(data.previousMonthConsumption)} m³ '
          '(${_signed(data.overallChangePercent)}%)');
    } else {
      b.write('• This month: ${_num(data.currentMonthConsumption)} m³ '
          '(no previous month to compare — not measured)');
    }

    return b.toString().trimRight();
  }

  static String _topWell(GmDashboardData data) {
    if (data.wells.isEmpty) {
      return 'No wells are registered yet — nothing to rank.';
    }

    final GmWellData? month = data.topWellThisMonth;
    final GmWellData overall = data.wells.first;

    final StringBuffer b = StringBuffer();

    b.write('Highest consumption overall: '
        '**${overall.name}** — ${_num(overall.consumption)} m³');

    if (overall.villageName.trim().isNotEmpty) {
      b.write(' in ${overall.villageName}');
    }

    b.write(' (${overall.subscribers} subscribers, '
        '${overall.closedCycles} closed cycles).');

    if (month != null && month.id != overall.id) {
      b.write('\nThis month the lead is **${month.name}** '
          'with ${_num(month.currentMonthConsumption)} m³.');
    } else if (month == null) {
      b.write('\nNo well has a recorded consumption this month — '
          'not measured yet.');
    }

    if (data.wells.length > 1) {
      final GmWellData second = data.wells[1];
      b.write('\nRunner-up: ${second.name} — '
          '${_num(second.consumption)} m³.');
    }

    return b.toString();
  }

  static String _topVillage(GmDashboardData data) {
    if (data.villages.isEmpty) {
      return 'No villages are registered yet.';
    }

    final GmVillageData top = data.villages.first;

    return '**${top.name}** is the heaviest village: '
        '${_num(top.consumption)} m³ across '
        '${top.wells.length} wells and '
        '${top.subscribers} subscribers. '
        'That is ${_share(top.consumption, data.totalConsumption)}% '
        'of total consumption.';
  }

  static String _risingVillages(GmDashboardData data) {
    final List<GmVillageData> rising = data.villages
        .where((GmVillageData v) => v.previousMonthConsumption > 0)
        .where((GmVillageData v) =>
            v.currentMonthConsumption > v.previousMonthConsumption)
        .toList()
      ..sort((GmVillageData a, GmVillageData b) => _change(b).compareTo(_change(a)));

    if (rising.isEmpty) {
      return 'No village is rising this month. '
          'Villages without a previous month are reported as '
          'not measured, not as no change.';
    }

    final StringBuffer b = StringBuffer(
      'Villages whose consumption rose this month:',
    );

    for (final GmVillageData v in rising.take(5)) {
      b.write('\n• ${v.name}: '
          '${_num(v.currentMonthConsumption)} m³ '
          'against ${_num(v.previousMonthConsumption)} m³ '
          '(${_signed(_change(v))}%)');
    }

    return b.toString();
  }

  static String _needsReview(GmDashboardData data) {
    final List<GmWellData> review = <GmWellData>[];

    for (final GmWellData well in data.wells) {
      final DateTime? last = well.lastCycleDate;

      if (last == null) {
        review.add(well);
        continue;
      }

      if (data.generatedAt.difference(last).inDays > 30) {
        review.add(well);
      }
    }

    if (review.isEmpty) {
      return 'Every well has a cycle within the last 30 days. '
          'Nothing needs follow-up on the data side.';
    }

    final StringBuffer b = StringBuffer(
      '${review.length} well(s) need a look:',
    );

    for (final GmWellData well in review.take(8)) {
      final DateTime? last = well.lastCycleDate;

      b.write('\n• ${well.name}: ');

      if (last == null) {
        b.write('no closed cycle on record — not measured, '
            'which is missing data rather than poor performance.');
      } else {
        b.write('last cycle ${_date(last)} '
            '(${data.generatedAt.difference(last).inDays} days ago).');
      }
    }

    return b.toString();
  }

  static String _comparison(GmDashboardData data) {
    if (data.previousMonthConsumption <= 0 &&
        data.currentMonthConsumption <= 0) {
      return 'Neither this month nor last month has recorded '
          'consumption — not measured.';
    }

    final String direction = data.currentMonthConsumption >
            data.previousMonthConsumption
        ? 'up'
        : data.currentMonthConsumption <
                data.previousMonthConsumption
            ? 'down'
            : 'flat';

    return 'This month: ${_num(data.currentMonthConsumption)} m³\n'
        'Last month: ${_num(data.previousMonthConsumption)} m³\n'
        'Change: ${_signed(data.overallChangePercent)}% ($direction).';
  }

  static String _trend(GmDashboardData data) {
    if (data.monthly.isEmpty) {
      return 'No monthly history yet — the first closed cycles '
          'will build it.';
    }

    final StringBuffer b = StringBuffer('Consumption by month:');

    for (final GmMonthPoint point in data.monthly) {
      b.write('\n• ${point.label}: ${_num(point.value)} m³');
    }

    return b.toString();
  }

  static String _consumption(GmDashboardData data) {
    final StringBuffer b = StringBuffer();

    b.writeln('Total consumption: '
        '${_num(data.totalConsumption)} m³ '
        'over ${data.closedCycleCount} closed cycles.');

    if (data.previousMonthConsumption > 0) {
      b.write('This month is ${_signed(data.overallChangePercent)}% '
          'against last month.');
    } else {
      b.write('No previous month to compare — reported as '
          'not measured.');
    }

    return b.toString();
  }

  static String _subscribers(GmDashboardData data) {
    final int unlinked =
        data.subscriberCount - data.linkedSubscriberCount;

    final StringBuffer b = StringBuffer();

    b.writeln('Subscribers: ${data.subscriberCount} '
        '(${data.linkedSubscriberCount} linked to a well).');

    if (data.subscriberCount > 0) {
      b.write('Coverage: '
          '${_share(data.linkedSubscriberCount.toDouble(), data.subscriberCount.toDouble())}%.');
    }

    if (unlinked > 0) {
      b.write(' $unlinked still have no well — they cannot be '
          'read or billed until linked.');
    }

    return b.toString();
  }

  static String _supervisors(GmDashboardData data) {
    if (data.supervisors.isEmpty) {
      return 'No supervisors are registered yet.';
    }

    final int withWell = data.supervisors
        .where((GmSupervisorData s) => s.hasWell)
        .length;

    return 'Supervisors: ${data.supervisors.length} '
        '($withWell assigned to a well). '
        'Every supervisor is scored on activity, regularity, '
        'coverage and data quality, out of 100.';
  }

  static String _location(GmDashboardData data) {
    final int mapped = data.wells
        .where((GmWellData w) => w.hasCoordinates)
        .length;

    if (mapped == 0) {
      return 'No well has coordinates yet — the map stays empty '
          'until latitudes and longitudes are entered in Setup.';
    }

    return '$mapped of ${data.wells.length} wells have coordinates '
        'and appear on the map. '
        'The rest are unplaced, not lost.';
  }

  static String _wellsList(GmDashboardData data) {
    if (data.wells.isEmpty) {
      return 'No wells are registered yet.';
    }

    final StringBuffer b = StringBuffer(
      '${data.wells.length} wells, heaviest first:',
    );

    for (final GmWellData well in data.wells.take(8)) {
      b.write('\n• ${well.name} — '
          '${_num(well.consumption)} m³ · '
          '${well.subscribers} subscribers');
    }

    if (data.wells.length > 8) {
      b.write('\n…and ${data.wells.length - 8} more.');
    }

    return b.toString();
  }

  static String _villagesList(GmDashboardData data) {
    if (data.villages.isEmpty) {
      return 'No villages are registered yet.';
    }

    final StringBuffer b = StringBuffer(
      '${data.villages.length} villages:',
    );

    for (final GmVillageData v in data.villages.take(8)) {
      b.write('\n• ${v.name} — '
          '${v.wells.length} wells · '
          '${_num(v.consumption)} m³');
    }

    return b.toString();
  }

  // ==========================================================
  // أدوات
  // ==========================================================

  static double _change(GmVillageData v) {
    if (v.previousMonthConsumption <= 0) {
      return 0;
    }

    return ((v.currentMonthConsumption -
                v.previousMonthConsumption) /
            v.previousMonthConsumption) *
        100;
  }

  static String _num(double value) {
    final bool negative = value < 0;
    final int rounded = value.abs().round();

    final String digits = rounded.toString();
    final StringBuffer out = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        out.write(',');
      }
      out.write(digits[i]);
    }

    return negative ? '-$out' : out.toString();
  }

  static String _signed(double value) {
    final String base = _num(value);
    return value > 0 ? '+$base' : base;
  }

  static String _share(double part, double total) {
    if (total <= 0) {
      return '0';
    }

    return ((part / total) * 100).toStringAsFixed(1);
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  static bool _hasAny(String query, List<String> needles) {
    for (final String needle in needles) {
      if (query.contains(needle)) {
        return true;
      }
    }

    return false;
  }

  static String _normalize(String value) {
    String out = value.toLowerCase();

    out = out.replaceAll(
      RegExp(r'[\u064B-\u0652\u0670\u0640]'),
      '',
    );

    out = out
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');

    out = out.replaceAll(RegExp(r'\s+'), ' ');

    return out.trim();
  }
}
