// ============================================================
// voice_translate_page.dart
// شاشة «الترجمة الصوتية» — تستمع إلى الكلام وتحوّله إلى نص،
// ثم تترجمه إلى العربية سطراً بسطر.
//
// المصدران:
//   • الميكروفون : يعمل مباشرة في Chrome بلا خادم للتفريغ.
//   • صوت الاجتماع (Zoom / Meet / تبويب) : يحتاج خدمة تفريغ
//     صوتي عبر WebSocket، لأن المتصفح لا يسمح بتمرير صوت
//     التبويب إلى محرّك التعرّف المدمج.
//
// الترجمة تحتاج خادماً واحداً فقط: POST /api/translate/
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/my_app_bar.dart';
import 'speech_bridge.dart';
import 'translation_service.dart';

const Color _bg = Color(0xFFF5F9FF);
const Color _primary = Color(0xFF1565C0);
const Color _teal = Color(0xFF00897B);
const Color _dark = Color(0xFF10304F);
const Color _border = Color(0xFFE3ECF7);

/// مقطع واحد من المحادثة: الأصل الإنجليزي والترجمة العربية.
class _VoiceSegment {
  final String original;
  String arabic = '';
  bool pending = false;
  String? error;

  _VoiceSegment(this.original);
}

class VoiceTranslatePage extends StatefulWidget {
  const VoiceTranslatePage({super.key});

  @override
  State<VoiceTranslatePage> createState() => _VoiceTranslatePageState();
}

class _VoiceTranslatePageState extends State<VoiceTranslatePage> {
  final List<_VoiceSegment> _segments = <_VoiceSegment>[];

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _apiController = TextEditingController(
    text: TranslationService.baseUrl,
  );

  final TextEditingController _wsController = TextEditingController(
    text: 'ws://127.0.0.1:8000/ws/transcribe/',
  );

  String _mode = 'mic';

  bool _listening = false;
  bool _checking = true;
  bool _supported = false;
  bool _supportsSystemAudio = false;

  bool _saving = false;
  bool _captionsOpen = false;

  String _status = 'جاهز. اختر المصدر ثم اضغط «ابدأ الاستماع».';
  String _partial = '';
  String? _error;

  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  @override
  void dispose() {
    if (_listening) {
      _stopListening(quiet: true);
    }

    _scrollController.dispose();
    _apiController.dispose();
    _wsController.dispose();

    super.dispose();
  }

  // ----------------------------------------------------------
  // فحص الدعم
  // ----------------------------------------------------------

  Future<void> _checkSupport() async {
    final bool supported = await SpeechBridge.isSupported();
    final bool system = await SpeechBridge.supportsSystemAudio();

    if (!mounted) return;

    setState(() {
      _checking = false;
      _supported = supported;
      _supportsSystemAudio = system;

      if (!supported) {
        _status = 'هذه النسخة لا تدعم التعرّف على الكلام. '
            'افتح التطبيق في Chrome على الحاسوب.';
      }
    });
  }

  // ----------------------------------------------------------
  // الاستماع
  // ----------------------------------------------------------

  Future<void> _startListening() async {
    if (_listening) return;

    if (_mode == 'mic' && !_supported) {
      setState(() {
        _error = 'التعرّف على الكلام غير مدعوم في هذه النسخة.';
      });
      return;
    }

    setState(() {
      _error = null;
      _listening = true;
      _partial = '';
      _status = 'جارٍ بدء الاستماع…';
      _sessionStart = DateTime.now();
    });

    if (_mode == 'mic') {
      await SpeechBridge.startMic(
        language: 'en-US',
        onText: _onText,
        onStatus: _onStatus,
        onError: _onError,
      );
    } else {
      await SpeechBridge.startSystemAudio(
        websocketUrl: _wsController.text.trim(),
        onText: _onText,
        onStatus: _onStatus,
        onError: _onError,
      );
    }
  }

  Future<void> _stopListening({bool quiet = false}) async {
    if (_mode == 'mic') {
      await SpeechBridge.stopMic();
    } else {
      await SpeechBridge.stopSystemAudio();
    }

    if (!mounted) return;

    setState(() {
      _listening = false;
      _partial = '';

      if (!quiet) {
        _status = 'توقّف الاستماع.';
      }
    });

    if (!quiet && _segments.isNotEmpty) {
      await _saveSession(quiet: true);
    }
  }

  void _onText(String text, bool isFinal) {
    if (!mounted) return;

    final String clean = text.trim();

    if (clean.isEmpty) return;

    if (!isFinal) {
      setState(() {
        _partial = clean;
      });

      _pushCaptions('…', clean);

      return;
    }

    final _VoiceSegment segment = _VoiceSegment(clean);

    setState(() {
      _partial = '';
      _segments.add(segment);
      _status = 'يستمع… (${_segments.length} مقطع)';
    });

    _scrollToBottom();
    _translateSegment(segment);
  }

  void _onStatus(String message) {
    if (!mounted) return;

    setState(() {
      _status = message.isEmpty ? _status : message;
    });
  }

  void _onError(String message) {
    if (!mounted) return;

    setState(() {
      _error = message;
      _listening = false;
      _partial = '';
    });
  }

  // ----------------------------------------------------------
  // الترجمة
  // ----------------------------------------------------------

  Future<void> _translateSegment(_VoiceSegment segment) async {
    setState(() {
      segment.pending = true;
      segment.error = null;
    });

    try {
      final String arabic = await TranslationService.translate(
        text: segment.original,
      );

      if (!mounted) return;

      setState(() {
        segment.arabic = arabic;
        segment.pending = false;
      });

      _pushCaptions(arabic, segment.original);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        segment.pending = false;
        segment.error = 'تعذّرت الترجمة: $error';
      });
    }
  }

  Future<void> _retranslate(_VoiceSegment segment) async {
    segment.arabic = '';
    await _translateSegment(segment);
  }

  // ----------------------------------------------------------
  // الحفظ والتصدير
  // ----------------------------------------------------------

  String _buildTranscriptText() {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('محضر مترجم — my_water');
    buffer.writeln('الوقت: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('المصدر: ${_mode == 'mic' ? 'الميكروفون' : 'صوت الاجتماع'}');
    buffer.writeln('عدد المقاطع: ${_segments.length}');
    buffer.writeln('----------------------------------------');

    for (int i = 0; i < _segments.length; i++) {
      final _VoiceSegment segment = _segments[i];

      buffer.writeln();
      buffer.writeln('${i + 1}. ${segment.original}');
      buffer.writeln(
        segment.arabic.isEmpty
            ? '   — لم تُترجم بعد —'
            : '   → ${segment.arabic}',
      );
    }

    return buffer.toString();
  }

  Future<void> _copyTranscript() async {
    if (_segments.isEmpty) {
      _snack('لا يوجد نص لنسخه بعد.');
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: _buildTranscriptText()),
    );

    _snack('تم نسخ المحضر المترجم.');
  }

  Future<void> _saveSession({bool quiet = false}) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!quiet) _snack('سجّل الدخول لحفظ المحضر.', error: true);
      return;
    }

    if (_segments.isEmpty) {
      if (!quiet) _snack('لا يوجد نص لحفظه.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('voice_sessions')
          .add(<String, dynamic>{
        'ownerUid': user.uid,
        'ownerEmail': user.email ?? '',
        'mode': _mode,
        'startedAt': _sessionStart == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(_sessionStart!),
        'savedAt': FieldValue.serverTimestamp(),
        'segmentCount': _segments.length,
        'segments': _segments
            .map(
              (_VoiceSegment s) => <String, String>{
                'original': s.original,
                'arabic': s.arabic,
              },
            )
            .toList(),
      });

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      if (!quiet) _snack('تم حفظ المحضر في حسابك.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      if (!quiet) _snack('تعذّر الحفظ: $error', error: true);
    }
  }

  // ----------------------------------------------------------
  // أدوات
  // ----------------------------------------------------------

  String _formatDateTime(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');

    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إعدادات الخدمات'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: _apiController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان خادم الترجمة',
                      hintText: 'https://api.example.com',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wsController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان خدمة تفريغ صوت الاجتماع',
                      hintText: 'wss://api.example.com/ws/transcribe/',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الميكروفون لا يحتاج خدمة تفريغ. الترجمة تحتاج خادم الترجمة، '
                    'وصوت الاجتماع يحتاج خدمة تفريغ عبر WebSocket.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.6,
                      color: _dark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  TranslationService.baseUrl =
                      _apiController.text.trim().replaceAll(
                            RegExp(r'/+$'),
                            '',
                          );

                  setState(() {});

                  Navigator.of(dialogContext).pop();
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // النافذة العائمة فوق Zoom
  // ----------------------------------------------------------

  Future<void> _toggleCaptions() async {
    if (_captionsOpen) {
      await SpeechBridge.closeCaptions();

      if (!mounted) return;

      setState(() {
        _captionsOpen = false;
      });

      return;
    }

    final bool supported = await SpeechBridge.captionsSupported();

    if (!supported) {
      _snack(
        'النافذة العائمة تحتاج Chrome 116 أو أحدث على الحاسوب.',
        error: true,
      );
      return;
    }

    final bool opened = await SpeechBridge.openCaptions();

    if (!mounted) return;

    setState(() {
      _captionsOpen = opened;
    });

    if (opened) {
      _snack('نافذة الترجمة العائمة مفتوحة — يمكنك تصغير المتصفح وفتح Zoom.');
    }
  }

  Future<void> _pushCaptions(String arabic, String original) async {
    if (!_captionsOpen) return;

    await SpeechBridge.updateCaptions(
      arabic: arabic,
      original: original,
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
        backgroundColor: _bg,
        appBar: MyAppBar(
          title: 'الترجمة الصوتية',
          subtitle: 'Live speech → Arabic',
          icon: Icons.translate,
          actions: <Widget>[
            IconButton(
              tooltip: 'ترجمة عائمة فوق التطبيقات',
              onPressed: _toggleCaptions,
              icon: Icon(
                Icons.picture_in_picture_alt,
                color: _captionsOpen ? Colors.white : null,
              ),
            ),
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: _openSettings,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: _checking
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  _buildHeader(),
                  Expanded(child: _buildTranscript()),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool systemMode = _mode == 'system';

    return Container(
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _listening
                      ? (_status.isEmpty ? 'يستمع…' : _status)
                      : _status,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: _listening ? _teal : _dark.withValues(alpha: 0.75),
                    fontWeight: _listening ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _listening ? _teal : const Color(0xFFB9C7D8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                selected: !systemMode,
                onSelected: _listening
                    ? null
                    : (_) {
                        setState(() {
                          _mode = 'mic';
                        });
                      },
                avatar: const Icon(Icons.mic, size: 18),
                label: const Text('الميكروفون'),
              ),
              ChoiceChip(
                selected: systemMode,
                onSelected: (_listening || !_supportsSystemAudio)
                    ? null
                    : (_) {
                        setState(() {
                          _mode = 'system';
                        });
                      },
                avatar: const Icon(Icons.computer, size: 18),
                label: const Text('صوت الاجتماع'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            systemMode && !_supportsSystemAudio
                ? 'هذا المتصفح لا يسمح بالتقاط صوت التبويب. '
                    'استخدم Chrome على الحاسوب، أو اختر «الميكروفون».'
                : systemMode
                ? 'لمتابعة Zoom المكتبي: اختر «الشاشة الكاملة» ثم فعّل '
                    '«مشاركة صوت النظام» (Chrome على ويندوز). '
                    'لاجتماع في تبويب متصفح: اختر «تبويب Chrome» مع «مشاركة صوت التبويب».'
                : 'يستمع إلى الميكروفون مباشرة في المتصفح. '
                    'تكلّم بالإنجليزية وستظهر الترجمة العربية تلقائياً.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: _dark.withValues(alpha: 0.6),
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFC62828),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.6,
                        color: Color(0xFF8E1B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscript() {
    if (_segments.isEmpty && _partial.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.graphic_eq,
                size: 54,
                color: _primary.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 14),
              Text(
                'لم يبدأ الاستماع بعد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _dark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اضغط «ابدأ الاستماع» ثم تكلّم. كل جملة تنتهي تظهر '
                'بالعربية، ويمكنك نسخ المحضر أو حفظه في حسابك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: _dark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      itemCount: _segments.length + (_partial.isEmpty ? 0 : 1),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _segments.length) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, style: BorderStyle.solid),
            ),
            child: Text(
              _partial,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: _dark.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return _buildSegmentCard(_segments[index], index);
      },
    );
  }

  Widget _buildSegmentCard(_VoiceSegment segment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  segment.original,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: _dark.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.subdirectory_arrow_left,
                size: 15,
                color: _teal.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: segment.pending
                    ? Row(
                        children: <Widget>[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'جارٍ الترجمة…',
                            style: TextStyle(
                              fontSize: 12,
                              color: _dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        segment.arabic.isEmpty
                            ? '—'
                            : segment.arabic,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.75,
                          fontWeight: FontWeight.w600,
                          color: _dark,
                        ),
                      ),
              ),
              if (segment.error != null)
                IconButton(
                  tooltip: 'إعادة المحاولة',
                  onPressed: () => _retranslate(segment),
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFFC62828),
                  ),
                ),
            ],
          ),
          if (segment.error != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              segment.error!,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.5,
                color: Color(0xFFC62828),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _listening ? const Color(0xFFC62828) : _teal,
                ),
                onPressed: _listening ? _stopListening : _startListening,
                icon: Icon(_listening ? Icons.stop : Icons.mic),
                label: Text(_listening ? 'أوقف الاستماع' : 'ابدأ الاستماع'),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'نسخ المحضر',
              onPressed: _segments.isEmpty ? null : _copyTranscript,
              icon: const Icon(Icons.copy_all_outlined, color: _primary),
            ),
            IconButton(
              tooltip: 'حفظ في حسابي',
              onPressed: _saving || _segments.isEmpty
                  ? null
                  : () => _saveSession(),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.cloud_upload_outlined,
                      color: _primary,
                    ),
            ),
            IconButton(
              tooltip: 'مسح',
              onPressed: !_listening && _segments.isNotEmpty
                  ? () {
                      setState(() {
                        _segments.clear();
                        _partial = '';
                        _status = 'جاهز لبدء محضر جديد.';
                      });
                    }
                  : null,
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Color(0xFF78909C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
