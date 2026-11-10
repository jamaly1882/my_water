// ============================================================
// well_agent_screen.dart
// شاشة وكيل البئر: لوحة واحدة تجمع ما يحتاجه وكيل البئر في مكان
// واحد — الزبائن، الحسابات الأربعة، الاستهلاك، عدد الأدوار،
// الفاقد المُدخل يدويًا، والقراءات القديمة (صورة + رقم + تاريخ).
//
// المجموعات المستخدمة:
//   wells                 وثيقة البئر (الاسم والموقع)
//   well_customers        الزبائن المرتبطون بالبئر
//   accounts              الحسابات: sales / cash / expenses / worker
//   cycles                الدورات (القراءات والاستهلاك)
//   well_losses           (جديدة) الفاقد المُدخل يدويًا لكل دورة
//   well_legacy_readings  (جديدة) القراءات قبل استخدام النظام
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/my_app_bar.dart';

class WellAgentScreen extends StatefulWidget {
  final String wellId;
  final String? wellName;
  final String? supervisorId;

  const WellAgentScreen({
    super.key,
    required this.wellId,
    this.wellName,
    this.supervisorId,
  });

  @override
  State<WellAgentScreen> createState() => _WellAgentScreenState();
}

/// صف واحد في جدول الزبائن.
class _SubscriberRow {
  final String customerId;
  final String name;
  final String phone;
  final int cyclesCount;
  final bool hasOpenCycle;
  final int? lastReading;
  final int lastConsumption;

  _SubscriberRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.cyclesCount,
    required this.hasOpenCycle,
    required this.lastReading,
    required this.lastConsumption,
  });
}

class _WellAgentScreenState extends State<WellAgentScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const Color appColor = Colors.blue;

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _well = <String, dynamic>{};

  List<_SubscriberRow> _subscribers = <_SubscriberRow>[];
  Map<String, int> _balances = <String, int>{};
  Map<String, String> _accountNames = <String, String>{};

  List<Map<String, dynamic>> _losses = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _legacy = <Map<String, dynamic>>[];

  int _openCycles = 0;
  int _totalConsumption = 0;
  int _lossVolume = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _fmt(num? value) {
    final int v = value?.round() ?? 0;
    final String digits = v.abs().toString();
    final StringBuffer out = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }

    return v < 0 ? '-$out' : out.toString();
  }

  /// يقرأ رقمًا من حقل نصي أو من حقل رقمي.
  int _reading(Map<String, dynamic> data, String textKey, String valueKey) {
    final dynamic raw = data[valueKey];
    if (raw is num) return raw.toInt();

    final String digits =
        (data[textKey] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');

    return int.tryParse(digits) ?? 0;
  }

  bool _isClosed(Map<String, dynamic> data) =>
      (data['status'] ?? '').toString().toLowerCase() == 'closed';

  bool _isOpen(Map<String, dynamic> data) =>
      (data['status'] ?? '').toString().toLowerCase() == 'open';

  int _cycleNumber(Map<String, dynamic> data) {
    final dynamic raw = data['cycleNumber'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  int _consumption(Map<String, dynamic> data) {
    final dynamic raw = data['consumption'];
    if (raw is num) return raw.toInt();

    final int diff = _reading(data, 'currentReading', 'currentReadingValue') -
        _reading(data, 'previousReading', 'previousReadingValue');

    return diff > 0 ? diff : 0;
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _shortDate(dynamic value) {
    final DateTime? date = _asDate(value);
    if (date == null) return '—';

    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // الوثائق تُجلب بالتسلسل لتفادي مشاكل الأنواع في Future.wait.
      final DocumentSnapshot<Map<String, dynamic>> wellDoc = await firestore
          .collection('wells')
          .doc(widget.wellId)
          .get();

      final QuerySnapshot<Map<String, dynamic>> customers = await firestore
          .collection('well_customers')
          .where('wellId', isEqualTo: widget.wellId)
          .get();

      final QuerySnapshot<Map<String, dynamic>> accounts = await firestore
          .collection('accounts')
          .where('wellId', isEqualTo: widget.wellId)
          .get();

      final QuerySnapshot<Map<String, dynamic>> cycles = await firestore
          .collection('cycles')
          .where('wellId', isEqualTo: widget.wellId)
          .get();

      final QuerySnapshot<Map<String, dynamic>> losses = await firestore
          .collection('well_losses')
          .where('wellId', isEqualTo: widget.wellId)
          .get();

      final QuerySnapshot<Map<String, dynamic>> legacy = await firestore
          .collection('well_legacy_readings')
          .where('wellId', isEqualTo: widget.wellId)
          .get();

      // ---------------- الحسابات ----------------
      final Map<String, int> balances = <String, int>{};
      final Map<String, String> accountNames = <String, String>{};

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in accounts.docs) {
        final Map<String, dynamic> data = doc.data();
        final String type = (data['type'] ?? '').toString();
        final dynamic raw = data['balance'];
        final int balance = raw is num ? raw.toInt() : 0;

        balances[type] = (balances[type] ?? 0) + balance;
        accountNames[type] = (data['name'] ?? type).toString();
      }

      // ---------------- الدورات ----------------
      final Map<String, List<Map<String, dynamic>>> byCustomer =
          <String, List<Map<String, dynamic>>>{};

      int openCycles = 0;
      int totalConsumption = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in cycles.docs) {
        final Map<String, dynamic> data = doc.data();
        final String customerId = (data['customerId'] ?? '').toString();

        byCustomer.putIfAbsent(customerId, () => <Map<String, dynamic>>[]);
        byCustomer[customerId]!.add(data);

        if (_isOpen(data)) openCycles++;
        if (_isClosed(data)) totalConsumption += _consumption(data);
      }

      // ---------------- الزبائن ----------------
      final List<_SubscriberRow> rows = <_SubscriberRow>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in customers.docs) {
        final Map<String, dynamic> data = doc.data();
        final String customerId = (data['customerId'] ?? '').toString();

        final List<Map<String, dynamic>> list =
            byCustomer[customerId] ?? <Map<String, dynamic>>[];

        list.sort((a, b) => _cycleNumber(a).compareTo(_cycleNumber(b)));

        Map<String, dynamic>? lastClosed;
        bool open = false;

        for (final Map<String, dynamic> cycle in list) {
          if (_isClosed(cycle)) lastClosed = cycle;
          if (_isOpen(cycle)) open = true;
        }

        rows.add(
          _SubscriberRow(
            customerId: customerId,
            name: (data['customerName'] ?? '—').toString(),
            phone: (data['phone'] ?? '').toString(),
            cyclesCount: list.length,
            hasOpenCycle: open,
            lastReading: lastClosed == null
                ? null
                : _reading(
                    lastClosed,
                    'currentReading',
                    'currentReadingValue',
                  ),
            lastConsumption:
                lastClosed == null ? 0 : _consumption(lastClosed),
          ),
        );
      }

      rows.sort((a, b) => a.name.compareTo(b.name));

      // ---------------- الفاقد ----------------
      final List<Map<String, dynamic>> lossRows = losses.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
          .toList();

      lossRows.sort((a, b) {
        final DateTime? da = _asDate(a['createdAt']);
        final DateTime? db = _asDate(b['createdAt']);
        return (db ?? DateTime(2000)).compareTo(da ?? DateTime(2000));
      });

      int lossVolume = 0;
      for (final Map<String, dynamic> row in lossRows) {
        final dynamic raw = row['volumeM3'];
        if (raw is num) lossVolume += raw.round();
      }

      // ---------------- القراءات القديمة ----------------
      final List<Map<String, dynamic>> legacyRows = legacy.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
          .toList();

      legacyRows.sort((a, b) {
        final DateTime? da = _asDate(a['readingDate']);
        final DateTime? db = _asDate(b['readingDate']);
        return (db ?? DateTime(2000)).compareTo(da ?? DateTime(2000));
      });

      if (!mounted) return;

      setState(() {
        _well = wellDoc.data() ?? <String, dynamic>{};
        _balances = balances;
        _accountNames = accountNames;
        _subscribers = rows;
        _openCycles = openCycles;
        _totalConsumption = totalConsumption;
        _losses = lossRows;
        _legacy = legacyRows;
        _lossVolume = lossVolume;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _wellName {
    final String fromDoc = (_well['name'] ?? '').toString().trim();
    if (fromDoc.isNotEmpty) return fromDoc;

    return widget.wellName?.trim().isNotEmpty == true
        ? widget.wellName!.trim()
        : 'Well';
  }

  String get _location {
    final List<String> parts = <String>[
      (_well['provinceName'] ?? '').toString(),
      (_well['districtName'] ?? '').toString(),
      (_well['hamletName'] ?? '').toString(),
      (_well['villageName'] ?? '').toString(),
    ].where((String part) => part.trim().isNotEmpty).toList();

    return parts.join(' · ');
  }

  // ============================================================
  // ADD LOSS
  // ============================================================

  Future<void> _addLoss() async {
    final TextEditingController label = TextEditingController(
      text: 'Cycle ${_openCycles + 1}',
    );
    final TextEditingController volume = TextEditingController();
    final TextEditingController percent = TextEditingController();
    final TextEditingController note = TextEditingController();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل الفاقد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: label,
                    decoration: const InputDecoration(
                      labelText: 'Cycle label',
                      hintText: 'Cycle 3 · November',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: volume,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Loss volume (m³)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: percent,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Loss percent (%)',
                      helperText: 'Optional — calculated from the volume if empty',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Leak repaired, meter replaced, ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;

    final double m3 = double.tryParse(volume.text.trim()) ?? 0;

    if (m3 <= 0) {
      _message('Enter the loss volume in m³');
      return;
    }

    double pct = double.tryParse(percent.text.trim()) ?? 0;

    if (pct <= 0 && _totalConsumption > 0) {
      pct = (m3 / _totalConsumption) * 100;
    }

    try {
      await firestore.collection('well_losses').add(<String, dynamic>{
        'wellId': widget.wellId,
        'wellName': _wellName,
        'cycleLabel': label.text.trim(),
        'volumeM3': m3,
        'percent': double.parse(pct.toStringAsFixed(2)),
        'computedFromConsumption': _totalConsumption,
        'note': note.text.trim(),
        'supervisorId': widget.supervisorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _message('Loss recorded');
      await _load();
    } catch (e) {
      _message('Could not save the loss: $e');
    }
  }

  // ============================================================
  // ADD LEGACY READING
  // ============================================================

  Future<void> _addLegacyReading() async {
    final ImagePicker picker = ImagePicker();

    final bool? camera = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera, color: appColor),
                title: const Text('Take a photo of the old register'),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: appColor),
                title: const Text('Choose a photo from the gallery'),
                onTap: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        );
      },
    );

    if (camera == null) return;

    XFile? file;

    try {
      file = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 45,
        maxWidth: 900,
      );
    } catch (e) {
      _message('Could not open the camera: $e');
      return;
    }

    if (file == null) return;

    final List<int> bytes = await file.readAsBytes();
    final String base64Image = base64Encode(bytes);

    final TextEditingController reading = TextEditingController();
    final TextEditingController note = TextEditingController();
    DateTime date = DateTime.now();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setDialogState,
          ) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('قراءة قديمة'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: reading,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Meter reading',
                          hintText: '15200',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text('Reading date: ${_shortDate(date)}'),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              date = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: note,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Paper register, before the platform',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (saved != true) return;

    final String digits =
        reading.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      _message('Enter the reading number');
      return;
    }

    if (base64Image.length > 900000) {
      _message('The photo is too large — try again with a lower quality');
      return;
    }

    try {
      await firestore
          .collection('well_legacy_readings')
          .add(<String, dynamic>{
        'wellId': widget.wellId,
        'wellName': _wellName,
        'reading': digits,
        'readingValue': int.tryParse(digits) ?? 0,
        'readingDate': Timestamp.fromDate(date),
        'note': note.text.trim(),
        'imageBase64': base64Image,
        'imageMime': 'image/jpeg',
        'supervisorId': widget.supervisorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _message('Old reading saved');
      await _load();
    } catch (e) {
      _message('Could not save the reading: $e');
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.water_drop, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _wellName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_location.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _location,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNTS
  // ============================================================

  Widget _buildAccounts() {
    const List<List<String>> types = <List<String>>[
      <String>['sales', 'Sales', 'المبيعات'],
      <String>['cash', 'Fund', 'الصندوق'],
      <String>['expenses', 'Expenses', 'المصروفات'],
      <String>['worker', 'Operator', 'العامل'],
    ];

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Accounts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (final List<String> type in types)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            type[1],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _accountNames[type[0]] ?? type[2],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _balances.containsKey(type[0])
                          ? _fmt(_balances[type[0]])
                          : '—',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBSCRIBERS
  // ============================================================

  Widget _buildSubscribers() {
    if (_subscribers.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(top: 14),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No subscribers linked to this well yet.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Subscribers · consumption · cycles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Last reading comes from the last closed cycle.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            for (final _SubscriberRow row in _subscribers)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            row.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (row.hasOpenCycle)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Open cycle',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: <Widget>[
                        Text(
                          'Last reading: '
                          '${row.lastReading == null ? '—' : _fmt(row.lastReading)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Consumption: ${_fmt(row.lastConsumption)} m³',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Cycles: ${row.cyclesCount}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOSS
  // ============================================================

  Widget _buildLoss() {
    final double percent = _totalConsumption > 0
        ? (_lossVolume / _totalConsumption) * 100
        : 0;

    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Loss per cycle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addLoss,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add loss'),
                ),
              ],
            ),
            Text(
              'Entered manually for each cycle: '
              '${_fmt(_lossVolume)} m³'
              '${_totalConsumption > 0 ? ' · ${percent.toStringAsFixed(1)}% of the metered water' : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (_losses.isEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Text(
                'No loss recorded yet.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 10),
              for (final Map<String, dynamic> row in _losses.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.report_gmailerrorred,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${row['cycleLabel'] ?? 'Cycle'} · '
                          '${_shortDate(row['createdAt'])}'
                          '${(row['note'] ?? '').toString().trim().isEmpty ? '' : ' · ${row['note']}'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${row['volumeM3'] is num ? _fmt(row['volumeM3'] as num) : row['volumeM3']} m³',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LEGACY READINGS
  // ============================================================

  Widget _image(String base64Image) {
    try {
      final Uint8List bytes = base64Decode(base64Image);
      return Image.memory(bytes, width: 46, height: 46, fit: BoxFit.cover);
    } catch (_) {
      return const Icon(Icons.broken_image, size: 24, color: Colors.black26);
    }
  }

  Widget _buildLegacy() {
    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Readings before the platform',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addLegacyReading,
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('Add photo'),
                ),
              ],
            ),
            const Text(
              'Photo + number + date — the baseline the platform continues from.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (_legacy.isEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Text(
                'No old readings recorded yet.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 10),
              for (final Map<String, dynamic> row in _legacy)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _image((row['imageBase64'] ?? '').toString()),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${row['reading'] ?? '—'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _shortDate(row['readingDate']),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: MyAppBar(
          title: 'Well agent',
          subtitle: _wellName,
          icon: Icons.person_pin_circle,
          actions: <Widget>[
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load the well data:\n$_error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(14),
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              _kpi(
                                'Subscribers',
                                '${_subscribers.length}',
                                Icons.people,
                                Colors.blue,
                              ),
                              _kpi(
                                'Open cycles',
                                '$_openCycles',
                                Icons.timelapse,
                                Colors.orange,
                              ),
                              _kpi(
                                'Metered m³',
                                _fmt(_totalConsumption),
                                Icons.straighten,
                                Colors.teal,
                              ),
                              _kpi(
                                'Loss m³',
                                _fmt(_lossVolume),
                                Icons.warning_amber_rounded,
                                Colors.redAccent,
                              ),
                            ],
                          ),
                          _buildAccounts(),
                          _buildSubscribers(),
                          _buildLoss(),
                          _buildLegacy(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
