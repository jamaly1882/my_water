// ============================================================
// challenge_brief_page.dart
// شاشة "ملف تحدي المياه" — Water Challenge Brief
// برنامج AYC Youth Pitches · الأسبوع الأول (2–6 نوفمبر)
//
// الشاشة تعرض الطبقات الأربع يوماً بيوم، تحفظ ما تكتبه في
// Firestore، وتصدّر الملف نصاً جاهزاً للصق في Miro أو للتسليم.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/my_app_bar.dart';
import 'challenge_brief_spec.dart';

// ============================================================
// ألوان الشاشة
// ============================================================

const Color _pageBackground = Color(0xFFF5F9FF);
const Color _textDark = Color(0xFF10304F);
const Color _border = Color(0xFFE3ECF7);

class ChallengeBriefPage extends StatefulWidget {
  const ChallengeBriefPage({super.key});

  @override
  State<ChallengeBriefPage> createState() => _ChallengeBriefPageState();
}

class _ChallengeBriefPageState extends State<ChallengeBriefPage> {
  // ----------------------------------------------------------
  // الحالة
  // ----------------------------------------------------------

  static const String _collection = 'water_challenge_briefs';

  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  final TextEditingController _ventureController = TextEditingController();

  int _step = 0;

  bool _loading = true;
  bool _saving = false;

  String? _loadError;

  // ----------------------------------------------------------
  // دورة الحياة
  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();

    for (final BriefLayerSpec layer in kBriefLayers) {
      for (final BriefFieldSpec field in layer.fields) {
        _controllers[_keyOf(layer.key, field.key)] =
            TextEditingController();
      }
    }

    _loadDraft();
  }

  @override
  void dispose() {
    for (final TextEditingController controller
        in _controllers.values) {
      controller.dispose();
    }

    _ventureController.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------
  // أدوات مساعدة
  // ----------------------------------------------------------

  String _keyOf(String layerKey, String fieldKey) =>
      '$layerKey.$fieldKey';

  TextEditingController _controllerOf(
    String layerKey,
    String fieldKey,
  ) {
    return _controllers[_keyOf(layerKey, fieldKey)]!;
  }

  int get _totalFields {
    int total = 0;

    for (final BriefLayerSpec layer in kBriefLayers) {
      total += layer.fields.length;
    }

    return total;
  }

  int get _filledFields {
    int filled = 0;

    for (final BriefLayerSpec layer in kBriefLayers) {
      for (final BriefFieldSpec field in layer.fields) {
        if (_controllerOf(layer.key, field.key)
            .text
            .trim()
            .isNotEmpty) {
          filled++;
        }
      }
    }

    return filled;
  }

  int _filledInLayer(BriefLayerSpec layer) {
    int filled = 0;

    for (final BriefFieldSpec field in layer.fields) {
      if (_controllerOf(layer.key, field.key)
          .text
          .trim()
          .isNotEmpty) {
        filled++;
      }
    }

    return filled;
  }

  String _nowText() {
    final DateTime now = DateTime.now();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  // ----------------------------------------------------------
  // تحميل المسودة
  // ----------------------------------------------------------

  Future<void> _loadDraft() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _loading = false;
        _loadError = 'لا يوجد مستخدم مسجل الدخول. '
            'سجّل الدخول أولاً ليُحفظ الملف في حسابك.';
      });

      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection(_collection)
              .doc(user.uid)
              .get();

      if (snapshot.exists && snapshot.data() != null) {
        final Map<String, dynamic> data = snapshot.data()!;

        _ventureController.text =
            (data['ventureName'] ?? '').toString();

        final dynamic layersRaw = data['layers'];

        if (layersRaw is Map) {
          for (final BriefLayerSpec layer in kBriefLayers) {
            final dynamic layerRaw = layersRaw[layer.key];

            if (layerRaw is Map) {
              for (final BriefFieldSpec field in layer.fields) {
                final dynamic value = layerRaw[field.key];

                _controllerOf(layer.key, field.key).text =
                    value == null ? '' : value.toString();
              }
            }
          }
        }
      }
    } catch (error) {
      _loadError = 'تعذر تحميل المسودة: $error';
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  // ----------------------------------------------------------
  // الحفظ
  // ----------------------------------------------------------

  Future<bool> _save({bool quiet = false}) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack(
        'سجّل الدخول أولاً ليُحفظ الملف في حسابك.',
        error: true,
      );

      return false;
    }

    setState(() {
      _saving = true;
    });

    try {
      final Map<String, dynamic> layers = <String, dynamic>{};

      for (final BriefLayerSpec layer in kBriefLayers) {
        final Map<String, String> values = <String, String>{};

        for (final BriefFieldSpec field in layer.fields) {
          values[field.key] =
              _controllerOf(layer.key, field.key).text.trim();
        }

        layers[layer.key] = values;
      }

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'ownerUid': user.uid,
          'ownerEmail': user.email ?? '',
          'ventureName': _ventureController.text.trim(),
          'layers': layers,
          'completedFields': _filledFields,
          'totalFields': _totalFields,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return true;

      setState(() {
        _saving = false;
      });

      if (!quiet) {
        _snack('تم حفظ الملف — $_filledFields من $_totalFields حقلًا.');
      }

      return true;
    } catch (error) {
      if (!mounted) return false;

      setState(() {
        _saving = false;
      });

      _snack('تعذر الحفظ: $error', error: true);

      return false;
    }
  }

  // ----------------------------------------------------------
  // نص التصدير
  // ----------------------------------------------------------

  String _buildBriefText() {
    final String venture = _ventureController.text.trim();

    final StringBuffer buffer = StringBuffer();

    buffer.writeln('============================================');
    buffer.writeln('ملف تحدي المياه — WATER CHALLENGE BRIEF');
    buffer.writeln('AYC Youth Pitches · الأسبوع الأول');
    buffer.writeln('المشروع: ${venture.isEmpty ? '—' : venture}');
    buffer.writeln('آخر تصدير: ${_nowText()}');
    buffer.writeln(
      'الاكتمال: $_filledFields / $_totalFields حقلًا',
    );
    buffer.writeln('============================================');
    buffer.writeln();

    for (int i = 0; i < kBriefLayers.length; i++) {
      final BriefLayerSpec layer = kBriefLayers[i];

      buffer.writeln(
        'الطبقة ${i + 1} · ${layer.titleAr}',
      );
      buffer.writeln(layer.titleEn);
      buffer.writeln('العدد المطلوب: ${layer.fields.length} حقول');
      buffer.writeln('--------------------------------------------');

      for (final BriefFieldSpec field in layer.fields) {
        final String value =
            _controllerOf(layer.key, field.key).text.trim();

        buffer.writeln('${field.labelAr} (${field.labelEn})');
        buffer.writeln(value.isEmpty ? '—' : value);
        buffer.writeln();
      }

      buffer.writeln('============================================');
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ----------------------------------------------------------
  // نافذة المعاينة والتصدير
  // ----------------------------------------------------------

  Future<void> _showExportDialog() async {
    await _save(quiet: true);

    if (!mounted) return;

    final String text = _buildBriefText();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: <Widget>[
                Icon(Icons.description_outlined, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تصدير الملف',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: _textDark,
                  ),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();

                  _snack('تم النسخ.');
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ الكل'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // البناء
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: MyAppBar(
          title: 'Challenge Brief',
          icon: Icons.assignment_outlined,
          actions: <Widget>[
            _saving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'حفظ',
                    onPressed: () => _save(),
                    icon: const Icon(Icons.save_outlined),
                  ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  _buildProgressHeader(),
                  _buildStepSelector(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (_loadError != null)
                            _buildLoadErrorBanner(),
                          _buildLayerHeader(kBriefLayers[_step]),
                          ..._buildLayerFields(kBriefLayers[_step]),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ترويسة الاكتمال + اسم المشروع
  // ----------------------------------------------------------

  Widget _buildProgressHeader() {
    final double progress =
        _totalFields == 0 ? 0 : _filledFields / _totalFields;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _ventureController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'اسم المشروع',
              hintText: 'مثال: منصة مياه الآبار الذكية',
              prefixIcon: Icon(Icons.water_drop_outlined),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8F0FA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$_filledFields / $_totalFields',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'الملف يُحفظ في حسابك ويُصدَّر نصاً جاهزاً للتسليم يوم الجمعة ٦ نوفمبر قبل الظهر.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: _textDark.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline,
            color: Color(0xFFEF6C00),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _loadError!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF7A4100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // اختيار الطبقة
  // ----------------------------------------------------------

  Widget _buildStepSelector() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        itemCount: kBriefLayers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final BriefLayerSpec layer = kBriefLayers[index];
          final bool selected = index == _step;
          final int filled = _filledInLayer(layer);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _step = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? layer.color
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? layer.color : _border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        layer.icon,
                        size: 16,
                        color: selected ? Colors.white : layer.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        layer.dayAr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? Colors.white
                              : layer.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    layer.titleAr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$filled / ${layer.fields.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : _textDark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // ترويسة الطبقة
  // ----------------------------------------------------------

  Widget _buildLayerHeader(BriefLayerSpec layer) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            layer.color,
            layer.color.withValues(alpha: 0.82),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(layer.icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  layer.titleAr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            layer.titleEn,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            layer.questionAr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            layer.questionEn,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // حقول الطبقة
  // ----------------------------------------------------------

  List<Widget> _buildLayerFields(BriefLayerSpec layer) {
    return layer.fields.map((BriefFieldSpec field) {
      final TextEditingController controller =
          _controllerOf(layer.key, field.key);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: layer.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.labelAr,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                ),
                Text(
                  field.labelEn,
                  style: TextStyle(
                    fontSize: 10,
                    color: _textDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: field.lines,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: _textDark,
              ),
              decoration: InputDecoration(
                hintText: field.hint,
                hintStyle: TextStyle(
                  fontSize: 11.5,
                  height: 1.6,
                  color: _textDark.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FBFE),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: layer.color,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ----------------------------------------------------------
  // شريط الأسفل
  // ----------------------------------------------------------

  Widget _buildBottomBar() {
    final bool isFirst = _step == 0;
    final bool isLast = _step == kBriefLayers.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst
                    ? null
                    : () {
                        setState(() {
                          _step = _step - 1;
                        });
                      },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('السابق'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLast
                  ? FilledButton.icon(
                      onPressed: _saving ? null : _showExportDialog,
                      icon: const Icon(
                        Icons.ios_share,
                        size: 18,
                      ),
                      label: const Text('تصدير الملف'),
                    )
                  : FilledButton.icon(
                      onPressed: () {
                        _save(quiet: true);

                        setState(() {
                          _step = _step + 1;
                        });
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                      label: const Text('التالي'),
                    ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'حفظ',
              onPressed: _saving ? null : () => _save(),
              icon: const Icon(
                Icons.save_outlined,
                color: Color(0xFF1565C0),
              ),
            ),
            IconButton(
              tooltip: 'تصدير',
              onPressed: _saving ? null : _showExportDialog,
              icon: const Icon(
                Icons.copy_all_outlined,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
