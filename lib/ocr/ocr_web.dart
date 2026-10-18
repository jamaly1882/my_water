// ============================================================
// ocr_web.dart
// صفحة قراءة عداد المياه للويب مع فحص جودة الصورة ومراجعة الخانات السبع
// ============================================================

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';
import 'ocr_quality_widgets.dart';

class OcrWebPage extends StatefulWidget {
  final int? previousReading;

  const OcrWebPage({
    super.key,
    this.previousReading,
  });

  @override
  State<OcrWebPage> createState() => _OcrWebPageState();
}

class _OcrWebPageState extends State<OcrWebPage> {
  String? _imageData;
  String? _croppedImageData;

  String _reading = '';
  String _rawText = '';

  ImageQualityReport? _qualityReport;
  MeterAnalysisResult? _analysisResult;

  bool _isCropping = false;
  bool _isRecognizing = false;

  String _status = 'اختر أو صوّر عداد الماء للبدء';

  html.FileUploadInputElement? _fileInput;

  @override
  void dispose() {
    _fileInput?.remove();
    super.dispose();
  }

  // ------------------------------------------------------------
  // اختيار أو تصوير الصورة
  // ------------------------------------------------------------

  Future<void> _pickImage({bool useCamera = false}) async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

    if (useCamera) {
      input.setAttribute('capture', 'environment');
    }

    _fileInput?.remove();
    _fileInput = input;

    input.onChange.listen((_) async {
      final files = input.files;

      if (files == null || files.isEmpty) {
        return;
      }

      final file = files.first;

      if (!file.type.startsWith('image/')) {
        _showMessage('الملف المختار ليس صورة');
        return;
      }

      try {
        setState(() {
          _status = 'جاري تحميل الصورة...';
          _reading = '';
          _rawText = '';
          _croppedImageData = null;
          _qualityReport = null;
          _analysisResult = null;
        });

        final reader = html.FileReader();
        final completer = Completer<String>();

        reader.onLoad.listen((_) {
          final result = reader.result;

          if (result is String) {
            completer.complete(result);
          } else {
            completer.completeError(
              Exception('تعذر قراءة الصورة'),
            );
          }
        });

        reader.onError.listen((_) {
          completer.completeError(
            Exception('حدث خطأ أثناء قراءة الصورة'),
          );
        });

        reader.readAsDataUrl(file);

        final dataUrl = await completer.future;

        if (!mounted) return;

        setState(() {
          _imageData = dataUrl;
          _status = 'حدد منطقة أرقام العداد السبعة';
        });

        // فتح القص تلقائياً بعد اختيار الصورة
        await _openCropper();
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _status = 'فشل تحميل الصورة';
        });

        _showMessage('خطأ في تحميل الصورة: $e');
      }
    });

    html.document.body?.append(input);
    input.click();
  }

  // ------------------------------------------------------------
  // فتح واجهة القص الموجودة في index.html
  // ------------------------------------------------------------

  Future<void> _openCropper() async {
    if (_imageData == null || _imageData!.isEmpty) {
      _showMessage('اختر صورة أولاً');
      return;
    }

    try {
      setState(() {
        _isCropping = true;
        _status = 'حدد منطقة شاشة العداد (7 أرقام)';
      });

      final result = await _callJsPromise(
        'cropMeterImage',
        <dynamic>[_imageData!],
      );

      if (!mounted) return;

      final cropped = result?.toString() ?? '';

      if (cropped.isEmpty || cropped == 'null') {
        setState(() {
          _isCropping = false;
          _status = 'تم إلغاء تحديد المنطقة';
        });
        return;
      }

      // فحص جودة الصورة المقصوصة مباشرة
      final Uint8List croppedBytes = _dataUrlToBytes(cropped);
      final ImageQualityReport? report = croppedBytes.isNotEmpty
          ? ImageQualityAnalyzer.analyzeBytes(croppedBytes)
          : null;

      setState(() {
        _croppedImageData = cropped;
        _qualityReport = report;
        _isCropping = false;
        _status = 'تم تحديد المنطقة وفحص الجودة. جاري قراءة الأرقام...';
      });

      // بدء القراءة تلقائياً بعد تأكيد القص
      await _recognizeMeter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCropping = false;
        _status = 'تم إلغاء القص أو حدث خطأ أثناء تحديد المنطقة';
      });
    }
  }

  // ------------------------------------------------------------
  // تشغيل OCR وتحليل النتائج
  // ------------------------------------------------------------

  Future<void> _recognizeMeter() async {
    if (_croppedImageData == null || _croppedImageData!.isEmpty) {
      _showMessage('حدد منطقة شاشة العداد أولاً');
      return;
    }

    if (_isRecognizing) {
      return;
    }

    try {
      setState(() {
        _isRecognizing = true;
        _reading = '';
        _rawText = '';
        _status = 'جاري قراءة أرقام العداد وتحليل الخانات السبع...';
      });

      await _callJsPromise(
        'recognizeMeterDigits',
        <dynamic>[_croppedImageData!],
      );

      if (!mounted) return;

      final String jsReading = _getJsString('getLastMeterOCRReading');
      final String rawText = _getJsString('getLastMeterOCRText');

      final List<String> rawParts = rawText
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final List<WeightedOcrCandidate> weighted = <WeightedOcrCandidate>[];
      if (jsReading.trim().isNotEmpty) {
        weighted.add(
          WeightedOcrCandidate(
            text: jsReading.trim(),
            weight: 2.5,
            source: 'js-solver',
          ),
        );
      }

      final MeterAnalysisResult analysis = MeterAnalyzer.analyze(
        rawParts,
        previousReading: widget.previousReading,
        weightedCandidates: weighted,
      );

      String finalReading = '';
      if (analysis.isValid) {
        finalReading = analysis.reading;
      } else if (MeterAnalyzer.isValid(MeterAnalyzer.normalize(jsReading))) {
        finalReading = MeterAnalyzer.normalize(jsReading);
      } else if (analysis.partialReading.isNotEmpty) {
        finalReading = analysis.partialReading.padLeft(7, '0');
      } else {
        finalReading = '0000000';
      }

      setState(() {
        _isRecognizing = false;
        _reading = finalReading;
        _rawText = rawText;
        _analysisResult = analysis;

        if (analysis.isValid) {
          _status = analysis.message;
        } else {
          _status =
              'تعذر قراءة الخانات السبع تلقائياً بوضوح؛ يمكنك ضبط الخانات أدناه أو إعادة القص.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecognizing = false;
        _status = 'فشل التعرف التلقائي على الأرقام';
      });

      _showMessage('خطأ OCR: $e');
    }
  }

  // ------------------------------------------------------------
  // اعتماد القراءة وإرجاعها للشاشة السابقة
  // ------------------------------------------------------------

  void _confirmAndReturn() {
    final String clean = MeterAnalyzer.normalize(_reading);
    if (!MeterAnalyzer.isValid(clean)) {
      _showMessage('القراءة يجب أن تتكون من 7 خانات بالضبط');
      return;
    }
    Navigator.of(context).pop(clean);
  }

  // ------------------------------------------------------------
  // استدعاء Promise من JavaScript
  // ------------------------------------------------------------

  Future<dynamic> _callJsPromise(
    String functionName,
    List<dynamic> args,
  ) async {
    final result = js_util.callMethod<dynamic>(
      html.window,
      functionName,
      args,
    );

    return js_util.promiseToFuture<dynamic>(result);
  }

  // ------------------------------------------------------------
  // قراءة قيمة من JavaScript
  // ------------------------------------------------------------

  String _getJsString(String functionName) {
    try {
      final result = js_util.callMethod<dynamic>(
        html.window,
        functionName,
        <dynamic>[],
      );

      if (result == null) {
        return '';
      }

      return result.toString();
    } catch (_) {
      return '';
    }
  }

  // ------------------------------------------------------------
  // تحويل Data URL إلى Uint8List
  // ------------------------------------------------------------

  Uint8List _dataUrlToBytes(String dataUrl) {
    try {
      final int comma = dataUrl.indexOf(',');
      if (comma < 0) {
        return Uint8List(0);
      }

      final String encoded = dataUrl.substring(comma + 1);
      final String binary = html.window.atob(encoded);

      return Uint8List.fromList(
        List<int>.generate(
          binary.length,
          (index) => binary.codeUnitAt(index),
        ),
      );
    } catch (_) {
      return Uint8List(0);
    }
  }

  // ------------------------------------------------------------
  // رسالة
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // إعادة البداية
  // ------------------------------------------------------------

  void _reset() {
    setState(() {
      _imageData = null;
      _croppedImageData = null;
      _reading = '';
      _rawText = '';
      _qualityReport = null;
      _analysisResult = null;
      _isCropping = false;
      _isRecognizing = false;
      _status = 'اختر أو صوّر عداد الماء للبدء';
    });
  }

  // ------------------------------------------------------------
  // الواجهة
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water),
              SizedBox(width: 8),
              Text('قراءة عداد الماء وفحص الجودة'),
            ],
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildImageArea(),
                    const SizedBox(height: 16),
                    _buildControls(),
                    if (_qualityReport != null) ...[
                      const SizedBox(height: 18),
                      ImageQualityCard(report: _qualityReport!),
                    ],
                    if (_reading.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildResult(),
                    ],
                    const SizedBox(height: 16),
                    _buildStatus(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.document_scanner,
              size: 46,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            const Text(
              'التعرف الإلكتروني على قراءة عداد الماء (7 خانات)',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'صوّر أو اختر صورة العداد، ثم حدد شاشة الأرقام السبعة ليتم فحص جودة الصورة واستخراج القراءة تلقائياً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    if (_imageData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.blueGrey,
            ),
            SizedBox(height: 10),
            Text(
              'لم يتم اختيار صورة بعد',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'احرص على نظافة زجاج العداد وتجنب انعكاس الفلاش المباشر',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final Uint8List bytes = _dataUrlToBytes(
      _croppedImageData ?? _imageData!,
    );

    if (bytes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _croppedImageData != null ? Icons.crop : Icons.image,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _croppedImageData != null
                      ? 'منطقة الأرقام المحددة (OCR)'
                      : 'الصورة الأصلية',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final bool busy = _isRecognizing || _isCropping;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: busy ? null : () => _pickImage(useCamera: true),
          icon: const Icon(Icons.camera_alt),
          label: const Text('تصوير بالكاميرا'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: busy ? null : () => _pickImage(useCamera: false),
          icon: const Icon(Icons.upload_file),
          label: Text(
            _imageData == null ? 'اختيار صورة من الجهاز' : 'تغيير الصورة',
          ),
        ),
        if (_imageData != null)
          OutlinedButton.icon(
            onPressed: busy ? null : _openCropper,
            icon: const Icon(Icons.crop),
            label: const Text('إعادة قص منطقة الأرقام'),
          ),
        if (_croppedImageData != null)
          FilledButton.icon(
            onPressed: busy ? null : _recognizeMeter,
            icon: _isRecognizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.document_scanner),
            label: Text(
              _isRecognizing ? 'جاري القراءة...' : 'إعادة قراءة الأرقام',
            ),
          ),
        if (_imageData != null)
          TextButton.icon(
            onPressed: busy ? null : _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('مسح وإعادة'),
          ),
      ],
    );
  }

  Widget _buildResult() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _analysisResult?.isValid == true
                      ? Icons.check_circle
                      : Icons.edit_note,
                  color: _analysisResult?.isValid == true
                      ? Colors.green
                      : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'قراءة العداد المستخرجة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_analysisResult != null && _analysisResult!.isValid) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _analysisResult!.isHighConfidence
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ثقة ${_analysisResult!.confidence.round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _analysisResult!.isHighConfidence
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            SevenDigitRollerEditor(
              reading: _reading,
              digitConfidences:
                  _analysisResult?.digitConfidences ?? const <double>[],
              alternatives:
                  _analysisResult?.alternatives ?? const <String>[],
              previousReading: widget.previousReading,
              onChanged: (val) {
                setState(() {
                  _reading = val;
                });
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmAndReturn,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  'اعتماد القراءة ($_reading)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (_rawText.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('النص الخام من محرك OCR'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _rawText,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        _status,
        key: ValueKey(_status),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _isRecognizing
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade800,
        ),
      ),
    );
  }
}
