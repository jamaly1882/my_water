import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// الشجرة المحاسبية — Accounting tree
//
// تبني شجرة حسابات (الأصول · الخصوم · حقوق الملكية · الإيرادات
// · المصروفات) من الحسابات والقيود الفعلية في Firestore.
//
// المصادر:
//   accounts             — الحسابات (type · wellId · customerId)
//   account_transactions — القيود بصيغتين:
//        (أ) accountId + debit/credit
//        (ب) debitAccountId / creditAccountId + amount
//
// لا تُكتب أي بيانات: الشجرة مشتقة بالكامل.
// ============================================================

/// طبيعة الحساب: مدين أو دائن.
enum AcctNature { debit, credit }

/// الفترة الزمنية للشجرة.
enum AccountingPeriod { all, thisYear, thisMonth }

extension AccountingPeriodLabel on AccountingPeriod {
  String get label {
    switch (this) {
      case AccountingPeriod.all:
        return 'All time';
      case AccountingPeriod.thisYear:
        return 'This year';
      case AccountingPeriod.thisMonth:
        return 'This month';
    }
  }

  DateTime? get from {
    final DateTime now = DateTime.now();

    switch (this) {
      case AccountingPeriod.all:
        return null;
      case AccountingPeriod.thisYear:
        return DateTime(now.year);
      case AccountingPeriod.thisMonth:
        return DateTime(now.year, now.month);
    }
  }
}

/// مرجع بئر لعنصر الاختيار.
class TreeWellRef {
  final String id;
  final String name;

  const TreeWellRef({required this.id, required this.name});
}

/// نتيجة قراءة قائمة الآبار: الآبار المتاحة + ملاحظات عن المصادر.
class TreeWellList {
  final List<TreeWellRef> wells;
  final List<String> notes;

  const TreeWellList({required this.wells, required this.notes});

  bool get isEmpty => wells.isEmpty;
}

/// عقدة في الشجرة.
class TreeLine {
  final String code;
  final String name;
  final AcctNature nature;

  double debit = 0;
  double credit = 0;

  final List<TreeLine> children = <TreeLine>[];

  TreeLine({
    required this.code,
    required this.name,
    required this.nature,
  });

  /// مجموع مدين هذه العقدة مع كل أبنائها.
  double get totalDebit {
    double sum = debit;

    for (final TreeLine child in children) {
      sum += child.totalDebit;
    }

    return sum;
  }

  /// مجموع دائن هذه العقدة مع كل أبنائها.
  double get totalCredit {
    double sum = credit;

    for (final TreeLine child in children) {
      sum += child.totalCredit;
    }

    return sum;
  }

  /// الرصيد بحسب طبيعة الحساب.
  double get balance {
    if (nature == AcctNature.debit) {
      return totalDebit - totalCredit;
    }

    return totalCredit - totalDebit;
  }

  bool get hasMoney =>
      totalDebit.abs() > 0.0001 || totalCredit.abs() > 0.0001;

  TreeLine? childByCode(String childCode) {
    for (final TreeLine child in children) {
      if (child.code == childCode) return child;
    }

    return null;
  }

  TreeLine ensureChild({
    required String childCode,
    required String childName,
    required AcctNature childNature,
  }) {
    final TreeLine? existing = childByCode(childCode);

    if (existing != null) return existing;

    final TreeLine created = TreeLine(
      code: childCode,
      name: childName,
      nature: childNature,
    );

    children.add(created);

    return created;
  }
}

/// نتيجة بناء الشجرة.
class AccountingTreeResult {
  final List<TreeLine> roots;

  final double totalDebit;
  final double totalCredit;

  final DateTime generatedAt;
  final String scopeLabel;
  final AccountingPeriod period;

  final int accountCount;
  final int postedAccountCount;
  final int unclassifiedCount;

  final List<String> warnings;

  const AccountingTreeResult({
    required this.roots,
    required this.totalDebit,
    required this.totalCredit,
    required this.generatedAt,
    required this.scopeLabel,
    required this.period,
    required this.accountCount,
    required this.postedAccountCount,
    required this.unclassifiedCount,
    required this.warnings,
  });

  /// إجمالي جذر بالكود (1000 · 2000 ...).
  double totalOf(String code) {
    for (final TreeLine root in roots) {
      if (root.code == code) return root.balance;
    }

    return 0;
  }

  double get assets => totalOf('1000');
  double get liabilities => totalOf('2000');
  double get revenue => totalOf('4000');
  double get expenses => totalOf('5000');

  /// حقوق الملكية = الإيرادات − المصروفات.
  double get equity => revenue - expenses;

  /// الفرق بين (الأصول − الخصوم) وحقوق الملكية.
  double get imbalance => (assets - liabilities) - equity;

  bool get hasData => totalDebit.abs() > 0.0001 || totalCredit.abs() > 0.0001;
}

/// تجميع داخلي لحساب واحد.
class _AccountBucket {
  final String id;
  final String name;
  final String type;
  final String wellId;
  final String wellName;
  final bool isCustomer;
  final double storedBalance;

  double debit = 0;
  double credit = 0;

  _AccountBucket({
    required this.id,
    required this.name,
    required this.type,
    required this.wellId,
    required this.wellName,
    required this.isCustomer,
    required this.storedBalance,
  });

  bool get hasPostings => debit.abs() > 0.0001 || credit.abs() > 0.0001;
}

// ============================================================
// الخدمة
// ============================================================

class AccountingTreeService {
  final FirebaseFirestore _db;

  AccountingTreeService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const int _accountLimit = 800;
  static const int _transactionLimit = 4000;

  // ----------------------------------------------------------
  // قائمة الآبار
  // ----------------------------------------------------------

  // قائمة الآبار تُبنى من عدة مصادر بالترتيب:
  //
  //   1) مجموعة wells               — الأسماء الرسمية
  //   2) وثائق users                — تحمل wellId و wellName للمشرفين
  //   3) مجموعة accounts            — كل حساب يحمل wellId و wellName
  //   4) البئر الحالي من الشاشة
  //
  // السبب: حساب مشرف بئر واحد قد لا يملك صلاحية قراءة مجموعة wells
  // كاملة، فيظهر في القائمة بئر واحد فقط. بهذه الطريقة تُجمع الأسماء
  // من المصادر التي يستطيع قراءتها، وتُدمج بلا تكرار.
  //
  // لا تُكتب أي بيانات — قراءة فقط.
  Future<TreeWellList> loadWells({
    String? currentWellId,
    String? currentWellName,
  }) async {
    final Map<String, String> names = <String, String>{};
    final List<String> notes = <String>[];

    // 1 — مجموعة wells
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collection('wells').limit(400).get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        _rememberWell(
          names,
          doc.id,
          _text(doc.data(), <String>['name', 'wellName', 'title']),
        );
      }
    } catch (_) {
      notes.add(
        'The "wells" collection is not readable with this account; '
        'well names were taken from the accounts instead.',
      );
    }

    // 2 — وثائق المستخدمين
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collection('users').limit(500).get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        _rememberWell(
          names,
          _text(data, <String>['wellId']),
          _text(data, <String>['wellName']),
        );
      }
    } catch (_) {
      // مصدر كمالي — لا يمنع العمل.
    }

    // 3 — الحسابات
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collection('accounts').limit(_accountLimit).get();

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        _rememberWell(
          names,
          _text(data, <String>['wellId']),
          _text(data, <String>['wellName']),
        );
      }
    } catch (_) {
      // مصدر كمالي — لا يمنع العمل.
    }

    // 4 — البئر الحالي
    _rememberWell(names, currentWellId, currentWellName);

    final List<TreeWellRef> wells = names.entries
        .map(
          (MapEntry<String, String> entry) => TreeWellRef(
            id: entry.key,
            name: entry.value.isEmpty ? 'Well ${entry.key}' : entry.value,
          ),
        )
        .toList();

    wells.sort(
      (TreeWellRef a, TreeWellRef b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    if (wells.isEmpty) {
      notes.add('No wells are readable with this account.');
    }

    return TreeWellList(wells: wells, notes: notes);
  }

  /// يضيف بئرًا إلى القائمة بلا تكرار، ويحتفظ بأفضل اسم متاح.
  static void _rememberWell(
    Map<String, String> names,
    String? id,
    String? name,
  ) {
    final String key = (id ?? '').trim();

    if (key.isEmpty) return;

    final String clean = (name ?? '').trim();
    final String existing = names[key] ?? '';

    if (clean.isEmpty) {
      if (!names.containsKey(key)) {
        names[key] = '';
      }

      return;
    }

    if (existing.isEmpty || existing == 'Well $key') {
      names[key] = clean;
    }
  }

  // ----------------------------------------------------------
  // البناء
  // ----------------------------------------------------------

  Future<AccountingTreeResult> load({
    String? wellId,
    String? wellName,
    AccountingPeriod period = AccountingPeriod.all,
  }) async {
    final List<String> warnings = <String>[];

    // 1 — الحسابات
    final QuerySnapshot<Map<String, dynamic>> accountDocs =
        await _db.collection('accounts').limit(_accountLimit).get();

    if (accountDocs.docs.length >= _accountLimit) {
      warnings.add('Account list hit the $_accountLimit cap.');
    }

    final Map<String, _AccountBucket> buckets = <String, _AccountBucket>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in accountDocs.docs) {
      final Map<String, dynamic> data = doc.data();

      final String customerId =
          _text(data, <String>['customerId']) ?? '';

      final _AccountBucket bucket = _AccountBucket(
        id: doc.id,
        name: _text(data, <String>['name', 'customerName', 'title']) ??
            (customerId.isNotEmpty ? 'Subscriber account' : 'Account'),
        type: (_text(data, <String>['type']) ?? '').toLowerCase(),
        wellId: _text(data, <String>['wellId']) ?? '',
        wellName: _text(data, <String>['wellName']) ?? '',
        isCustomer: customerId.isNotEmpty,
        storedBalance: _number(data['balance']),
      );

      buckets[doc.id] = bucket;
    }

    // 2 — القيود
    Query<Map<String, dynamic>> query =
        _db.collection('account_transactions');

    if (wellId != null && wellId.isNotEmpty) {
      query = query.where('wellId', isEqualTo: wellId);
    }

    final QuerySnapshot<Map<String, dynamic>> txDocs =
        await query.limit(_transactionLimit).get();

    if (txDocs.docs.length >= _transactionLimit) {
      warnings.add('Entry list hit the $_transactionLimit cap; '
          'narrow the period or pick a single well.');
    }

    final DateTime? fromDate = period.from;
    final Set<String> seen = <String>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in txDocs.docs) {
      if (!seen.add(doc.id)) continue;

      final Map<String, dynamic> data = doc.data();

      if (fromDate != null) {
        final DateTime? at = _date(data);

        if (at != null && at.isBefore(fromDate)) continue;
      }

      final String txWellId = _text(data, <String>['wellId']) ?? '';
      final String txWellName = _text(data, <String>['wellName']) ?? '';

      final String debitAccountId =
          _text(data, <String>['debitAccountId']) ?? '';
      final String creditAccountId =
          _text(data, <String>['creditAccountId']) ?? '';

      final String singleAccountId =
          _text(data, <String>['accountId']) ?? '';

      // الصيغة (ب): قيد مزدوج صريح
      if (debitAccountId.isNotEmpty || creditAccountId.isNotEmpty) {
        final double amount = _number(data['amount']);

        if (amount != 0) {
          if (debitAccountId.isNotEmpty) {
            _bucketFor(buckets, debitAccountId, txWellId, txWellName)
                .debit += amount;
          }

          if (creditAccountId.isNotEmpty) {
            _bucketFor(buckets, creditAccountId, txWellId, txWellName)
                .credit += amount;
          }
        }

        continue;
      }

      // الصيغة (أ): حساب واحد + مدين/دائن
      if (singleAccountId.isEmpty) continue;

      double debit = _number(data['debit']);
      double credit = _number(data['credit']);

      if (debit == 0 && credit == 0) {
        final double amount = _number(data['amount']);
        final String side =
            (_text(data, <String>['transactionType']) ?? '').toLowerCase();

        if (side == 'debit') {
          debit = amount;
        } else if (side == 'credit') {
          credit = amount;
        }
      }

      if (debit == 0 && credit == 0) continue;

      final _AccountBucket bucket =
          _bucketFor(buckets, singleAccountId, txWellId, txWellName);

      bucket.debit += debit;
      bucket.credit += credit;
    }

    // 3 — الشجرة
    final TreeLine assets = TreeLine(
      code: '1000',
      name: 'Assets',
      nature: AcctNature.debit,
    );

    final TreeLine liabilities = TreeLine(
      code: '2000',
      name: 'Liabilities',
      nature: AcctNature.credit,
    );

    final TreeLine equity = TreeLine(
      code: '3000',
      name: 'Equity',
      nature: AcctNature.credit,
    );

    final TreeLine revenue = TreeLine(
      code: '4000',
      name: 'Revenue',
      nature: AcctNature.credit,
    );

    final TreeLine expenses = TreeLine(
      code: '5000',
      name: 'Expenses',
      nature: AcctNature.debit,
    );

    int posted = 0;
    int unclassified = 0;
    int unassignedPostings = 0;
    int usedStoredBalance = 0;

    double postedDebit = 0;
    double postedCredit = 0;

    for (final _AccountBucket bucket in buckets.values) {
      if (wellId != null && wellId.isNotEmpty) {
        final bool sameWell = bucket.wellId == wellId;

        if (!sameWell) continue;
      }

      if (!bucket.hasPostings && bucket.storedBalance.abs() < 0.0001) {
        continue;
      }

      posted++;

      postedDebit += bucket.debit;
      postedCredit += bucket.credit;


      if (bucket.wellId.isEmpty) {
        unassignedPostings++;
      }

      final String wellKey =
          bucket.wellId.isNotEmpty ? bucket.wellId : 'unassigned';
      final String wellLabel = bucket.wellId.isNotEmpty
          ? (bucket.wellName.isNotEmpty ? bucket.wellName : 'Well')
          : 'Unassigned';

      final String? leafCode = _leafCodeFor(bucket);

      // حساب له رصيد مخزّن بلا قيود (بيانات قديمة): نورده بالرصيد المخزّن
      // حتى لا تختفي أرقام من الشجرة.
      double debit = bucket.debit;
      double credit = bucket.credit;

      if (!bucket.hasPostings && bucket.storedBalance.abs() > 0.0001) {
        usedStoredBalance++;

        final AcctNature nature =
            leafCode == null ? AcctNature.debit : _natureForLeaf(leafCode);

        if (nature == AcctNature.debit) {
          debit = bucket.storedBalance;
          credit = 0;
        } else {
          credit = bucket.storedBalance;
          debit = 0;
        }
      }

      if (leafCode == null) {
        unclassified++;

        final TreeLine other = assets.ensureChild(
          childCode: '1900',
          childName: 'Unclassified accounts',
          childNature: AcctNature.debit,
        );

        _addLeaf(
          other,
          wellId: wellKey,
          wellName: wellLabel,
          accountName: bucket.name,
          accountType: bucket.type.isEmpty ? 'unknown' : bucket.type,
          debit: debit,
          credit: credit,
        );

        continue;
      }

      final TreeLine parent = _parentFor(
        leafCode: leafCode,
        assets: assets,
        liabilities: liabilities,
        revenue: revenue,
        expenses: expenses,
      );

      _addLeaf(
        parent,
        wellId: wellKey,
        wellName: wellLabel,
        accountName: bucket.name,
        accountType: leafCode,
        debit: debit,
        credit: credit,
      );
    }

    // 4 — حقوق الملكية المحسوبة
    final TreeLine result = equity.ensureChild(
      childCode: '3100',
      childName: 'Result for the period (Revenue − Expenses)',
      childNature: AcctNature.credit,
    );

    final double revenueBalance = revenue.balance;
    final double expenseBalance = expenses.balance;

    result.credit = revenueBalance > 0 ? revenueBalance : 0;
    result.debit = expenseBalance > 0 ? expenseBalance : 0;

    // 5 — الحصيلة
    final List<TreeLine> roots = <TreeLine>[
      assets,
      liabilities,
      equity,
      revenue,
      expenses,
    ];

    _sortTree(assets);
    _sortTree(liabilities);
    _sortTree(equity);
    _sortTree(revenue);
    _sortTree(expenses);

    final AccountingTreeResult provisional = AccountingTreeResult(
      roots: roots,
      totalDebit: postedDebit,
      totalCredit: postedCredit,
      generatedAt: DateTime.now(),
      scopeLabel: wellId == null || wellId.isEmpty
          ? 'All wells'
          : (wellName ?? 'Selected well'),
      period: period,
      accountCount: buckets.length,
      postedAccountCount: posted,
      unclassifiedCount: unclassified,
      warnings: warnings,
    );

    if (provisional.imbalance.abs() > 0.05) {
      warnings.add(
        'Balance sheet mismatch of '
        '${provisional.imbalance.toStringAsFixed(2)} — '
        'some entries post to one side only.',
      );
    }

    if (unassignedPostings > 0) {
      warnings.add(
        '$unassignedPostings account(s) carry no wellId; '
        'they appear under "Unassigned" and are excluded '
        'when a single well is selected.',
      );
    }

    if (usedStoredBalance > 0) {
      warnings.add(
        '$usedStoredBalance account(s) carry a stored balance but no '
        'entries; the stored balance was used so no figure disappears.',
      );
    }

    if (unclassified > 0) {
      warnings.add(
        '$unclassified account(s) have no type and were placed under '
        '"Unclassified accounts".',
      );
    }

    return provisional;
  }

  // ----------------------------------------------------------
  // التصنيف
  // ----------------------------------------------------------

  /// كود الورقة لكل حساب بحسب نوعه.
  String? _leafCodeFor(_AccountBucket bucket) {
    final String type = bucket.type;

    if (bucket.isCustomer) return '1201';
    if (type == 'cash') return '1101';
    if (type == 'worker') return '2101';
    if (type == 'sales') return '4101';
    if (type == 'expenses' || type == 'expense') return '5101';

    // تصنيف احتياطي بالاسم حين يكون النوع مفقوداً.
    final String name = bucket.name.toLowerCase();

    if (name.contains('fund') || name.contains('cash')) return '1101';
    if (name.contains('operator') || name.contains('worker')) return '2101';
    if (name.contains('sales')) return '4101';
    if (name.contains('expense')) return '5101';

    return null;
  }

  /// طبيعة الورقة (مدين/دائن) بحسب كودها.
  AcctNature _natureForLeaf(String code) {
    switch (code) {
      case '1101':
      case '1201':
      case '1900':
      case '5101':
        return AcctNature.debit;
      default:
        return AcctNature.credit;
    }
  }

  /// الفرع الأب لكل كود ورقة.
  TreeLine _parentFor({
    required String leafCode,
    required TreeLine assets,
    required TreeLine liabilities,
    required TreeLine revenue,
    required TreeLine expenses,
  }) {
    switch (leafCode) {
      case '1101':
        return assets.ensureChild(
          childCode: '1100',
          childName: 'Cash and funds',
          childNature: AcctNature.debit,
        );
      case '1201':
        return assets.ensureChild(
          childCode: '1200',
          childName: 'Receivables',
          childNature: AcctNature.debit,
        );
      case '2101':
        return liabilities.ensureChild(
          childCode: '2100',
          childName: 'Amounts due to well operators',
          childNature: AcctNature.credit,
        );
      case '4101':
        return revenue.ensureChild(
          childCode: '4100',
          childName: 'Water sales',
          childNature: AcctNature.credit,
        );
      case '5101':
      default:
        return expenses.ensureChild(
          childCode: '5100',
          childName: 'Well expenses',
          childNature: AcctNature.debit,
        );
    }
  }

  /// تُضاف ورقة لكل (بئر + نوع حساب) تحت الفرع المعطى.
  void _addLeaf(
    TreeLine parent, {
    required String wellId,
    required String wellName,
    required String accountName,
    required String accountType,
    required double debit,
    required double credit,
  }) {
    final TreeLine node = parent.ensureChild(
      childCode: '${parent.code}-$wellId',
      childName: wellName,
      childNature: parent.nature,
    );

    final TreeLine leaf = node.ensureChild(
      childCode: '${parent.code}-$wellId-$accountType',
      childName: accountName,
      childNature: parent.nature,
    );

    leaf.debit += debit;
    leaf.credit += credit;
  }

  void _sortTree(TreeLine node) {
    node.children.sort((TreeLine a, TreeLine b) => a.code.compareTo(b.code));

    for (final TreeLine child in node.children) {
      _sortTree(child);
    }
  }

  _AccountBucket _bucketFor(
    Map<String, _AccountBucket> buckets,
    String accountId,
    String wellId,
    String wellName,
  ) {
    final _AccountBucket? existing = buckets[accountId];

    if (existing != null) {
      if (existing.wellId.isEmpty && wellId.isNotEmpty) {
        final _AccountBucket updated = _AccountBucket(
          id: existing.id,
          name: existing.name,
          type: existing.type,
          wellId: wellId,
          wellName: wellName,
          isCustomer: existing.isCustomer,
          storedBalance: existing.storedBalance,
        );

        updated.debit = existing.debit;
        updated.credit = existing.credit;

        buckets[accountId] = updated;

        return updated;
      }

      return existing;
    }

    // حساب مذكور في القيد وغير موجود في accounts: نورده حتى لا يضيع رقم.
    final _AccountBucket created = _AccountBucket(
      id: accountId,
      name: 'Entry-only account ${accountId.substring(0, accountId.length > 6 ? 6 : accountId.length)}',
      type: '',
      wellId: wellId,
      wellName: wellName,
      isCustomer: false,
      storedBalance: 0,
    );

    buckets[accountId] = created;

    return created;
  }

  // ----------------------------------------------------------
  // أدوات
  // ----------------------------------------------------------

  static String? _text(Map<String, dynamic> data, List<String> keys) {
    for (final String key in keys) {
      final String value = data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) return value;
    }

    return null;
  }

  static double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    }

    return 0;
  }

  static DateTime? _date(Map<String, dynamic> data) {
    const List<String> keys = <String>[
      'date',
      'entryDate',
      'createdAt',
      'transactionDate',
    ];

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;

      if (value is String && value.trim().isNotEmpty) {
        final DateTime? parsed = DateTime.tryParse(value.trim());

        if (parsed != null) return parsed;
      }
    }

    return null;
  }
}
