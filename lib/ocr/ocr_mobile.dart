// ============================================================
// ocr_mobile.dart
// قراءة عداد المياه على Android / iOS مع فحص جودة الصورة
// والمعالجة المتعددة (Adaptive Threshold + Spatial OCR + مراجعة تفاعلية)
// ============================================================

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'image_quality_analyzer.dart';
import 'meter_analysis.dart';
import 'ocr_quality_widgets.dart';

class _MobileOcrRunOutput {
  final MeterAnalysisResult analysis;
  final ImageQualityReport qualityReport;
  final Uint8List croppedBytes;
  final Uint8List? enhancedPreviewBytes;

  const _MobileOcrRunOutput({
    required this.analysis,
    required this.qualityReport,
    required this.croppedBytes,
    this.enhancedPreviewBytes,
  });
}

class _ImageVariantSpec {
  final File file;
  final String name;
  final double weight;
  final bool isTemporary;

  const _ImageVariantSpec({
    required this.file,
    required this.name,
    required this.weight,
    required this.isTemporary,
  });
}

/// ============================================================
/// قراءة عداد المياه - استخراج 7 أرقام مع فحص الجودة والمراجعة
/// مثال: 0650040
/// ============================================================

Future<String?> readNumberImpl({
  BuildContext? context,
  int? previousReading,
}) async {
  final ImagePicker picker = ImagePicker();

  try {
    // استرجاع الصورة المفقودة عند إعادة تشغيل Android
    final LostDataResponse lostData = await picker.retrieveLostData();

    if (!lostData.isEmpty) {
      final files = lostData.files;

      if (files != null && files.isNotEmpty) {
        final file = File(files.first.path);

        if (await file.exists() && await file.length() > 0) {
          return await _cropAndReadLoop(
            file,
            picker: picker,
            context: context,
            previousReading: previousReading,
          );
        }
      }
    }
  } catch (e) {
    debugPrint('استرجاع الصورة: $e');
  }

  ImageSource? selectedSource = ImageSource.camera;
  if (context != null && context.mounted) {
    selectedSource = await _showCaptureSourceSheet(context);
    if (selectedSource == null) {
      return null;
    }
  }

  File? currentFile = await _pickImageFile(picker, selectedSource);
  if (currentFile == null) return null;

  return _cropAndReadLoop(
    currentFile,
    picker: picker,
    context: context,
    previousReading: previousReading,
  );
}

/// ============================================================
/// نافذة اختيار مصدر الصورة مع إرشادات جودة التصوير
/// ============================================================

Future<ImageSource?> _showCaptureSourceSheet(BuildContext context) async {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'تصوير عداد المياه (7 خانات)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إرشادات لضمان أعلى جودة للصورة ودقة القراءة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• امسح زجاج العداد من الغبار أو قطرات الماء قبل التصوير.',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• تجنب انعكاس الفلاش المباشر على الزجاج (صوّر بزاوية مائلة قليلاً عند اللمعان).',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• في خطوة القص، حدد مستطيل الأرقام السبعة فقط بدون حواف العداد.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(
                          'الكاميرا',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text(
                          'معرض الصور',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<File?> _pickImageFile(
  ImagePicker picker,
  ImageSource source,
) async {
  final XFile? picked = await picker.pickImage(
    source: source,
    imageQuality: 100,
    maxWidth: 4000,
    maxHeight: 4000,
    preferredCameraDevice: CameraDevice.rear,
  );

  if (picked == null) return null;

  final File file = File(picked.path);
  if (!await file.exists() || await file.length() == 0) {
    throw Exception('تعذر الوصول إلى صورة العداد.');
  }

  return file;
}

/// ============================================================
/// حلقة القص والقراءة والمراجعة (تتيح إعادة القص أو إعادة التصوير)
/// ============================================================

Future<String?> _cropAndReadLoop(
  File initialImageFile, {
  required ImagePicker picker,
  BuildContext? context,
  int? previousReading,
}) async {
  File currentImageFile = initialImageFile;

  while (true) {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: currentImageFile.path,
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

    final File croppedFile = File(cropped.path);
    if (!await croppedFile.exists() || await croppedFile.length() == 0) {
      throw Exception('الصورة المقصوصة غير صالحة.');
    }

    final _MobileOcrRunOutput output = await _runOCRWithQuality(
      croppedFile,
      previousReading: previousReading,
    );

    // إذا كان context متوفراً، نعرض نافذة مراجعة جودة الصورة والخانات السبع
    if (context != null && context.mounted) {
      final OcrReviewOutcome? outcome =
          await showDialog<OcrReviewOutcome>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MeterOcrReviewDialog(
          croppedImageBytes: output.croppedBytes,
          enhancedImageBytes: output.enhancedPreviewBytes,
          qualityReport: output.qualityReport,
          analysisResult: output.analysis,
          previousReading: previousReading,
        ),
      );

      if (outcome == null || outcome.action == OcrReviewAction.cancel) {
        return null;
      }

      if (outcome.action == OcrReviewAction.confirm) {
        return outcome.reading;
      }

      if (outcome.action == OcrReviewAction.recrop) {
        // يعيد فتح أداة القص على نفس الصورة الأصلية دون الحاجة لإعادة التصوير
        continue;
      }

      if (outcome.action == OcrReviewAction.retake) {
        ImageSource? source = ImageSource.camera;
        if (context.mounted) {
          source = await _showCaptureSourceSheet(context);
        }
        if (source == null) return null;
        final File? newFile = await _pickImageFile(picker, source);
        if (newFile == null) return null;
        currentImageFile = newFile;
        continue;
      }
    }

    // في حال عدم تمرير context نعتمد النتيجة الأفضل مباشرة
    if (!output.analysis.isValid) {
      throw Exception(
        '${output.analysis.message}\n${output.qualityReport.summaryMessage}',
      );
    }

    return output.analysis.reading;
  }
}

/// ============================================================
/// فحص جودة الصورة + تشغيل OCR على النسخ المحسنة + التحليل الموضعي
/// ============================================================

Future<_MobileOcrRunOutput> _runOCRWithQuality(
  File croppedFile, {
  int? previousReading,
}) async {
  final Uint8List croppedBytes = await croppedFile.readAsBytes();
  final ImageQualityReport qualityReport =
      ImageQualityAnalyzer.analyzeBytes(croppedBytes);

  debugPrint('========================================');
  debugPrint(
    'جودة الصورة: ${qualityReport.levelText} '
    '(${qualityReport.overallScore.toStringAsFixed(1)}%) | '
    'الحدة: ${qualityReport.sharpnessScore.toStringAsFixed(1)} | '
    'الإضاءة: ${qualityReport.brightnessScore.toStringAsFixed(1)} | '
    'التباين: ${qualityReport.contrastScore.toStringAsFixed(1)} | '
    'الوهج: ${qualityReport.glareScore.toStringAsFixed(1)}',
  );
  debugPrint('========================================');

  final TextRecognizer recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  final List<_ImageVariantSpec> variants = <_ImageVariantSpec>[];
  Uint8List? enhancedPreviewBytes;

  try {
    final prep = await _createImageVariants(
      croppedFile,
      croppedBytes,
      qualityReport,
    );
    variants.addAll(prep.variants);
    enhancedPreviewBytes = prep.previewBytes;

    final List<String> rawTexts = <String>[];
    final List<WeightedOcrCandidate> weightedCandidates =
        <WeightedOcrCandidate>[];

    for (int i = 0; i < variants.length; i++) {
      final _ImageVariantSpec spec = variants[i];
      try {
        final InputImage input = InputImage.fromFilePath(spec.file.path);
        final RecognizedText recognized =
            await recognizer.processImage(input);

        debugPrint(
          'OCR [${spec.name}]: ${recognized.text.replaceAll('\n', ' | ')}',
        );

        if (recognized.text.trim().isNotEmpty) {
          rawTexts.add(recognized.text);
        }

        // 1. استخراج من كل سطر
        for (final TextBlock block in recognized.blocks) {
          for (final TextLine line in block.lines) {
            rawTexts.add(line.text);
            weightedCandidates.addAll(
              MeterAnalyzer.extractCandidatesFromText(
                line.text,
                baseWeight: spec.weight * 1.15,
                source: '${spec.name}-line',
              ),
            );
          }
        }

        // 2. إعادة بناء الخانات مكانياً من العناصر المرتبة من اليسار لليمين
        // يعالج حالة تقسيم ML Kit للأرقام السبعة إلى كتلتين متجاورتين أفقياً
        final String? spatialLine =
            _reconstructHorizontalDigits(recognized);
        if (spatialLine != null && spatialLine.isNotEmpty) {
          debugPrint('OCR [${spec.name}] Spatial: $spatialLine');
          rawTexts.add(spatialLine);
          weightedCandidates.addAll(
            MeterAnalyzer.extractCandidatesFromText(
              spatialLine,
              baseWeight: spec.weight * 1.25,
              source: '${spec.name}-spatial',
            ),
          );
        }

        // 3. استخراج من النص الكامل للنسخة
        weightedCandidates.addAll(
          MeterAnalyzer.extractCandidatesFromText(
            recognized.text,
            baseWeight: spec.weight * 0.9,
            source: '${spec.name}-full',
          ),
        );
      } catch (e) {
        debugPrint('خطأ OCR في النسخة ${spec.name}: $e');
      }
    }

    final MeterAnalysisResult analysis = MeterAnalyzer.analyze(
      rawTexts,
      previousReading: previousReading,
      weightedCandidates: weightedCandidates,
    );

    debugPrint('قراءة العداد المحللة: ${analysis.reading}');
    debugPrint('درجة الثقة: ${analysis.confidence.toStringAsFixed(1)}%');

    return _MobileOcrRunOutput(
      analysis: analysis,
      qualityReport: qualityReport,
      croppedBytes: croppedBytes,
      enhancedPreviewBytes: enhancedPreviewBytes,
    );
  } finally {
    await recognizer.close();
    // حذف الملفات المؤقتة للنسخ المحسنة
    for (final spec in variants) {
      if (spec.isTemporary) {
        try {
          if (await spec.file.exists()) {
            await spec.file.delete();
          }
        } catch (_) {}
      }
    }
  }
}

/// ============================================================
/// إعادة تجميع عناصر النص (TextElements) المرتبة أفقياً من اليسار لليمين
/// ============================================================

String? _reconstructHorizontalDigits(RecognizedText recognized) {
  final List<TextElement> elements = <TextElement>[];

  for (final block in recognized.blocks) {
    for (final line in block.lines) {
      for (final elem in line.elements) {
        final String norm = MeterAnalyzer.normalize(elem.text);
        if (norm.isNotEmpty) {
          elements.add(elem);
        }
      }
    }
  }

  if (elements.isEmpty) return null;

  // نرتب العناصر من اليسار إلى اليمين حسب إحداثيات X
  elements.sort(
    (a, b) => a.boundingBox.left.compareTo(b.boundingBox.left),
  );

  // نأخذ العناصر الواقعة على الخط الأفقي الرئيسي للعداد
  final List<double> centerYs = elements
      .map((e) => (e.boundingBox.top + e.boundingBox.bottom) / 2.0)
      .toList()
    ..sort();
  final double medianY = centerYs[centerYs.length ~/ 2];

  final List<double> heights = elements
      .map((e) => e.boundingBox.height.toDouble())
      .toList()
    ..sort();
  final double medianHeight =
      math.max(12.0, heights[heights.length ~/ 2]);

  final StringBuffer buffer = StringBuffer();
  for (final elem in elements) {
    final double cy =
        (elem.boundingBox.top + elem.boundingBox.bottom) / 2.0;
    if ((cy - medianY).abs() <= medianHeight * 0.95) {
      buffer.write(MeterAnalyzer.normalize(elem.text));
    }
  }

  final String combined = buffer.toString();
  return combined.isEmpty ? null : combined;
}

/// ============================================================
/// إنشاء نسخ محسنة للصورة لمعالجة الإضاءة الضعيفة، البكرات السوداء/الحمراء،
/// والظلال الجزئية على زجاج العداد
/// ============================================================

class _VariantsCreationResult {
  final List<_ImageVariantSpec> variants;
  final Uint8List? previewBytes;

  const _VariantsCreationResult({
    required this.variants,
    this.previewBytes,
  });
}

Future<_VariantsCreationResult> _createImageVariants(
  File original,
  Uint8List originalBytes,
  ImageQualityReport qualityReport,
) async {
  final List<_ImageVariantSpec> result = <_ImageVariantSpec>[
    _ImageVariantSpec(
      file: original,
      name: 'original',
      weight: 1.0,
      isTemporary: false,
    ),
  ];

  Uint8List? previewBytes;

  try {
    final img.Image? decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      debugPrint('تعذر فك الصورة؛ سيتم استخدام الأصل فقط.');
      return _VariantsCreationResult(variants: result);
    }

    final img.Image oriented = img.bakeOrientation(decoded);

    // تكبير الصورة إذا كانت صغيرة لضمان دقة التعرف على الخانات السبع
    img.Image baseWorking = oriented.clone();
    if (baseWorking.width < 1400) {
      baseWorking = img.copyResize(
        baseWorking,
        width: 1400,
        interpolation: img.Interpolation.cubic,
      );
    }

    // إضافة هامش هادئ حول الصورة لمنع ضياع الصفر الأول على الطرف الأيسر
    final img.Image paddedWorking = ImageQualityAnalyzer.addQuietZoneBorder(
      baseWorking,
      horizontalRatio: 0.12,
      verticalRatio: 0.22,
    );

    // 1. نسخة محسنة الحدة والتباين مع تعويض الإضاءة التلقائي
    final double targetBrightness = qualityReport.isDark
        ? 1.14
        : qualityReport.isOverexposed
            ? 0.92
            : 1.03;
    final double targetContrast = qualityReport.isLowContrast ? 1.55 : 1.38;

    final img.Image sharpened = ImageQualityAnalyzer.sharpenImage(
      paddedWorking,
      amount: qualityReport.isBlurry ? 0.85 : 0.55,
    );
    final img.Image contrastAdjusted = img.adjustColor(
      sharpened.clone(),
      contrast: targetContrast,
      brightness: targetBrightness,
    );

    final File sharpContrastFile = await _saveVariant(
      contrastAdjusted,
      original.path,
      'sharp_contrast',
    );
    previewBytes = await sharpContrastFile.readAsBytes();

    result.add(
      _ImageVariantSpec(
        file: sharpContrastFile,
        name: 'sharp_contrast',
        weight: 1.3,
        isTemporary: true,
      ),
    );

    // 2. نسخة رمادية مع تعزيز القناة الحمراء (لبكرات الكسور الحمراء في العدادات)
    final img.Image redBoostGray =
        ImageQualityAnalyzer.extractRedBoostGrayscale(paddedWorking);
    final img.Image redContrast = img.adjustColor(
      redBoostGray.clone(),
      contrast: 1.6,
      brightness: targetBrightness,
    );

    result.add(
      _ImageVariantSpec(
        file: await _saveVariant(redContrast, original.path, 'red_gray'),
        name: 'red_gray',
        weight: 1.2,
        isTemporary: true,
      ),
    );

    // 3. نسخة ثنائية تكيفية محلية مع إزالة خطوط الفواصل العمودية
    final img.Image adaptiveBin = ImageQualityAnalyzer.adaptiveBinarize(
      sharpened,
      invert: false,
      sensitivity: 0.11,
      suppressVerticalDividers: true,
    );

    result.add(
      _ImageVariantSpec(
        file: await _saveVariant(adaptiveBin, original.path, 'adaptive_bin'),
        name: 'adaptive_bin',
        weight: 1.25,
        isTemporary: true,
      ),
    );

    // 4. نسخة معكوسة (للبكرات السوداء أو الحمراء ذات الأرقام البيضاء)
    final img.Image invertedGray = img.invert(redBoostGray.clone());
    final img.Image invertedContrast = img.adjustColor(
      invertedGray,
      contrast: 1.55,
      brightness: 1.02,
    );

    result.add(
      _ImageVariantSpec(
        file: await _saveVariant(
          invertedContrast,
          original.path,
          'inverted_drums',
        ),
        name: 'inverted_drums',
        weight: 1.15,
        isTemporary: true,
      ),
    );
  } catch (e) {
    debugPrint('تعذر تجهيز نسخ الصورة: $e');
  }

  return _VariantsCreationResult(
    variants: result,
    previewBytes: previewBytes,
  );
}

/// ============================================================
/// حفظ نسخة الصورة
/// ============================================================

Future<File> _saveVariant(
  img.Image image,
  String originalPath,
  String suffix,
) async {
  final String directory = File(originalPath).parent.path;
  final String path =
      '$directory/ocr_${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg';

  final Uint8List encoded = Uint8List.fromList(
    img.encodeJpg(image, quality: 95),
  );

  final File file = File(path);
  await file.writeAsBytes(encoded, flush: true);

  return file;
}
