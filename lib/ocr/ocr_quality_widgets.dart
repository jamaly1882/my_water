// ============================================================
// ocr_quality_widgets.dart
// مكونات واجهة فحص جودة الصورة ومراجعة الخانات السبع لقراءة العداد
// تعمل على جميع المنصات (Mobile / Web)
// ============================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';

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
                    'جودة صورة العداد: ${report.levelText}',
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
                    label: 'الوضوح والحدة',
                    score: report.sharpnessScore,
                    icon: Icons.center_focus_strong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricBar(
                    label: 'الإضاءة',
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
                    label: 'التباين',
                    score: report.contrastScore,
                    icon: Icons.contrast,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricBar(
                    label: 'عدم الوهج',
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
                      'نصائح لتحسين القراءة:',
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
// محرر ومراجع الخانات السبع التفاعلي (مثل بكرات العداد)
// ============================================================

class SevenDigitRollerEditor extends StatelessWidget {
  final String reading;
  final List<double> digitConfidences;
  final List<String> alternatives;
  final int? previousReading;
  final ValueChanged<String> onChanged;

  const SevenDigitRollerEditor({
    super.key,
    required this.reading,
    this.digitConfidences = const <double>[],
    this.alternatives = const <String>[],
    this.previousReading,
    required this.onChanged,
  });

  List<int> _getDigits() {
    final String clean = reading.replaceAll(RegExp(r'\D'), '');
    final String padded = clean.padLeft(7, '0');
    final String seven =
        padded.length > 7 ? padded.substring(padded.length - 7) : padded;

    return List<int>.generate(
      7,
      (i) => int.tryParse(seven[i]) ?? 0,
    );
  }

  void _updateDigit(int index, int delta) {
    final List<int> digits = _getDigits();
    digits[index] = (digits[index] + delta + 10) % 10;
    onChanged(digits.join());
  }

  @override
  Widget build(BuildContext context) {
    final List<int> digits = _getDigits();
    final String currentStr = digits.join();
    final int? currentInt = int.tryParse(currentStr);

    final bool hasPrevious = previousReading != null && previousReading! >= 0;
    final bool isLessThanPrevious = hasPrevious &&
        currentInt != null &&
        currentInt < previousReading!;
    final int? consumption = hasPrevious && currentInt != null && !isLessThanPrevious
        ? currentInt - previousReading!
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          const Text(
            'تحقق من تطابق الخانات السبع مع الصورة (يمكنك تعديل أي خانة بالأسهم):',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // شريط الخانات السبع من اليسار إلى اليمين كما في العداد الحقيقي
          Directionality(
            textDirection: TextDirection.ltr,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(7, (index) {
                  final double conf = index < digitConfidences.length
                      ? digitConfidences[index]
                      : 90.0;
                  final bool isUncertain = conf < 72.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildDigitRoller(
                      index: index,
                      digit: digits[index],
                      isUncertain: isUncertain,
                    ),
                  );
                }),
              ),
            ),
          ),

          // تنبيه إذا كانت إحدى الخانات غير مؤكدة
          if (digitConfidences.any((c) => c < 72.0)) ...[
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
                    'الخانات الملونة بالبرتقالي أقل وضوحاً في الصورة، تأكد من مطابقتها.',
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

          // القراءات البديلة المقترحة إن وجدت
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'قراءات محتملة أخرى:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...alternatives.map(
                  (alt) => ActionChip(
                    label: Text(
                      alt,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    onPressed: () => onChanged(alt),
                  ),
                ),
              ],
            ),
          ],

          // مقارنة مع القراءة السابقة إن وجدت
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
                          ? 'تنبيه: القراءة الحالية ($currentStr) أقل من القراءة السابقة ($previousReading)!'
                          : 'القراءة السابقة: $previousReading  |  الاستهلاك: $consumption وحدة',
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
      width: 44,
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.keyboard_arrow_up,
                size: 22,
                color: borderColor,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.white,
            child: Text(
              digit.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 22,
                color: borderColor,
              ),
            ),
          ),
        ],
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
  bool _showEnhanced = false;

  @override
  void initState() {
    super.initState();
    if (widget.analysisResult.reading.length == 7) {
      _currentReading = widget.analysisResult.reading;
    } else if (widget.analysisResult.partialReading.isNotEmpty) {
      _currentReading =
          widget.analysisResult.partialReading.padLeft(7, '0');
    } else {
      _currentReading = '0000000';
    }
  }

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
                            'مراجعة قراءة العداد وجودة الصورة',
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
                          'ثقة ${widget.analysisResult.confidence.round()}%',
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

                // صورة نافذة الأرقام المقصوصة
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxHeight: 150,
                      minHeight: 80,
                    ),
                    color: Colors.black87,
                    child: Image.memory(
                      displayBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
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
                            ? 'عرض الصورة الأصلية'
                            : 'عرض نسخة التحسين (OCR)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 10),

                // محرر الخانات السبع
                SevenDigitRollerEditor(
                  reading: _currentReading,
                  digitConfidences: widget.analysisResult.digitConfidences,
                  alternatives: widget.analysisResult.alternatives,
                  previousReading: widget.previousReading,
                  onChanged: (val) {
                    setState(() {
                      _currentReading = val;
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
                    onPressed: () {
                      Navigator.of(context).pop(
                        OcrReviewOutcome(
                          action: OcrReviewAction.confirm,
                          reading: _currentReading,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      'اعتماد القراءة ($_currentReading)',
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
                        label: const Text('إعادة القص'),
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
                        label: const Text('إعادة التصوير'),
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
