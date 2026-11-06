// ============================================================
// ocr_web.dart
// صفحة قراءة عداد المياه للويب مع فحص جودة الصورة ومراجعة خانات العداد (6 أو 7)
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
  int _digitCount = MeterAnalyzer.maxDigits;
  String _rawText = '';

  ImageQualityReport? _qualityReport;
  MeterAnalysisResult? _analysisResult;

  bool _isCropping = false;
  bool _isRecognizing = false;

  String _status = 'Choose or photograph the water meter to start';

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
        _showMessage('The selected file is not an image');
        return;
      }

      try {
        setState(() {
          _status = 'Loading the image…';
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
              Exception('Could not read the image'),
            );
          }
        });

        reader.onError.listen((_) {
          completer.completeError(
            Exception('Something went wrong while reading the image'),
          );
        });

        reader.readAsDataUrl(file);

        final dataUrl = await completer.future;

        if (!mounted) return;

        setState(() {
          _imageData = dataUrl;
          _status = 'Select the 6 or 7 digit area';
        });

        // فتح القص تلقائياً بعد اختيار الصورة
        await _openCropper();
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _status = 'Could not load the image';
        });

        _showMessage('Image load error: $e');
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
      _showMessage('Choose an image first');
      return;
    }

    try {
      setState(() {
        _isCropping = true;
        _status = 'Select the meter window (6 or 7 digits)';
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
          _status = 'Area selection cancelled';
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
        _status = 'Area selected and quality checked. Reading the digits…';
      });

      // بدء القراءة تلقائياً بعد تأكيد القص
      await _recognizeMeter();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCropping = false;
        _status = 'Cropping was cancelled or failed';
      });
    }
  }

  // ------------------------------------------------------------
  // تشغيل OCR وتحليل النتائج
  // ------------------------------------------------------------

  Future<void> _recognizeMeter() async {
    if (_croppedImageData == null || _croppedImageData!.isEmpty) {
      _showMessage('Select the meter window first');
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
        _status = 'Reading the meter digits and checking all 6 or 7…';
      });

      await _callJsPromise(
        'recognizeMeterDigits',
        <dynamic>[_croppedImageData!],
      );

      if (!mounted) return;

      final String jsReading = _getJsString('getLastMeterOCRReading');
      final String rawText = _getJsString('getLastMeterOCRText');
      final String jsMethod = _getJsString('getLastMeterOCRMethod');
      final List<double> jsDigitConfidences = _getJsDigitConfidences();

      final String cleanJsReading = MeterAnalyzer.normalize(jsReading);

      final MeterAnalysisResult analysis;
      if (jsMethod == 'cells' && MeterAnalyzer.isValid(cleanJsReading)) {
        // قراءة خانة-ب-خانة: نثق بالنتيجة المنظمة مباشرة مع ثقة كل خانة،
        // ولا نعيد اشتقاقها من نص خام قد يعيد تقديم أرقام مخترعة.
        final double conf = jsDigitConfidences.isNotEmpty
            ? jsDigitConfidences.reduce((a, b) => a + b) /
                jsDigitConfidences.length
            : 80.0;
        analysis = MeterAnalysisResult(
          reading: cleanJsReading,
          confidence: conf.clamp(0.0, 99.0),
          occurrences: 1,
          totalAttempts: 1,
          isValid: true,
          message:
              'The ${cleanJsReading.length}-digit reading was recognised drum by drum.',
          digitConfidences: jsDigitConfidences,
        );
      } else {
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
              source: 'js-line',
            ),
          );
        }

        analysis = MeterAnalyzer.analyze(
          rawParts,
          previousReading: widget.previousReading,
          weightedCandidates: weighted,
        );
      }

      String finalReading = '';
      if (analysis.isValid) {
        finalReading = analysis.reading;
      } else if (MeterAnalyzer.isValid(cleanJsReading)) {
        finalReading = cleanJsReading;
      }

      setState(() {
        _isRecognizing = false;
        _reading = finalReading;
        _digitCount = finalReading.isNotEmpty
            ? finalReading.length
            : MeterAnalyzer.maxDigits;
        _rawText = rawText;
        _analysisResult = analysis;

        if (finalReading.isNotEmpty) {
          _status = analysis.isValid
              ? analysis.message
              : 'A candidate reading was found — review it against the photo.';
        } else {
          _status =
              'The 6 or 7 digits could not be read clearly — enter them below or crop again.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecognizing = false;
        _status = 'Automatic digit recognition failed';
      });

      _showMessage('OCR error: $e');
    }
  }

  // ------------------------------------------------------------
  // اعتماد القراءة وإرجاعها للشاشة السابقة
  // ------------------------------------------------------------

  void _confirmAndReturn() {
    final String clean = MeterAnalyzer.normalize(_reading);
    if (!MeterAnalyzer.isValid(clean, expectedDigits: _digitCount)) {
      _showMessage('The reading must be exactly $_digitCount digits');
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
  // قراءة ثقة كل خانة من JavaScript (مصفوفة أرقام)
  // ------------------------------------------------------------

  List<double> _getJsDigitConfidences() {
    try {
      final result = js_util.callMethod<dynamic>(
        html.window,
        'getLastMeterOCRDigitConfidences',
        <dynamic>[],
      );

      if (result == null) {
        return const <double>[];
      }

      final dynamic dartified = js_util.dartify(result);
      if (dartified is List) {
        return dartified.map((dynamic e) {
          if (e is num) {
            return e.toDouble();
          }
          return double.tryParse(e.toString()) ?? 0.0;
        }).toList();
      }

      return const <double>[];
    } catch (_) {
      return const <double>[];
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
      _status = 'Choose or photograph the water meter to start';
      _digitCount = MeterAnalyzer.maxDigits;
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
              Text('Water meter reading with quality check'),
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
                    if (_analysisResult != null || _reading.isNotEmpty) ...[
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
              'Electronic reading of the water meter (6 or 7 digits)',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Photograph or pick the meter, then select the 6 or 7 integer digit window so the photo is checked and the reading extracted automatically.',
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
              'No image selected yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Keep the meter glass clean and avoid direct flash',
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
                      ? 'Selected digit area (OCR)'
                      : 'Original photo',
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
          label: const Text('Take a photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: busy ? null : () => _pickImage(useCamera: false),
          icon: const Icon(Icons.upload_file),
          label: Text(
            _imageData == null ? 'Pick an image from the device' : 'Change the image',
          ),
        ),
        if (_imageData != null)
          OutlinedButton.icon(
            onPressed: busy ? null : _openCropper,
            icon: const Icon(Icons.crop),
            label: const Text('Crop the digit area again'),
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
              _isRecognizing ? 'Reading…' : 'Read the digits again',
            ),
          ),
        if (_imageData != null)
          TextButton.icon(
            onPressed: busy ? null : _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
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
                  'Extracted meter reading',
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
                      'Confidence ${_analysisResult!.confidence.round()}%',
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
            MeterReadingEditor(
              reading: _reading,
              digitCount: _digitCount,
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
              onDigitCountChanged: (count) {
                setState(() {
                  _digitCount = count;
                });
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: MeterAnalyzer.isValid(
                  _reading,
                  expectedDigits: _digitCount,
                )
                    ? _confirmAndReturn
                    : null,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  MeterAnalyzer.isValid(_reading, expectedDigits: _digitCount)
                      ? 'Approve the reading ($_reading)'
                      : 'Enter the full $_digitCount-digit reading',
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
                title: const Text('Raw OCR text'),
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
