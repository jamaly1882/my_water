// ============================================================
// meter_analysis.dart
// تحليل قراءة العداد محليًا
// لا يحتاج Cloud Functions
// ============================================================

class MeterAnalysisResult {
  final String reading;
  final double confidence;
  final int occurrences;
  final bool isValid;
  final String message;

  const MeterAnalysisResult({
    required this.reading,
    required this.confidence,
    required this.occurrences,
    required this.isValid,
    required this.message,
  });

  String get confidenceText {
    if (confidence >= 85) {
      return 'عالية';
    }

    if (confidence >= 65) {
      return 'متوسطة';
    }

    return 'منخفضة';
  }

  bool get isHighConfidence {
    return confidence >= 85;
  }
}

// ============================================================
// تحليل نتائج OCR
// ============================================================

class MeterAnalyzer {
  // ----------------------------------------------------------
  // تنظيف الرقم
  // ----------------------------------------------------------

  static String normalize(String value) {
    String result = value.trim();

    result = result
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('d', '0')
        .replaceAll('Q', '0')
        .replaceAll('q', '0')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('L', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll('Z', '2')
        .replaceAll('z', '2')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('G', '6')
        .replaceAll('g', '6')
        .replaceAll('B', '8')
        .replaceAll('b', '8');

    result = result
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    result = result.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return result;
  }

  // ----------------------------------------------------------
  // التحقق
  // ----------------------------------------------------------

  static bool isValid(String value) {
    return RegExp(
      r'^\d{7}$',
    ).hasMatch(value);
  }

  // ----------------------------------------------------------
  // تحليل قائمة نتائج OCR
  // ----------------------------------------------------------

  static MeterAnalysisResult analyze(
    List<String> rawResults,
  ) {
    final Map<String, int> counts = {};

    for (final raw in rawResults) {
      final value = normalize(raw);

      if (!isValid(value)) {
        continue;
      }

      counts[value] =
          (counts[value] ?? 0) + 1;
    }

    // --------------------------------------------------------
    // لا توجد قراءة
    // --------------------------------------------------------

    if (counts.isEmpty) {
      return const MeterAnalysisResult(
        reading: '',
        confidence: 0,
        occurrences: 0,
        isValid: false,
        message:
            'لم يتم العثور على قراءة عداد واضحة.',
      );
    }

    // --------------------------------------------------------
    // ترتيب النتائج
    // --------------------------------------------------------

    final entries =
        counts.entries.toList();

    entries.sort(
      (a, b) => b.value.compareTo(a.value),
    );

    final best = entries.first;

    // --------------------------------------------------------
    // حساب الثقة
    // --------------------------------------------------------

    final total =
        counts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    double confidence =
        (best.value / total) * 100;

    // --------------------------------------------------------
    // تعزيز الثقة عند تكرار النتيجة
    // --------------------------------------------------------

    if (best.value >= 5) {
      confidence += 10;
    } else if (best.value >= 3) {
      confidence += 5;
    }

    if (confidence > 100) {
      confidence = 100;
    }

    String message;

    if (confidence >= 85) {
      message =
          'تم التعرف على القراءة بدرجة ثقة عالية.';
    } else if (confidence >= 65) {
      message =
          'تم التعرف على القراءة، لكن يُفضل التحقق منها.';
    } else {
      message =
          'القراءة غير مؤكدة، يُفضل إعادة تصوير العداد.';
    }

    return MeterAnalysisResult(
      reading: best.key,
      confidence: confidence,
      occurrences: best.value,
      isValid: true,
      message: message,
    );
  }
}