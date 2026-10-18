// ============================================================
// image_quality_analyzer.dart
// فحص جودة صورة العداد وتحسينها قبل عملية القراءة الآلية (OCR)
// يعمل على جميع المنصات (Android / iOS / Web)
// ============================================================

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum ImageQualityLevel {
  excellent,
  good,
  fair,
  poor,
}

class ImageQualityReport {
  final double overallScore;
  final double sharpnessScore;
  final double brightnessScore;
  final double contrastScore;
  final double glareScore;

  final double meanLuminance;
  final double stdLuminance;
  final double dynamicRange;
  final double glareRatio;

  final int width;
  final int height;

  final ImageQualityLevel level;
  final bool isAcceptable;
  final List<String> issues;
  final List<String> tips;

  const ImageQualityReport({
    required this.overallScore,
    required this.sharpnessScore,
    required this.brightnessScore,
    required this.contrastScore,
    required this.glareScore,
    required this.meanLuminance,
    required this.stdLuminance,
    required this.dynamicRange,
    required this.glareRatio,
    required this.width,
    required this.height,
    required this.level,
    required this.isAcceptable,
    required this.issues,
    required this.tips,
  });

  String get levelText {
    switch (level) {
      case ImageQualityLevel.excellent:
        return 'ممتازة';
      case ImageQualityLevel.good:
        return 'جيدة';
      case ImageQualityLevel.fair:
        return 'متوسطة';
      case ImageQualityLevel.poor:
        return 'ضعيفة';
    }
  }

  bool get isDark => meanLuminance < 75;
  bool get isOverexposed => meanLuminance > 205;
  bool get isBlurry => sharpnessScore < 45;
  bool get isLowContrast => contrastScore < 45;
  bool get hasGlare => glareScore < 65;

  String get summaryMessage {
    if (issues.isEmpty) {
      return 'جودة الصورة $levelText ومناسبة لقراءة العداد.';
    }
    return 'جودة الصورة $levelText: ${issues.join('، ')}.';
  }
}

class ImageQualityAnalyzer {
  ImageQualityAnalyzer._();

  // ==========================================================
  // تحليل جودة الصورة من الـ Bytes
  // ==========================================================

  static ImageQualityReport analyzeBytes(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageQualityReport(
        overallScore: 0,
        sharpnessScore: 0,
        brightnessScore: 0,
        contrastScore: 0,
        glareScore: 0,
        meanLuminance: 0,
        stdLuminance: 0,
        dynamicRange: 0,
        glareRatio: 0,
        width: 0,
        height: 0,
        level: ImageQualityLevel.poor,
        isAcceptable: false,
        issues: ['تعذر قراءة ملف الصورة'],
        tips: ['أعد التقاط صورة واضحة للعداد'],
      );
    }

    final img.Image oriented = img.bakeOrientation(decoded);
    return analyzeImage(oriented);
  }

  // ==========================================================
  // تحليل كائن الصورة مباشرة
  // ==========================================================

  static ImageQualityReport analyzeImage(img.Image source) {
    final int origW = source.width;
    final int origH = source.height;

    if (origW < 40 || origH < 15) {
      return ImageQualityReport(
        overallScore: 15,
        sharpnessScore: 0,
        brightnessScore: 0,
        contrastScore: 0,
        glareScore: 0,
        meanLuminance: 0,
        stdLuminance: 0,
        dynamicRange: 0,
        glareRatio: 0,
        width: origW,
        height: origH,
        level: ImageQualityLevel.poor,
        isAcceptable: false,
        issues: const ['أبعاد الصورة المقصوصة صغيرة جداً'],
        tips: const [
          'قرّب الكاميرا من شاشة العداد وحدد نافذة الأرقام السبعة بالكامل',
        ],
      );
    }

    // تصغير نسخة التحليل لتسريع الحسابات على الأجهزة الضعيفة
    img.Image sample = source;
    if (sample.width > 480) {
      sample = img.copyResize(
        source,
        width: 480,
        interpolation: img.Interpolation.linear,
      );
    }

    final int w = sample.width;
    final int h = sample.height;

    // نركز على المنطقة الوسطى (90% عرض × 86% ارتفاع) حيث تقع الأرقام
    final int startX = math.max(1, (w * 0.05).round());
    final int endX = math.min(w - 1, (w * 0.95).round());
    final int startY = math.max(1, (h * 0.07).round());
    final int endY = math.min(h - 1, (h * 0.93).round());

    final List<int> histogram = List<int>.filled(256, 0);
    final Float64List lumGrid = Float64List(w * h);

    double sumLum = 0;
    int pixelCount = 0;
    int glarePixels = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = sample.getPixel(x, y);
        final num r = p.r;
        final num g = p.g;
        final num b = p.b;

        final double lum = 0.299 * r + 0.587 * g + 0.114 * b;
        final int lumInt = lum.round().clamp(0, 255);
        lumGrid[y * w + x] = lum;

        if (x >= startX && x < endX && y >= startY && y < endY) {
          histogram[lumInt]++;
          sumLum += lum;
          pixelCount++;

          final num maxCh = math.max(r, math.max(g, b));
          final num minCh = math.min(r, math.min(g, b));
          if (lumInt >= 245 && (maxCh - minCh) <= 22) {
            glarePixels++;
          }
        }
      }
    }

    if (pixelCount == 0) {
      pixelCount = 1;
    }

    final double meanLum = sumLum / pixelCount;

    // الانحراف المعياري للسطوع (مقياس التباين)
    double varianceSum = 0;
    for (int i = 0; i < 256; i++) {
      if (histogram[i] > 0) {
        final double diff = i - meanLum;
        varianceSum += diff * diff * histogram[i];
      }
    }
    final double stdLum = math.sqrt(varianceSum / pixelCount);

    // حساب المدى الديناميكي (P92 - P8)
    final double p8 = _percentileFromHistogram(histogram, pixelCount, 0.08);
    final double p92 = _percentileFromHistogram(histogram, pixelCount, 0.92);
    final double dynamicRange = math.max(0, p92 - p8);

    // حساب حدة الحواف (Sobel + Laplacian Energy)
    final List<double> edgeStrengths = <double>[];
    double laplacianSumSq = 0;
    int edgeSampleCount = 0;

    for (int y = startY; y < endY; y++) {
      final int row = y * w;
      final int rowUp = (y - 1) * w;
      final int rowDown = (y + 1) * w;

      for (int x = startX; x < endX; x++) {
        final double center = lumGrid[row + x];
        final double left = lumGrid[row + x - 1];
        final double right = lumGrid[row + x + 1];
        final double up = lumGrid[rowUp + x];
        final double down = lumGrid[rowDown + x];

        final double gx = (right - left).abs();
        final double gy = (down - up).abs();
        final double grad = math.sqrt(gx * gx + gy * gy);

        final double lap = (4 * center - left - right - up - down).abs();
        laplacianSumSq += lap * lap;
        edgeStrengths.add(grad);
        edgeSampleCount++;
      }
    }

    edgeStrengths.sort();
    final double p90Edge = edgeStrengths.isEmpty
        ? 0
        : edgeStrengths[(edgeStrengths.length * 0.90).floor()];
    final double laplacianRms = edgeSampleCount > 0
        ? math.sqrt(laplacianSumSq / edgeSampleCount)
        : 0;

    // تطبيع الحدة بالنسبة للتباين المحلي لتفادي ظلم الصور ذات الخلفية الموحدة
    final double normalizedEdge = dynamicRange > 18
        ? (p90Edge / math.max(35.0, dynamicRange * 0.55)) * 65.0
        : p90Edge;

    final double rawSharpness = normalizedEdge * 0.65 + laplacianRms * 1.15;
    final double sharpnessScore = (rawSharpness / 42.0 * 100.0).clamp(0.0, 100.0);

    // تقييم الإضاءة (المثالي بين 85 و 185)
    double brightnessScore;
    if (meanLum >= 85 && meanLum <= 185) {
      brightnessScore = 100.0 - ((meanLum - 135).abs() / 50.0) * 12.0;
    } else if (meanLum < 85) {
      brightnessScore = (meanLum / 85.0 * 85.0).clamp(0.0, 85.0);
    } else {
      brightnessScore = ((255.0 - meanLum) / 70.0 * 85.0).clamp(10.0, 85.0);
    }

    // تقييم التباين
    final double stdScore = (stdLum / 52.0 * 100.0).clamp(0.0, 100.0);
    final double rangeScore = (dynamicRange / 135.0 * 100.0).clamp(0.0, 100.0);
    final double contrastScore =
        (stdScore * 0.55 + rangeScore * 0.45).clamp(0.0, 100.0);

    // تقييم الوهج والانعكاس الضوئي
    final double glareRatio = glarePixels / pixelCount;
    double glareScore = 100.0;
    if (glareRatio > 0.025) {
      glareScore =
          (100.0 - ((glareRatio - 0.025) / 0.22) * 100.0).clamp(0.0, 100.0);
    }

    // الدرجة الكلية
    double overallScore = sharpnessScore * 0.36 +
        contrastScore * 0.28 +
        brightnessScore * 0.20 +
        glareScore * 0.16;

    final List<String> issues = <String>[];
    final List<String> tips = <String>[];

    // فحص الأبعاد ونسبة العرض إلى الارتفاع
    final double aspect = origW / math.max(1, origH);
    if (origW < 180 || origH < 40) {
      overallScore -= 18;
      issues.add('دقة منطقة الأرقام منخفضة');
      tips.add('قرّب الهاتف من العداد أثناء التصوير لتكون الأرقام كبيرة وواضحة');
    }

    if (aspect < 1.35) {
      overallScore -= 8;
      issues.add('منطقة القص مربعة أكثر من اللازم');
      tips.add('قص الشريط الأفقي للأرقام السبعة فقط بدون جسم العداد');
    }

    if (sharpnessScore < 45) {
      issues.add('الصورة غير حادة (مهتزة أو غير مركزة)');
      tips.add('ثبّت يدك واضغط على شاشة العداد للتركيز (Focus) قبل الالتقاط');
    }

    if (meanLum < 72) {
      issues.add('الإضاءة ضعيفة جداً');
      tips.add('استخدم إضاءة كافية أو صوّر في مكان جيد الإضاءة');
    } else if (meanLum > 205) {
      issues.add('الإضاءة ساطعة جداً');
      tips.add('خفف الإضاءة المباشرة لتجنب اختفاء تفاصيل الأرقام');
    }

    if (contrastScore < 45) {
      issues.add('التباين منخفض بين الأرقام والخلفية');
      tips.add('امسح زجاج العداد من الغبار أو البخار قبل التصوير');
    }

    if (glareScore < 65) {
      issues.add('يوجد انعكاس ضوئي (وهج) على زجاج العداد');
      tips.add('غيّر زاوية التصوير قليلاً لتجنب انعكاس الفلاش أو الشمس على الزجاج');
    }

    overallScore = overallScore.clamp(0.0, 100.0);

    ImageQualityLevel level;
    if (overallScore >= 78) {
      level = ImageQualityLevel.excellent;
    } else if (overallScore >= 60) {
      level = ImageQualityLevel.good;
    } else if (overallScore >= 42) {
      level = ImageQualityLevel.fair;
    } else {
      level = ImageQualityLevel.poor;
    }

    final bool isAcceptable = overallScore >= 38 && origW >= 100 && origH >= 25;

    return ImageQualityReport(
      overallScore: overallScore,
      sharpnessScore: sharpnessScore,
      brightnessScore: brightnessScore,
      contrastScore: contrastScore,
      glareScore: glareScore,
      meanLuminance: meanLum,
      stdLuminance: stdLum,
      dynamicRange: dynamicRange,
      glareRatio: glareRatio,
      width: origW,
      height: origH,
      level: level,
      isAcceptable: isAcceptable,
      issues: issues,
      tips: tips,
    );
  }

  static double _percentileFromHistogram(
    List<int> histogram,
    int total,
    double percentile,
  ) {
    final int target = (total * percentile).round();
    int cumulative = 0;
    for (int i = 0; i < 256; i++) {
      cumulative += histogram[i];
      if (cumulative >= target) {
        return i.toDouble();
      }
    }
    return 255.0;
  }

  // ==========================================================
  // إضافة هامش هادئ حول الأرقام (Quiet Zone Padding)
  // يمنع ضياع الرقم الأول (خصوصاً الصفر) أو الأخير عند القص الضيق
  // ==========================================================

  static img.Image addQuietZoneBorder(
    img.Image src, {
    double horizontalRatio = 0.12,
    double verticalRatio = 0.22,
    int? fillGray,
  }) {
    final int padX = math.max(16, (src.width * horizontalRatio).round());
    final int padY = math.max(12, (src.height * verticalRatio).round());

    final int bg = fillGray ?? _estimateBorderLuminance(src);

    final img.Image padded = img.Image(
      width: src.width + padX * 2,
      height: src.height + padY * 2,
    );

    // تعبئة الخلفية بلون محايد قريب من حواف العداد
    for (int y = 0; y < padded.height; y++) {
      for (int x = 0; x < padded.width; x++) {
        padded.setPixelRgb(x, y, bg, bg, bg);
      }
    }

    img.compositeImage(
      padded,
      src,
      dstX: padX,
      dstY: padY,
    );

    return padded;
  }

  static int _estimateBorderLuminance(img.Image src) {
    final List<int> samples = <int>[];
    final int w = src.width;
    final int h = src.height;

    for (int x = 0; x < w; x += math.max(1, w ~/ 30)) {
      final top = src.getPixel(x, 0);
      final bottom = src.getPixel(x, h - 1);
      samples.add((0.299 * top.r + 0.587 * top.g + 0.114 * top.b).round());
      samples
          .add((0.299 * bottom.r + 0.587 * bottom.g + 0.114 * bottom.b).round());
    }

    if (samples.isEmpty) return 235;
    samples.sort();
    return samples[samples.length ~/ 2].clamp(40, 245);
  }

  // ==========================================================
  // زيادة حدة الأرقام (Unsharp / Convolution Sharpening)
  // ==========================================================

  static img.Image sharpenImage(
    img.Image src, {
    double amount = 0.65,
  }) {
    final img.Image copy = src.clone();
    return img.convolution(
      copy,
      filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ],
      div: 1,
      offset: 0,
      amount: amount,
    );
  }

  // ==========================================================
  // استخراج القناة الحمراء (مهم لبكرات الكسور الحمراء في عدادات المياه)
  // ==========================================================

  static img.Image extractRedBoostGrayscale(img.Image src) {
    final img.Image out = img.Image(
      width: src.width,
      height: src.height,
    );

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        // تعزيز القناة الحمراء والخضراء لتوضيح الأرقام على الخلفيات الحمراء أو السوداء
        final int val = (0.55 * p.r + 0.35 * p.g + 0.10 * p.b)
            .round()
            .clamp(0, 255);
        out.setPixelRgb(x, y, val, val, val);
      }
    }

    return out;
  }

  // ==========================================================
  // تحويل ثنائي تكيفي محلي (Bradley-Roth Integral Image Adaptive Threshold)
  // يعالج الظلال الجزئية، البكرات السوداء ذات الأرقام البيضاء، والفواصل العمودية
  // ==========================================================

  static img.Image adaptiveBinarize(
    img.Image src, {
    bool invert = false,
    double sensitivity = 0.11,
    bool suppressVerticalDividers = true,
  }) {
    final int w = src.width;
    final int h = src.height;

    final Int32List lum = Int32List(w * h);
    final Int64List integral = Int64List(w * h);

    for (int y = 0; y < h; y++) {
      int rowSum = 0;
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        int v = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
        if (invert) {
          v = 255 - v;
        }
        lum[y * w + x] = v;
        rowSum += v;
        if (y == 0) {
          integral[x] = rowSum;
        } else {
          integral[y * w + x] = integral[(y - 1) * w + x] + rowSum;
        }
      }
    }

    final int windowRadiusX = math.max(8, (w / 14).round());
    final int windowRadiusY = math.max(8, (h / 4).round());

    final Uint8List binary = Uint8List(w * h); // 1 = black ink, 0 = white bg

    for (int y = 0; y < h; y++) {
      final int y1 = math.max(0, y - windowRadiusY);
      final int y2 = math.min(h - 1, y + windowRadiusY);

      for (int x = 0; x < w; x++) {
        final int x1 = math.max(0, x - windowRadiusX);
        final int x2 = math.min(w - 1, x + windowRadiusX);

        final int count = (x2 - x1 + 1) * (y2 - y1 + 1);

        int sum = integral[y2 * w + x2];
        if (y1 > 0) sum -= integral[(y1 - 1) * w + x2];
        if (x1 > 0) sum -= integral[y2 * w + (x1 - 1)];
        if (y1 > 0 && x1 > 0) sum += integral[(y1 - 1) * w + (x1 - 1)];

        final int current = lum[y * w + x];
        final double threshold = (sum / count) * (1.0 - sensitivity);

        binary[y * w + x] = current < threshold ? 1 : 0;
      }
    }

    // إزالة الخطوط العمودية الفاصلة بين خانات العداد (التي قد تُقرأ كأنها رقم 1)
    if (suppressVerticalDividers && h >= 20 && w >= 60) {
      for (int x = 1; x < w - 1; x++) {
        int blackCount = 0;
        for (int y = 0; y < h; y++) {
          if (binary[y * w + x] == 1) {
            blackCount++;
          }
        }
        // إذا كان العمود أسود بنسبة تزيد عن 86% من كامل ارتفاع الصورة فهو خط إطار فاصل
        if (blackCount > h * 0.86) {
          // نتأكد أنه خط رفيع وليس جزءاً عريضاً من رقم
          int neighborHorizontal = 0;
          final int checkXLeft = math.max(0, x - 3);
          final int checkXRight = math.min(w - 1, x + 3);
          for (int y = (h * 0.2).round(); y < (h * 0.8).round(); y++) {
            if (binary[y * w + checkXLeft] == 0 &&
                binary[y * w + checkXRight] == 0) {
              neighborHorizontal++;
            }
          }
          if (neighborHorizontal > (h * 0.35)) {
            for (int y = 0; y < h; y++) {
              binary[y * w + x] = 0;
            }
          }
        }
      }
    }

    final img.Image out = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int c = binary[y * w + x] == 1 ? 0 : 255;
        out.setPixelRgb(x, y, c, c, c);
      }
    }

    return out;
  }
}
