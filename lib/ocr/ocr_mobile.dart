
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// ============================================================
/// قراءة عداد المياه - استخراج 7 أرقام
/// مثال: 0650040
/// ============================================================

Future<String?> readNumberImpl() async {
  final ImagePicker picker = ImagePicker();

  try {
    // استرجاع الصورة المفقودة عند إعادة تشغيل Android
    final LostDataResponse lostData =
        await picker.retrieveLostData();

    if (!lostData.isEmpty) {
      final files = lostData.files;

      if (files != null && files.isNotEmpty) {
        final file = File(files.first.path);

        if (await file.exists() && await file.length() > 0) {
          return await _cropAndRead(file);
        }
      }
    }
  } catch (e) {
    debugPrint('استرجاع الصورة: $e');
  }

  // فتح الكاميرا
  final XFile? picked = await picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 100,
    maxWidth: 4000,
    maxHeight: 4000,
  );

  if (picked == null) return null;

  final file = File(picked.path);

  if (!await file.exists() || await file.length() == 0) {
    throw Exception('تعذر الوصول إلى صورة العداد.');
  }

  return _cropAndRead(file);
}

/// ============================================================
/// قص نافذة الأرقام فقط
/// ============================================================

Future<String?> _cropAndRead(File imageFile) async {
  final CroppedFile? cropped = await ImageCropper().cropImage(
    sourcePath: imageFile.path,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 100,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'حدد الأرقام السبعة فقط',
        toolbarColor: const Color(0xFF1565C0),
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: false,
        showCropGrid: true,
        backgroundColor: Colors.black,
      ),
      IOSUiSettings(
        title: 'حدد الأرقام السبعة فقط',
        aspectRatioLockEnabled: false,
      ),
    ],
  );

  if (cropped == null) return null;

  final file = File(cropped.path);

  if (!await file.exists() || await file.length() == 0) {
    throw Exception('الصورة المقصوصة غير صالحة.');
  }

  return _runOCR(file);
}

/// ============================================================
/// تشغيل OCR على الصورة الأصلية والنسخ المحسنة
/// ============================================================

Future<String?> _runOCR(File croppedFile) async {
  final recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  try {
    final List<File> variants =
        await _createImageVariants(croppedFile);

    final Map<String, int> candidateCounts = {};

    for (int i = 0; i < variants.length; i++) {
      try {
        final input = InputImage.fromFilePath(
          variants[i].path,
        );

        final RecognizedText recognized =
            await recognizer.processImage(input);

        debugPrint(
          'OCR النسخة ${i + 1}: ${recognized.text}',
        );

        // استخراج مرشح من كل سطر، مع الحفاظ على ترتيب النص
        for (final block in recognized.blocks) {
          for (final line in block.lines) {
            final candidate =
                _extractSevenDigits(line.text);

            if (candidate != null) {
              candidateCounts[candidate] =
                  (candidateCounts[candidate] ?? 0) + 1;
            }
          }
        }

        // محاولة إضافية من النص الكامل إذا كانت الأرقام
        // السبعة موجودة متجاورة في النص.
        final fullCandidate =
            _extractSevenDigits(recognized.text);

        if (fullCandidate != null) {
          candidateCounts[fullCandidate] =
              (candidateCounts[fullCandidate] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('خطأ OCR في النسخة ${i + 1}: $e');
      }
    }

    if (candidateCounts.isEmpty) {
      throw Exception(
        'لم نتمكن من استخراج الأرقام السبعة. '
        'أعد التصوير بإضاءة جيدة، ثم قص نافذة الأرقام فقط.',
      );
    }

    // لا نختار مرشحاً مختلفاً لمجرد أنه حصل على نقاط شكلية.
    // نطلب نتيجة متفقاً عليها بين أكثر من محاولة إن أمكن.
    final entries = candidateCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final best = entries.first;

    if (entries.length > 1 &&
        entries[1].value == best.value) {
      throw Exception(
        'نتائج القراءة غير متطابقة: '
        '${entries[0].key} و${entries[1].key}. '
        'أعد تصوير العداد للتحقق من القراءة.',
      );
    }

    debugPrint('قراءة العداد المقترحة: ${best.key}');
    debugPrint('عدد مرات ظهورها: ${best.value}');

    return best.key;
  } finally {
    await recognizer.close();
  }
}

/// ============================================================
/// استخراج سبعة أرقام دون فقدان الصفر الأول
/// ============================================================

String? _extractSevenDigits(String text) {
  final normalized = _normalizeText(text);

  // الحالة الأولى: سبعة أرقام متجاورة
  final directMatches =
      RegExp(r'(?<!\d)\d{7}(?!\d)')
          .allMatches(normalized)
          .toList();

  if (directMatches.length == 1) {
    return directMatches.first.group(0);
  }

  // إذا وجدنا أكثر من قراءة محتملة في السطر، لا نخمن.
  if (directMatches.length > 1) {
    return null;
  }

  // الحالة الثانية: OCR فصل الأرقام بمسافات أو علامات.
  // نسمح بالفواصل بين الخانات فقط، ولا ندمج النص كله عشوائياً.
  final separated = RegExp(
    r'(?<!\d)(\d(?:[\s.,:;|_-]*\d){6})(?!\d)',
  ).allMatches(normalized).toList();

  if (separated.length == 1) {
    final digits = separated.first
        .group(1)!
        .replaceAll(RegExp(r'\D'), '');

    if (digits.length == 7) return digits;
  }

  return null;
}

/// ============================================================
/// تصحيح الحروف التي يشبه شكلها الأرقام
/// ============================================================

String _normalizeText(String text) {
  return text
      .replaceAll('O', '0')
      .replaceAll('o', '0')
      .replaceAll('D', '0')
      .replaceAll('Q', '0')
      .replaceAll('I', '1')
      .replaceAll('l', '1')
      .replaceAll('|', '1')
      .replaceAll('!', '1')
      .replaceAll('S', '5')
      .replaceAll('s', '5')
      .replaceAll('B', '8')
      .replaceAll('b', '6')
      .replaceAll('G', '6')
      .replaceAll('Z', '2')
      .replaceAll('z', '2');
}

/// ============================================================
/// إنشاء نسخ محسنة للصورة
/// ============================================================

Future<List<File>> _createImageVariants(File original) async {
  final List<File> result = [original];

  try {
    final Uint8List bytes = await original.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);

    if (decoded == null) {
      debugPrint('تعذر فك الصورة؛ سيتم استخدام الأصل فقط.');
      return result;
    }

    final img.Image oriented = img.bakeOrientation(decoded);

    img.Image working = oriented;

    // التكبير مفيد عندما تكون نافذة الأرقام صغيرة.
    if (working.width < 1200) {
      working = img.copyResize(
        working,
        width: 1200,
        interpolation: img.Interpolation.linear,
      );
    }

    // نسخة محسنة بتباين متوسط
    final img.Image contrast = img.adjustColor(
      working,
      contrast: 1.4,
      brightness: 1.02,
    );

    result.add(
      await _saveVariant(
        contrast,
        original.path,
        'contrast',
      ),
    );

    // نسخة رمادية مع تحسين التباين
    final img.Image gray = img.grayscale(working);

    final img.Image grayContrast = img.adjustColor(
      gray,
      contrast: 1.6,
      brightness: 1.02,
    );

    result.add(
      await _saveVariant(
        grayContrast,
        original.path,
        'gray',
      ),
    );
  } catch (e) {
    debugPrint('تعذر تجهيز نسخ الصورة: $e');
  }

  return result;
}

/// ============================================================
/// حفظ نسخة الصورة
/// ============================================================

Future<File> _saveVariant(
  img.Image image,
  String originalPath,
  String suffix,
) async {
  final directory = File(originalPath).parent.path;

  final path =
      '$directory/ocr_${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg';

  final encoded = Uint8List.fromList(
    img.encodeJpg(image, quality: 95),
  );

  final file = File(path);

  await file.writeAsBytes(encoded, flush: true);

  return file;
}
