import 'package:flutter/material.dart';

import '../../services/gm_dashboard_service.dart';
import '../../services/local_insight_service.dart';
import '../../widgets/gm_ui.dart';

// ============================================================
// تبويب التحليل الذكي والمساعد
// ============================================================

class GmAnalyticsView extends StatefulWidget {
  final GmDashboardData? data;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;

  const GmAnalyticsView({
    super.key,
    required this.data,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<GmAnalyticsView> createState() =>
      _GmAnalyticsViewState();
}

class _GmAnalyticsViewState extends State<GmAnalyticsView> {
  final TextEditingController _controller =
      TextEditingController();

  final List<_QaEntry> _entries = <_QaEntry>[];

  static const List<String> _suggestions = <String>[
    'Which well consumes the most this month?',
    'Which village rose against last month?',
    'Which wells need a review?',
    'How did consumption move over the last six months?',
    'How many subscribers are linked?',
    'Compare the wells',
  ];

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _ask(String question) {
    final String text = question.trim();

    final GmDashboardData? data = widget.data;

    if (text.isEmpty || data == null) return;

    final String answer =
        LocalInsightService.answerFor(text, data);

    setState(() {
      _entries.add(
        _QaEntry(question: text, answer: answer),
      );

      if (_entries.length > 20) {
        _entries.removeAt(0);
      }
    });

    _controller.clear();

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final GmDashboardData? value = widget.data;

    if (value == null) {
      return _placeholder();
    }

    return RefreshIndicator(
      color: gmPrimary,
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(
                color: gmPrimary,
                minHeight: 3,
              ),
            ),

          if (widget.error != null) ...<Widget>[
            _errorBanner(),
            const SizedBox(height: 12),
          ],

          _summaryCard(value),
          const SizedBox(height: 14),

          _insightsCard(value),
          const SizedBox(height: 14),

          _assistantCard(value),
        ],
      ),
    );
  }

  // ==========================================================
  // حالات التحميل
  // ==========================================================

  Widget _placeholder() {
    if (widget.loading) {
      return const Center(
        child: CircularProgressIndicator(color: gmPrimary),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GmCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.psychology,
                size: 46,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load smart analytics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: gmTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.error ??
                    'Check the internet connection and account permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  widget.onRefresh();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gmPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: 17,
            color: Color(0xFFC62828),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.error ?? 'Could not refresh the data',
              style: const TextStyle(
                fontSize: 10.8,
                color: Color(0xFFC62828),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onRefresh();
            },
            child: const Text(
              'Refresh',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // قراءة سريعة
  // ==========================================================

  Widget _summaryCard(GmDashboardData value) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const GmSectionTitle(
            title: 'Smart analytics',
            icon: Icons.psychology,
            subtitle:
                'Automatic reading of consumption and supervisor data',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GmPill(
                label: '${value.closedCycleCount} closed cycles',
                icon: Icons.loop,
              ),
              GmPill(
                label:
                    '${value.wellsNeedingReview.length} wells to review',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFD32F2F),
              ),
              GmPill(
                label:
                    '${value.villagesRising.length} rising villages',
                icon: Icons.trending_up,
                color: const Color(0xFFEF6C00),
              ),
              GmPill(
                label:
                    '${value.wellsWithoutSupervisor.length} without a supervisor',
                icon: Icons.person_off,
                color: const Color(0xFF6A1B9A),
              ),
              GmPill(
                label:
                    '${value.staleWells.length} need follow-up',
                icon: Icons.explore_outlined,
                color: const Color(0xFF00838F),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The system compares this month with the last for every well and '
            'village, flags rises above 20% for villages and 30% for wells, '
            'and lists wells with no supervisor or no recent cycle.',
            style: TextStyle(
              fontSize: 10.8,
              height: 1.6,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // التنبيهات
  // ==========================================================

  Widget _insightsCard(GmDashboardData value) {
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'Alerts and indicators',
            icon: Icons.notifications_active,
            subtitle:
                '${value.insights.length} notes from your data',
          ),
          const SizedBox(height: 14),
          ...value.insights.map(
            (GmInsight insight) => GmInsightTile(
              insight: insight,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // المساعد الذكي
  // ==========================================================

  Widget _assistantCard(GmDashboardData value) {
    final List<Widget> messages = <Widget>[];

    for (final _QaEntry entry in _entries) {
      messages.add(_bubble(entry.question, true));
      messages.add(_bubble(entry.answer, false));
    }

    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GmSectionTitle(
            title: 'Assistant',
            icon: Icons.auto_awesome,
            subtitle:
                'Ask about wells, villages, consumption and supervisors',
            trailing: _entries.isEmpty
                ? null
                : TextButton(
                    onPressed: () {
                      setState(() {
                        _entries.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(36, 28),
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(fontSize: 10.5),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gmBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: gmPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start with a suggestion below, or type your own '
                      'question about wells and villages.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...messages,
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestions
                .map(
                  (String suggestion) => ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 9.8),
                    ),
                    onPressed: () {
                      _ask(suggestion);
                    },
                    backgroundColor:
                        const Color(0xFFF1F7FF),
                    side: const BorderSide(color: gmBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (String value) {
                    _ask(value);
                  },
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Type your question…',
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    _ask(_controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: gmPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Icon(Icons.send, size: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Answers are computed straight from your data '
            '(${gmFormatNumber(value.wellCount)} wells, '
            '${gmFormatNumber(value.villageCount)} villages).',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool user) {
    return Align(
      alignment:
          user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: user ? gmPrimary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(user ? 14 : 4),
            bottomRight: Radius.circular(user ? 4 : 14),
          ),
          border: user
              ? null
              : Border.all(color: gmBorder),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.6,
            color: user
                ? Colors.white
                : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// سؤال وجواب
// ============================================================

class _QaEntry {
  final String question;
  final String answer;

  const _QaEntry({
    required this.question,
    required this.answer,
  });
}
