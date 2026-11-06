// ============================================================
// ocr_quality_widgets.dart
// مكونات واجهة فحص جودة الصورة ومراجعة خانات العداد (6 أو 7)
// تعمل على جميع المنصات (Mobile / Web)
// ============================================================

import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';

// ============================================================
// صورة العداد القابلة للتكبير لتسهيل القراءة اليدوية
// عرض قابل للتكبير والتحريك + زر فتح ملء الشاشة.
// لا يمسّ منطق القراءة إطلاقًا؛ مجرد أداة عرض لمساعدة المستخدم
// على رؤية الخانات الباهتة وكتابتها يدويًا بدقة.
// ============================================================

class ZoomableMeterPhoto extends StatelessWidget {
  final Uint8List bytes;
  final double height;
  final String label;

  const ZoomableMeterPhoto({
    super.key,
    required this.bytes,
    this.height = 200,
    this.label = 'Meter photo',
  });

  void _openFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        final Size screen = MediaQuery.of(dialogContext).size;
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: SizedBox(
            width: screen.width,
            height: screen.height * 0.9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 10.0,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Pinch or scroll to zoom • drag to move',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: label,
          image: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: height,
              color: Colors.black87,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 8.0,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.zoom_in, size: 16, color: Colors.blueGrey.shade600),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Pinch or scroll to zoom into the digits',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openFullScreen(context),
              icon: const Icon(Icons.fullscreen, size: 18),
              label: const Text('Enlarge', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// بطاقة عرض جودة الصورة
// ============================================================

class ImageQualityCard extends StatelessWidget {
  final ImageQualityReport report;
  final bool compact;

  const ImageQualityCard({
    super.key,
    required this.report,
    this.compact = false,
  });

  Color _levelColor(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.excellent:
        return Colors.green.shade700;
      case ImageQualityLevel.good:
        return Colors.blue.shade700;
      case ImageQualityLevel.fair:
        return Colors.orange.shade800;
      case ImageQualityLevel.poor:
        return Colors.red.shade700;
    }
  }

  IconData _levelIcon(ImageQualityLevel level) {
    switch (level) {
      case ImageQualityLevel.excellent:
        return Icons.verified;
      case ImageQualityLevel.good:
        return Icons.check_circle_outline;
      case ImageQualityLevel.fair:
        return Icons.warning_amber_rounded;
      case ImageQualityLevel.poor:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _levelColor(report.level);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _levelIcon(report.level),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Meter photo quality: ${report.levelText}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${report.overallScore.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricBar(
                    label: 'Sharpness',
                    score: report.sharpnessScore,
                    icon: Icons.center_focus_strong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricBar(
                    label: 'Lighting',
                    score: report.brightnessScore,
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _metricBar(
                    label: 'Contrast',
                    score: report.contrastScore,
                    icon: Icons.contrast,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricBar(
                    label: 'No glare',
                    score: report.glareScore,
                    icon: Icons.flare_outlined,
                  ),
                ),
              ],
            ),
            if (report.issues.isNotEmpty) ...[
              const Divider(height: 20),
              ...report.issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          issue,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (report.tips.isNotEmpty && !compact) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tips for a better read:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...report.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $tip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
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
    );
  }

  Widget _metricBar({
    required String label,
    required double score,
    required IconData icon,
  }) {
    final double normalized = (score / 100.0).clamp(0.0, 1.0);
    final Color barColor = score >= 70
        ? Colors.green
        : score >= 45
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${score.round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// محرر ومراجعة خانات العداد (6 أو 7) مع إدخال يدوي آمن
// ============================================================

class MeterReadingEditor extends StatefulWidget {
  final String reading;
  final int digitCount;
  final List<double> digitConfidences;
  final List<String> alternatives;
  final int? previousReading;
  final ValueChanged<String> onChanged;
  final ValueChanged<int> onDigitCountChanged;

  const MeterReadingEditor({
    super.key,
    required this.reading,
    required this.digitCount,
    required this.onChanged,
    required this.onDigitCountChanged,
    this.digitConfidences = const <double>[],
    this.alternatives = const <String>[],
    this.previousReading,
  });

  @override
  State<MeterReadingEditor> createState() => _MeterReadingEditorState();
}

class _MeterReadingEditorState extends State<MeterReadingEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.reading);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant MeterReadingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reading != _controller.text) {
      _controller.text = widget.reading;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setReading(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    widget.onChanged(value);
  }

  void _updateDigit(int index, int delta) {
    final String clean = MeterAnalyzer.normalize(_controller.text);
    // نعدّل فقط الخانات المُدخلة فعلًا؛ لا نضيف أرقامًا غير موجودة.
    if (index < 0 || index >= clean.length) return;
    final List<int> digits = clean.split('').map(int.parse).toList();
    digits[index] = (digits[index] + delta + 10) % 10;
    _setReading(digits.join());
  }

  @override
  Widget build(BuildContext context) {
    final String clean = MeterAnalyzer.normalize(_controller.text);
    final bool hasFullLength = clean.length == widget.digitCount;
    final int? currentInt = hasFullLength ? int.tryParse(clean) : null;

    final bool hasPrevious =
        widget.previousReading != null && widget.previousReading! >= 0;
    final bool isLessThanPrevious = hasPrevious &&
        currentInt != null &&
        currentInt < widget.previousReading!;
    final int? consumption = hasPrevious && currentInt != null && !isLessThanPrevious
        ? currentInt - widget.previousReading!
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Text(
            'Check the ${widget.digitCount} digits against the photo. '
            'Leading zeros are kept exactly as shown.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(value: 6, label: Text('6 digits')),
              ButtonSegment<int>(value: 7, label: Text('7 digits')),
            ],
            selected: {widget.digitCount},
            onSelectionChanged: (selection) {
              widget.onDigitCountChanged(selection.first);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.digitCount),
            ],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: 'Meter reading',
              hintText: widget.digitCount == 6 ? '065004' : '0650040',
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            onChanged: widget.onChanged,
          ),
          const SizedBox(height: 10),
          // صف الخانات ظاهر دائمًا: الخانات المُدخلة كأزرار تمرير،
          // والفارغة كخانات إرشادية فارغة (لا تُخترع أرقامًا).
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(widget.digitCount, (index) {
                  final bool filled = index < clean.length;
                  final double conf = index < widget.digitConfidences.length
                      ? widget.digitConfidences[index]
                      : 90.0;
                  final bool isUncertain = filled && conf < 72.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: filled
                        ? _buildDigitRoller(
                            index: index,
                            digit: int.parse(clean[index]),
                            isUncertain: isUncertain,
                          )
                        : _buildDigitPlaceholder(),
                  );
                }),
              ),
            ),
          ),
          if (!hasFullLength) ...[
            const SizedBox(height: 8),
            Text(
              'Enter all ${widget.digitCount} digits shown in the meter window. '
              'Do not add zeros that are not on the meter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasFullLength && widget.digitConfidences.any((c) => c < 72.0)) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Digits in orange are less clear in the photo — double-check them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Other possible readings:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...widget.alternatives
                    .where((alt) => MeterAnalyzer.isValid(alt))
                    .map(
                  (alt) => ActionChip(
                    label: Text(
                      alt,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    onPressed: () {
                      widget.onDigitCountChanged(alt.length);
                      _setReading(alt);
                    },
                  ),
                ),
              ],
            ),
          ],
          if (hasPrevious) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isLessThanPrevious
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLessThanPrevious
                      ? Colors.red.shade300
                      : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLessThanPrevious
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    color: isLessThanPrevious
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLessThanPrevious
                          ? 'Warning: the current reading ($clean) is lower than the previous one (${widget.previousReading})!'
                          : 'Previous reading: ${widget.previousReading}  |  Consumption: $consumption units',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isLessThanPrevious
                            ? Colors.red.shade900
                            : Colors.green.shade900,
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

  Widget _buildDigitRoller({
    required int index,
    required int digit,
    required bool isUncertain,
  }) {
    final Color borderColor =
        isUncertain ? Colors.orange.shade700 : Colors.blue.shade700;
    final Color bgColor =
        isUncertain ? Colors.orange.shade50 : Colors.blue.shade50;

    return Container(
      width: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: isUncertain ? 2.0 : 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            onTap: () => _updateDigit(index, 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 26,
                color: borderColor,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: Text(
              digit.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isUncertain
                    ? Colors.orange.shade900
                    : Colors.blue.shade900,
              ),
            ),
          ),
          InkWell(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
            onTap: () => _updateDigit(index, -1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 26,
                color: borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // خانة فارغة إرشادية: تفتح لوحة المفاتيح عند النقر، ولا تُدرج أي رقم.
  Widget _buildDigitPlaceholder() {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        width: 54,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade400,
            width: 1.4,
          ),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// نافذة المراجعة والتأكيد المتكاملة بعد القص والقراءة
// ============================================================

enum OcrReviewAction {
  confirm,
  recrop,
  retake,
  cancel,
}

class OcrReviewOutcome {
  final OcrReviewAction action;
  final String? reading;

  const OcrReviewOutcome({
    required this.action,
    this.reading,
  });
}

class MeterOcrReviewDialog extends StatefulWidget {
  final Uint8List croppedImageBytes;
  final Uint8List? enhancedImageBytes;
  final ImageQualityReport qualityReport;
  final MeterAnalysisResult analysisResult;
  final int? previousReading;

  const MeterOcrReviewDialog({
    super.key,
    required this.croppedImageBytes,
    this.enhancedImageBytes,
    required this.qualityReport,
    required this.analysisResult,
    this.previousReading,
  });

  @override
  State<MeterOcrReviewDialog> createState() => _MeterOcrReviewDialogState();
}

class _MeterOcrReviewDialogState extends State<MeterOcrReviewDialog> {
  late String _currentReading;
  late int _digitCount;
  bool _showEnhanced = false;

  @override
  void initState() {
    super.initState();
    final String reading = widget.analysisResult.reading;
    if (MeterAnalyzer.isValid(reading)) {
      _currentReading = reading;
      _digitCount = reading.length;
    } else {
      // لا نخمّن رقمًا ولا نضيف أصفارًا: نترك الحقل فارغًا للمراجعة.
      _currentReading = '';
      _digitCount = MeterAnalyzer.maxDigits;
    }
  }

  bool get _canApprove =>
      MeterAnalyzer.isValid(_currentReading, expectedDigits: _digitCount);

  @override
  Widget build(BuildContext context) {
    final bool hasValidOcr = widget.analysisResult.isValid;
    final Uint8List displayBytes =
        (_showEnhanced && widget.enhancedImageBytes != null)
            ? widget.enhancedImageBytes!
            : widget.croppedImageBytes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // العنوان
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.document_scanner,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review the meter reading and photo quality',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.analysisResult.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: hasValidOcr
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasValidOcr)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.analysisResult.isHighConfidence
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Confidence ${widget.analysisResult.confidence.round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.analysisResult.isHighConfidence
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // صورة نافذة الأرقام المقصوصة (قابلة للتكبير لتسهيل القراءة اليدوية)
                ZoomableMeterPhoto(
                  bytes: displayBytes,
                  height: 200,
                  label: 'Meter digit window',
                ),

                if (widget.enhancedImageBytes != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showEnhanced = !_showEnhanced;
                        });
                      },
                      icon: Icon(
                        _showEnhanced
                            ? Icons.image
                            : Icons.auto_fix_high,
                        size: 16,
                      ),
                      label: Text(
                        _showEnhanced
                            ? 'Show the original photo'
                            : 'Show the enhanced (OCR) copy',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),

                // محرر خانات العداد (6 أو 7)
                MeterReadingEditor(
                  reading: _currentReading,
                  digitCount: _digitCount,
                  digitConfidences: widget.analysisResult.digitConfidences,
                  alternatives: widget.analysisResult.alternatives,
                  previousReading: widget.previousReading,
                  onChanged: (val) {
                    setState(() {
                      _currentReading = val;
                    });
                  },
                  onDigitCountChanged: (count) {
                    setState(() {
                      _digitCount = count;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // تقرير جودة الصورة
                ImageQualityCard(
                  report: widget.qualityReport,
                  compact: widget.qualityReport.overallScore >= 75,
                ),

                const SizedBox(height: 16),

                // أزرار الإجراءات
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _canApprove
                        ? () {
                            Navigator.of(context).pop(
                              OcrReviewOutcome(
                                action: OcrReviewAction.confirm,
                                reading: _currentReading,
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      _canApprove
                          ? 'Approve the reading ($_currentReading)'
                          : 'Enter the full $_digitCount-digit reading',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            const OcrReviewOutcome(
                              action: OcrReviewAction.recrop,
                            ),
                          );
                        },
                        icon: const Icon(Icons.crop, size: 18),
                        label: const Text('Crop again'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(
                            const OcrReviewOutcome(
                              action: OcrReviewAction.retake,
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Retake photo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
