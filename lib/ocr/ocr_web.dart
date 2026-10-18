import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:flutter/material.dart';

class OcrWebPage extends StatefulWidget {
  const OcrWebPage({super.key});

  @override
  State<OcrWebPage> createState() => _OcrWebPageState();
}

class _OcrWebPageState extends State<OcrWebPage> {
  String? _imageData;
  String? _croppedImageData;

  String _reading = '';
  String _rawText = '';

  bool _isCropping = false;
  bool _isRecognizing = false;

  String _status = 'اختر صورة عداد الماء';

  html.FileUploadInputElement? _fileInput;

  @override
  void dispose() {
    _fileInput?.remove();
    super.dispose();
  }

  // ------------------------------------------------------------
  // اختيار الصورة
  // ------------------------------------------------------------

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;

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
          _status = 'حدد منطقة أرقام العداد';
        });

        // فتح القص تلقائياً بعد اختيار الصورة.
        await _openCropper();
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _status = 'فشل تحميل الصورة';
        });

        _showMessage('خطأ في تحميل الصورة: $e');
      }
    });

    // إضافة العنصر مؤقتاً إلى الصفحة.
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
        _status = 'حدد منطقة شاشة العداد';
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

      setState(() {
        _croppedImageData = cropped;
        _isCropping = false;
        _status = 'تم تحديد المنطقة. اضغط قراءة العداد';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCropping = false;
        _status = 'حدث خطأ أثناء تحديد المنطقة';
      });

      _showMessage('خطأ في القص: $e');
    }
  }

  // ------------------------------------------------------------
  // تشغيل OCR
  // ------------------------------------------------------------

  Future<void> _recognizeMeter() async {
    if (_croppedImageData == null ||
        _croppedImageData!.isEmpty) {
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
        _status = 'جاري قراءة أرقام العداد...';
      });

      await _callJsPromise(
        'recognizeMeterDigits',
        <dynamic>[_croppedImageData!],
      );

      if (!mounted) return;

      final reading = _getJsString(
        'getLastMeterOCRReading',
      );

      final rawText = _getJsString(
        'getLastMeterOCRText',
      );

      setState(() {
        _isRecognizing = false;
        _reading = _normalizeDigits(reading);
        _rawText = rawText;

        if (_reading.isNotEmpty) {
          _status = 'تم التعرف على قراءة العداد';
        } else {
          _status =
              'لم يتم التعرف على القراءة بوضوح. حاول تحديد الشاشة بدقة أكبر';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isRecognizing = false;
        _status = 'فشل التعرف على الأرقام';
      });

      _showMessage('خطأ OCR: $e');
    }
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
      final comma = dataUrl.indexOf(',');

      if (comma < 0) {
        return Uint8List(0);
      }

      final encoded = dataUrl.substring(comma + 1);

      final binary = html.window.atob(encoded);

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
  // تطبيع الأرقام العربية والفارسية إلى الإنجليزية
  // ------------------------------------------------------------

  String _normalizeDigits(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'[٠-٩]'),
          (match) {
            final char = match.group(0)!;
            final code = char.codeUnitAt(0);

            final normalized =
                code - '٠'.codeUnitAt(0);

            return normalized.toString();
          },
        )
        .replaceAllMapped(
          RegExp(r'[۰-۹]'),
          (match) {
            final char = match.group(0)!;
            final code = char.codeUnitAt(0);

            final normalized =
                code - '۰'.codeUnitAt(0);

            return normalized.toString();
          },
        );
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
      _isCropping = false;
      _isRecognizing = false;
      _status = 'اختر صورة عداد الماء';
    });
  }

  // ------------------------------------------------------------
  // الواجهة
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water),
            SizedBox(width: 8),
            Text('قراءة عداد الماء'),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildImageArea(),
                  const SizedBox(height: 20),
                  _buildControls(),
                  const SizedBox(height: 24),
                  _buildResult(),
                  const SizedBox(height: 16),
                  _buildStatus(),
                ],
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.water,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'التعرف على قراءة عداد الماء',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'اختر صورة العداد، ثم حدد شاشة الأرقام وسيتم استخراج القراءة تلقائياً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
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
        height: 260,
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
              size: 70,
            ),
            SizedBox(height: 12),
            Text(
              'لم يتم اختيار صورة',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    final bytes = _dataUrlToBytes(
      _croppedImageData ?? _imageData!,
    );

    if (bytes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _croppedImageData != null
                      ? Icons.crop
                      : Icons.image,
                ),
                const SizedBox(width: 8),
                Text(
                  _croppedImageData != null
                      ? 'منطقة OCR المحددة'
                      : 'الصورة الأصلية',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 450,
            ),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isRecognizing || _isCropping
              ? null
              : _pickImage,
          icon: const Icon(Icons.upload_file),
          label: Text(
            _imageData == null
                ? 'اختيار صورة'
                : 'اختيار صورة أخرى',
          ),
        ),

        if (_imageData != null)
          OutlinedButton.icon(
            onPressed:
                _isRecognizing || _isCropping
                    ? null
                    : _openCropper,
            icon: const Icon(Icons.crop),
            label: const Text(
              'تحديد منطقة العداد',
            ),
          ),

        if (_croppedImageData != null)
          FilledButton.icon(
            onPressed:
                _isRecognizing || _isCropping
                    ? null
                    : _recognizeMeter,
            icon: _isRecognizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.document_scanner),
            label: Text(
              _isRecognizing
                  ? 'جاري القراءة...'
                  : 'قراءة العداد',
            ),
          ),

        if (_imageData != null)
          TextButton.icon(
            onPressed:
                _isRecognizing || _isCropping
                    ? null
                    : _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة'),
          ),
      ],
    );
  }

  Widget _buildResult() {
    if (_reading.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 50,
            ),
            const SizedBox(height: 12),
            const Text(
              'قراءة العداد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              _reading,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
            if (_rawText.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text(
                  'النص الخام من OCR',
                ),
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
          color: _isRecognizing
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade700,
        ),
      ),
    );
  }
}