import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/accounting_tree_service.dart';
import '../widgets/my_app_bar.dart';

// ============================================================
// شاشة الشجرة المحاسبية — Accounting tree
//
// تعرض الأصول والخصوم وحقوق الملكية والإيرادات والمصروفات
// لكل بئر على حدة، أو مجمّعة لكل الآبار.
// الأرقام تُبنى من accounts + account_transactions مباشرة.
// ============================================================

const Color _primary = Color(0xFF1565C0);
const Color _accent = Color(0xFF00897B);
const Color _bg = Color(0xFFF5F9FF);
const Color _border = Color(0xFFE3ECF7);
const Color _textDark = Color(0xFF10304F);
const Color _danger = Color(0xFFD32F2F);

class AccountingTreeScreen extends StatefulWidget {
  final String? wellId;
  final String? wellName;

  const AccountingTreeScreen({
    super.key,
    this.wellId,
    this.wellName,
  });

  @override
  State<AccountingTreeScreen> createState() => _AccountingTreeScreenState();
}

class _AccountingTreeScreenState extends State<AccountingTreeScreen> {
  final AccountingTreeService _service = AccountingTreeService();

  List<TreeWellRef> _wells = <TreeWellRef>[];

  String? _selectedWellId;
  String _selectedWellName = 'All wells';

  AccountingPeriod _period = AccountingPeriod.all;

  AccountingTreeResult? _result;
  String? _error;

  bool _loading = true;

  final Set<String> _expanded = <String>{'1000', '4000', '5000'};

  @override
  void initState() {
    super.initState();

    _selectedWellId = widget.wellId;
    _selectedWellName = widget.wellId == null
        ? 'All wells'
        : (widget.wellName ?? 'Selected well');

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final List<TreeWellRef> wells = await _service.loadWells();

      if (!mounted) return;

      setState(() {
        _wells = wells;
      });
    } catch (_) {
      // قائمة الآبار كمالية: الشجرة تعمل حتى لو فشلت.
    }

    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final AccountingTreeResult result = await _service.load(
        wellId: _selectedWellId,
        wellName: _selectedWellId == null ? null : _selectedWellName,
        period: _period,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _clean(e.toString());
        _loading = false;
      });
    }
  }

  String _clean(String value) {
    if (value.startsWith('Exception: ')) {
      return value.substring('Exception: '.length);
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: MyAppBar(
          title: 'Accounting tree',
          subtitle: 'Assets · Liabilities · Revenue · Expenses',
          icon: Icons.account_tree,
          actions: <Widget>[
            IconButton(
              tooltip: 'Copy as CSV',
              onPressed: _result == null ? null : _copyCsv,
              icon: const Icon(Icons.copy_all),
            ),
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
                ? _errorView()
                : _content(),
      ),
    );
  }

  // ==========================================================
  // الحالات
  // ==========================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 46, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Could not load the tree',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final AccountingTreeResult? result = _result;

    if (result == null) {
      return const Center(child: Text('No data'));
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: <Widget>[
        _filtersCard(),
        const SizedBox(height: 12),
        _equationCard(result),
        const SizedBox(height: 12),
        if (!result.hasData)
          _emptyCard()
        else
          _treeCard(result),
        if (result.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _warningsCard(result),
        ],
        const SizedBox(height: 12),
        _metaCard(result),
      ],
    );
  }

  // ==========================================================
  // الفلاتر
  // ==========================================================

  Widget _filtersCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.tune, size: 18, color: _primary),
              const SizedBox(width: 8),
              const Text(
                'Scope',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Well',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedWellId,
                isExpanded: true,
                isDense: true,
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All wells'),
                  ),
                  ..._wells.map(
                    (TreeWellRef well) => DropdownMenuItem<String?>(
                      value: well.id,
                      child: Text(
                        well.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedWellId = value;
                    _selectedWellName =
                        value == null ? 'All wells' : _nameFor(value);
                  });

                  _load();
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: AccountingPeriod.values.map((AccountingPeriod period) {
              final bool selected = _period == period;

              return ChoiceChip(
                label: Text(period.label),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _period = period;
                  });

                  _load();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _nameFor(String wellId) {
    for (final TreeWellRef well in _wells) {
      if (well.id == wellId) return well.name;
    }

    return 'Selected well';
  }

  // ==========================================================
  // شريط المعادلة
  // ==========================================================

  Widget _equationCard(AccountingTreeResult result) {
    final bool balanced = result.imbalance.abs() <= 0.05;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.functions, size: 18, color: _primary),
              const SizedBox(width: 8),
              const Text(
                'Balance equation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: balanced
                      ? _accent.withValues(alpha: 0.12)
                      : _danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  balanced ? 'Balanced' : 'Unbalanced',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: balanced ? _accent : _danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _metric('Assets', result.assets, _primary),
              _metric('Liabilities', result.liabilities, Colors.orange.shade800),
              _metric('Equity', result.equity, _accent),
              _metric('Revenue', result.revenue, Colors.green.shade700),
              _metric('Expenses', result.expenses, _danger),
            ],
          ),
          if (!balanced) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Difference: ${_money(result.imbalance)} — '
              'Assets − Liabilities do not equal Revenue − Expenses.',
              style: const TextStyle(fontSize: 10.5, color: _danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, double value, Color color) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(value),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // الشجرة
  // ==========================================================

  Widget _treeCard(AccountingTreeResult result) {
    return _card(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.account_tree, size: 18, color: _primary),
              const SizedBox(width: 8),
              const Text(
                'Chart of accounts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                result.scopeLabel,
                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _headerRow(),
          const Divider(height: 12),
          for (final TreeLine root in result.roots) ..._buildRows(root, 0),
        ],
      ),
    );
  }

  List<Widget> _buildRows(TreeLine line, int depth) {
    if (!line.hasMoney) return <Widget>[];

    final bool hasChildren = line.children.isNotEmpty;
    final bool open = _expanded.contains(line.code);

    final List<Widget> rows = <Widget>[
      InkWell(
        onTap: hasChildren
            ? () {
                setState(() {
                  if (open) {
                    _expanded.remove(line.code);
                  } else {
                    _expanded.add(line.code);
                  }
                });
              }
            : null,
        child: Container(
          color: depth == 0 ? _primary.withValues(alpha: 0.05) : null,
          padding: EdgeInsetsDirectional.only(
            start: 2 + depth * 14,
            top: 7,
            bottom: 7,
            end: 2,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                child: hasChildren
                    ? Icon(
                        open ? Icons.expand_more : Icons.chevron_right,
                        size: 16,
                        color: _primary,
                      )
                    : null,
              ),
              SizedBox(
                width: 52,
                child: Text(
                  line.code,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  line.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ),
              _amount(line.totalDebit, strong: depth == 0),
              _amount(line.totalCredit, strong: depth == 0),
              _amount(line.balance, strong: true),
            ],
          ),
        ),
      ),
    ];

    if (hasChildren && open) {
      for (final TreeLine child in line.children) {
        rows.addAll(_buildRows(child, depth + 1));
      }
    }

    return rows;
  }

  Widget _headerRow() {
    const TextStyle style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Color(0xFF546E7A),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2, end: 2),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          const SizedBox(width: 52, child: Text('Code', style: style)),
          const Expanded(child: Text('Account', style: style)),
          const SizedBox(
            width: 64,
            child: Text('Debit', style: style, textAlign: TextAlign.left),
          ),
          const SizedBox(
            width: 64,
            child: Text('Credit', style: style, textAlign: TextAlign.left),
          ),
          const SizedBox(
            width: 72,
            child: Text('Balance', style: style, textAlign: TextAlign.left),
          ),
        ],
      ),
    );
  }

  Widget _amount(double value, {bool strong = false}) {
    return SizedBox(
      width: 72,
      child: Text(
        _money(value),
        textAlign: TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: strong ? FontWeight.bold : FontWeight.normal,
          color: _textDark,
        ),
      ),
    );
  }

  // ==========================================================
  // بطاقات مساعدة
  // ==========================================================

  Widget _emptyCard() {
    return _card(
      child: Column(
        children: <Widget>[
          const Icon(Icons.inbox, size: 40, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            'No entries posted yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Close a reading cycle or save a voucher and the tree '
            'will fill itself from the real entries.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _warningsCard(AccountingTreeResult result) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Text(
                '${result.warnings.length} note(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final String warning in result.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('• ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    child: Text(
                      warning,
                      style: TextStyle(
                        fontSize: 10.8,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaCard(AccountingTreeResult result) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Source: accounts + account_transactions · '
            '${result.accountCount} accounts, '
            '${result.postedAccountCount} with movement',
            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'Total debit ${_money(result.totalDebit)} · '
            'total credit ${_money(result.totalCredit)} · '
            'generated ${_dateTime(result.generatedAt)}',
            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  // ==========================================================
  // التصدير
  // ==========================================================

  void _copyCsv() {
    final AccountingTreeResult? result = _result;

    if (result == null) return;

    final StringBuffer buffer = StringBuffer();

    buffer.writeln('scope,period,code,account,debit,credit,balance');
    buffer.writeln(
      '"${result.scopeLabel}","${result.period.label}",,,'
      '${result.totalDebit.toStringAsFixed(2)},'
      '${result.totalCredit.toStringAsFixed(2)},'
      '${result.imbalance.toStringAsFixed(2)}',
    );

    void walk(TreeLine line, int depth) {
      final String indent = '  ' * depth;

      buffer.writeln(
        '"${result.scopeLabel}","${result.period.label}",'
        '"${line.code}","$indent${line.name.replaceAll('"', '""')}",'
        '${line.totalDebit.toStringAsFixed(2)},'
        '${line.totalCredit.toStringAsFixed(2)},'
        '${line.balance.toStringAsFixed(2)}',
      );

      for (final TreeLine child in line.children) {
        walk(child, depth + 1);
      }
    }

    for (final TreeLine root in result.roots) {
      walk(root, 0);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tree copied as CSV'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // تنسيق
  // ==========================================================

  String _money(double value) {
    final bool negative = value < 0;
    final String raw = value.abs().toStringAsFixed(2);
    final List<String> parts = raw.split('.');

    final String whole = parts.first;
    final StringBuffer out = StringBuffer();

    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        out.write(',');
      }
      out.write(whole[i]);
    }

    final String result = '$out.${parts.length > 1 ? parts[1] : '00'}';

    return negative ? '-$result' : result;
  }

  String _dateTime(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '${value.year}-$month-$day $hour:$minute';
  }
}
