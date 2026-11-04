// ============================================================
// supervisor_insights_page.dart
// شاشة «التحليل الذكي للsupervisorsين» — بطاقة لكل supervisors بئر،
// بدرجة من 100، وقراءة نصية، ومخاطر، وSuggested steps.
//
// التحليل محلي بالكامل: لا يستدعي أي خدمة خارجية.
// ============================================================

import 'package:flutter/material.dart';

import '../../widgets/my_app_bar.dart';
import 'supervisor_insight_service.dart';

const Color _bg = Color(0xFFF5F9FF);
const Color _primary = Color(0xFF1565C0);
const Color _dark = Color(0xFF10304F);
const Color _border = Color(0xFFE3ECF7);

class SupervisorInsightsPage extends StatefulWidget {
  const SupervisorInsightsPage({super.key});

  @override
  State<SupervisorInsightsPage> createState() =>
      _SupervisorInsightsPageState();
}

class _SupervisorInsightsPageState extends State<SupervisorInsightsPage> {
  final SupervisorInsightService _service = SupervisorInsightService();

  SupervisorInsightResult? _result;

  bool _loading = true;

  String? _error;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final SupervisorInsightResult result = await _service.load();

      if (!mounted) return;

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load the supervisor data: $error';
      });
    }
  }

  // ----------------------------------------------------------
  // أدوات عرض
  // ----------------------------------------------------------

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF00897B);
    if (score >= 70) return _primary;
    if (score >= 50) return const Color(0xFFEF6C00);

    return const Color(0xFFC62828);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    String two(int v) => v.toString().padLeft(2, '0');

    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  List<SupervisorScore> get _filtered {
    final List<SupervisorScore> all =
        _result?.scores ?? <SupervisorScore>[];

    switch (_filter) {
      case 'follow':
        return all.where((SupervisorScore s) => s.needsFollowUp).toList();
      case 'noCycles':
        return all
            .where((SupervisorScore s) => s.kpi.closedCycles == 0)
            .toList();
      case 'great':
        return all.where((SupervisorScore s) => s.total >= 85).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: MyAppBar(
          title: 'Supervisor Insights',
          icon: Icons.insights,
          actions: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildBody(),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off,
              size: 46,
              color: Color(0xFFC62828),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: _dark,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final SupervisorInsightResult result = _result!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: <Widget>[
        _buildSummary(result),
        if (result.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _buildWarnings(result.warnings),
        ],
        const SizedBox(height: 10),
        _buildFilters(),
        const SizedBox(height: 10),
        if (_filtered.isEmpty)
          _buildEmpty()
        else
          ..._filtered.map(_buildCard),
      ],
    );
  }

  Widget _buildSummary(SupervisorInsightResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.insights, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Field performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${result.averageScore.toStringAsFixed(0)}/100',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Average score across all supervisors',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _summaryChip(
                '${result.supervisorCount}',
                'supervisors',
                Icons.person_outline,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                '${result.needsFollowUp}',
                'Needs follow-up',
                Icons.flag_outlined,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                '${result.withoutCycles}',
                'No cycles',
                Icons.hourglass_empty,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The analysis rests on cycle activity, regularity, coverage '
            'and data quality — not on impressions. '
            'Last updated ${_formatDate(result.generatedAt)}.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarnings(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            color: Color(0xFFEF6C00),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warnings.join(' · '),
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF7A4100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final List<List<String>> options = <List<String>>[
      <String>['all', 'All'],
      <String>['follow', 'Needs follow-up'],
      <String>['noCycles', 'No cycles'],
      <String>['great', 'Excellent'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((List<String> option) {
          final bool selected = _filter == option[0];

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filter = option[0];
                });
              },
              label: Text(option[1]),
              labelStyle: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : _dark,
              ),
              selectedColor: _primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? _primary : _border,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.search_off,
            size: 40,
            color: _primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 10),
          const Text(
            'No supervisor matches this filter.',
            style: TextStyle(fontSize: 13, color: _dark),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // بطاقة الsupervisors
  // ----------------------------------------------------------

  Widget _buildCard(SupervisorScore score) {
    final Color color = _scoreColor(score.total);
    final SupervisorKpi kpi = score.kpi;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(score),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${score.total}',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          kpi.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kpi.hasWell
                              ? '${kpi.wellName.isEmpty ? 'بئر بلا اسم' : kpi.wellName}'
                                  '${kpi.locationLabel.isEmpty ? '' : ' · ${kpi.locationLabel}'}'
                              : 'Not linked to a well',
                          style: TextStyle(
                            fontSize: 11,
                            color: _dark.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      score.grade,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                score.headline,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.7,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  _metric(
                    '${kpi.subscribers}',
                    'subscribers',
                  ),
                  const SizedBox(width: 14),
                  _metric(
                    '${kpi.closedCycles}',
                    'closed cycles',
                  ),
                  const SizedBox(width: 14),
                  _metric(
                    '${_formatNumber(kpi.consumption)}',
                    'm³',
                  ),
                  const Spacer(),
                  Text(
                    'Last cycle: ${_formatDate(kpi.lastCycleDate)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _dark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (score.risks.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: Color(0xFFEF6C00),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          score.risks.first,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.6,
                            color: Color(0xFF7A4100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: _dark.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // التفاصيل
  // ----------------------------------------------------------

  Future<void> _showDetails(SupervisorScore score) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final Color color = _scoreColor(score.total);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            title: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${score.total}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        score.kpi.name,
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        score.grade,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _breakdown(score),
                    const SizedBox(height: 12),
                    _section(
                      'Metrics',
                      <String>[
                        'Well: ${score.kpi.wellName.isEmpty ? '—' : score.kpi.wellName}',
                        'Subscribers: ${score.kpi.subscribers}',
                        'Closed cycles: ${score.kpi.closedCycles}',
                        'Cycles in the last 90 days: ${score.kpi.cyclesLast90}',
                        'Total consumption: ${_formatNumber(score.kpi.consumption)} m³',
                        'Last cycle: ${_formatDate(score.kpi.lastCycleDate)} '
                            '(${score.kpi.daysSinceLastCycle == null ? 'بلا تاريخ' : 'قبل ${score.kpi.daysSinceLastCycle} يوماً'})',
                        'Phone: ${score.kpi.hasPhone ? score.kpi.phone : 'غير مسجّل'}',
                      ],
                    ),
                    _section('Strengths', score.strengths),
                    _section('Risks', score.risks),
                    _section('Suggested steps', score.actions),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _breakdown(SupervisorScore score) {
    final List<List<dynamic>> rows = <List<dynamic>>[
      <dynamic>['Activity', score.activity, 30],
      <dynamic>['Regularity', score.regularity, 25],
      <dynamic>['Coverage', score.coverage, 25],
      <dynamic>['Data quality', score.dataQuality, 20],
    ];

    return Column(
      children: rows.map((List<dynamic> row) {
        final String label = row[0] as String;
        final int value = row[1] as int;
        final int max = row[2] as int;
        final double ratio = max == 0 ? 0 : value / max;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 82,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: _dark.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE8F0FA),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _scoreColor((ratio * 100).round()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value/$max',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: _dark,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _section(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: _primary,
            ),
          ),
          const SizedBox(height: 5),
          ...items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '• ',
                    style: TextStyle(color: _primary),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.7,
                        color: _dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
