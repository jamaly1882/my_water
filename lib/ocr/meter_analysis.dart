// ============================================================
// meter_analysis.dart
// تحليل قراءة العداد محليًا مع التصويت الموضعي للخانات السبع
// والتحقق السياقي من القراءة السابقة (لا يحتاج Cloud Functions)
// ============================================================

import 'dart:math' as math;

class WeightedOcrCandidate {
  final String text;
  final double weight;
  final String source;

  const WeightedOcrCandidate({
    required this.text,
    this.weight = 1.0,
    this.source = 'ocr',
  });
}

class MeterAnalysisResult {
  final String reading;
  final double confidence;
  final int occurrences;
  final int totalAttempts;
  final bool isValid;
  final String message;
  final List<String> alternatives;
  final List<double> digitConfidences;
  final String partialReading;

  const MeterAnalysisResult({
    required this.reading,
    required this.confidence,
    required this.occurrences,
    this.totalAttempts = 0,
    required this.isValid,
    required this.message,
    this.alternatives = const <String>[],
    this.digitConfidences = const <double>[],
    this.partialReading = '',
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
  // تحويل الأرقام العربية والفارسية والحروف المشابهة بصرياً
  // ----------------------------------------------------------

  static String normalizeTextKeepSeparators(String value) {
    String result = value.trim();

    // الأرقام العربية (٠-٩)
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

    // الأرقام الفارسية (۰-۹)
    result = result
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');

    // الحروف المتشابهة بصرياً مع الأرقام في شاشات العدادات
    result = result
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('D', '0')
        .replaceAll('d', '0')
        .replaceAll('Q', '0')
        .replaceAll('q', '0')
        .replaceAll('U', '0')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('L', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll('!', '1')
        .replaceAll('Z', '2')
        .replaceAll('z', '2')
        .replaceAll('E', '3')
        .replaceAll('A', '4')
        .replaceAll('a', '4')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('G', '6')
        .replaceAll('g', '6')
        .replaceAll('T', '7')
        .replaceAll('t', '7')
        .replaceAll('B', '8')
        .replaceAll('b', '8');

    return result;
  }

  // ----------------------------------------------------------
  // تنظيف الرقم وإبقاء الخانات الرقمية فقط
  // ----------------------------------------------------------

  static String normalize(String value) {
    return normalizeTextKeepSeparators(value).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  // ----------------------------------------------------------
  // التحقق من 7 خانات بالضبط
  // ----------------------------------------------------------

  static bool isValid(String value) {
    return RegExp(
      r'^\d{7}$',
    ).hasMatch(value.trim());
  }

  // ----------------------------------------------------------
  // استخراج المرشحات ذات الـ 7 أرقام من سطر أو نص OCR
  // يعالج الفواصل بين الخانات وحدود الإطار المقروءة كـ 1
  // ----------------------------------------------------------

  static List<WeightedOcrCandidate> extractCandidatesFromText(
    String rawText, {
    double baseWeight = 1.0,
    String source = 'ocr',
  }) {
    final List<WeightedOcrCandidate> results = <WeightedOcrCandidate>[];
    if (rawText.trim().isEmpty) {
      return results;
    }

    final String normalized = normalizeTextKeepSeparators(rawText);

    // 1. سبعة أرقام متجاورة مباشرة
    final Iterable<RegExpMatch> directMatches =
        RegExp(r'(?<!\d)\d{7}(?!\d)').allMatches(normalized);

    for (final match in directMatches) {
      final String candidate = match.group(0)!;
      results.add(
        WeightedOcrCandidate(
          text: candidate,
          weight: baseWeight * 1.25,
          source: '$source-direct',
        ),
      );
    }

    // 2. سبعة أرقام مفصولة بمسافات أو فواصل إطارات الخانات
    final Iterable<RegExpMatch> separatedMatches = RegExp(
      r'(?<!\d)(\d(?:[\s.,:;|_/\-\[\]()]*\d){6})(?!\d)',
    ).allMatches(normalized);

    for (final match in separatedMatches) {
      final String digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 7) {
        final bool alreadyDirect = results.any((c) => c.text == digits);
        results.add(
          WeightedOcrCandidate(
            text: digits,
            weight: alreadyDirect ? baseWeight * 0.5 : baseWeight * 1.0,
            source: '$source-separated',
          ),
        );
      }
    }

    // 3. معالجة حالة 8 أرقام الناتجة عن قراءة إطار العداد الجانبي كرقم (1)
    final Iterable<RegExpMatch> eightDigitMatches =
        RegExp(r'(?<!\d)\d{8}(?!\d)').allMatches(normalized);

    for (final match in eightDigitMatches) {
      final String eight = match.group(0)!;
      if (eight.startsWith('1')) {
        results.add(
          WeightedOcrCandidate(
            text: eight.substring(1),
            weight: baseWeight * 0.55,
            source: '$source-trim-left-border',
          ),
        );
      }
      if (eight.endsWith('1')) {
        results.add(
          WeightedOcrCandidate(
            text: eight.substring(0, 7),
            weight: baseWeight * 0.55,
            source: '$source-trim-right-border',
          ),
        );
      }
    }

    // 4. إذا كان السطر كله بعد إزالة غير الأرقام يساوي 7 خانات بالضبط
    final String allDigits = normalized.replaceAll(RegExp(r'\D'), '');
    if (allDigits.length == 7 &&
        !results.any((c) => c.text == allDigits)) {
      results.add(
        WeightedOcrCandidate(
          text: allDigits,
          weight: baseWeight * 0.85,
          source: '$source-clean',
        ),
      );
    }

    return results;
  }

  // ----------------------------------------------------------
  // استخراج أفضل قراءة جزئية (5 أو 6 أرقام) لمساعدة المستخدم عند صعوبة الصورة
  // ----------------------------------------------------------

  static String extractBestPartialReading(List<String> rawResults) {
    final Map<String, int> partials = <String, int>{};

    for (final raw in rawResults) {
      final String norm = normalizeTextKeepSeparators(raw);
      for (final match in RegExp(r'\d{4,6}').allMatches(norm)) {
        final String d = match.group(0)!;
        partials[d] = (partials[d] ?? 0) + 1;
      }
      final String clean = normalize(raw);
      if (clean.length >= 4 && clean.length <= 6) {
        partials[clean] = (partials[clean] ?? 0) + 2;
      }
    }

    if (partials.isEmpty) return '';

    final sorted = partials.entries.toList()
      ..sort((a, b) {
        final int lenCmp = b.key.length.compareTo(a.key.length);
        if (b.value != a.value) return b.value.compareTo(a.value);
        return lenCmp;
      });

    return sorted.first.key;
  }

  // ----------------------------------------------------------
  // تحليل قائمة نتائج OCR مع التصويت الموضعي والسياقي
  // ----------------------------------------------------------

  static MeterAnalysisResult analyze(
    List<String> rawResults, {
    int? previousReading,
    List<WeightedOcrCandidate>? weightedCandidates,
  }) {
    final List<WeightedOcrCandidate> allCandidates = <WeightedOcrCandidate>[];

    if (weightedCandidates != null) {
      for (final wc in weightedCandidates) {
        final String clean = normalize(wc.text);
        if (isValid(clean)) {
          allCandidates.add(
            WeightedOcrCandidate(
              text: clean,
              weight: wc.weight,
              source: wc.source,
            ),
          );
        } else {
          allCandidates.addAll(
            extractCandidatesFromText(
              wc.text,
              baseWeight: wc.weight,
              source: wc.source,
            ),
          );
        }
      }
    }

    for (final raw in rawResults) {
      final String clean = normalize(raw);
      if (isValid(clean)) {
        allCandidates.add(
          WeightedOcrCandidate(
            text: clean,
            weight: 1.0,
            source: 'raw',
          ),
        );
      } else {
        allCandidates.addAll(
          extractCandidatesFromText(raw, baseWeight: 0.9),
        );
      }
    }

    // --------------------------------------------------------
    // لا توجد قراءة من 7 أرقام
    // --------------------------------------------------------

    if (allCandidates.isEmpty) {
      final String partial = extractBestPartialReading(rawResults);
      return MeterAnalysisResult(
        reading: '',
        confidence: 0,
        occurrences: 0,
        totalAttempts: rawResults.length,
        isValid: false,
        partialReading: partial,
        message: partial.isNotEmpty
            ? 'تم التعرف جزئياً على ($partial) فقط. يرجى ضبط القص على الخانات السبع أو إكمال الرقم.'
            : 'لم يتم العثور على قراءة عداد واضحة من 7 خانات.',
      );
    }

    // --------------------------------------------------------
    // حساب التكرار والأوزان لكل مرشح + التصويت الموضعي للخانات السبع
    // --------------------------------------------------------

    final Map<String, double> candidateScores = <String, double>{};
    final Map<String, int> candidateCounts = <String, int>{};

    // مصفوفة تصويت لكل خانة من الخانات السبع (0..6)
    final List<Map<String, double>> positionalVotes = List.generate(
      7,
      (_) => <String, double>{},
    );

    double totalWeight = 0;

    for (final item in allCandidates) {
      final String val = item.text;
      if (!isValid(val)) continue;

      double w = item.weight;

      // تعزيز المرشحات المنطقية بناءً على القراءة السابقة إن وجدت
      if (previousReading != null && previousReading > 0) {
        final int? parsed = int.tryParse(val);
        if (parsed != null) {
          if (parsed >= previousReading) {
            final int diff = parsed - previousReading;
            if (diff <= 10000) {
              w *= 1.35; // استهلاك منطقي جداً
            } else if (diff <= 100000) {
              w *= 1.15;
            }
          } else {
            // أقل من القراءة السابقة: غالباً خطأ قراءة في إحدى الخانات العليا
            w *= 0.55;
          }
        }
      }

      candidateScores[val] = (candidateScores[val] ?? 0.0) + w;
      candidateCounts[val] = (candidateCounts[val] ?? 0) + 1;
      totalWeight += w;

      for (int i = 0; i < 7; i++) {
        final String d = val[i];
        positionalVotes[i][d] = (positionalVotes[i][d] ?? 0.0) + w;
      }
    }

    // --------------------------------------------------------
    // تركيب القراءة التوافقية من التصويت الموضعي للخانات السبع
    // --------------------------------------------------------

    final StringBuffer consensusBuffer = StringBuffer();
    final List<double> digitConfidences = <double>[];

    for (int i = 0; i < 7; i++) {
      final Map<String, double> slotVotes = positionalVotes[i];
      if (slotVotes.isEmpty) {
        consensusBuffer.write('0');
        digitConfidences.add(0);
        continue;
      }

      final sortedSlot = slotVotes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final bestDigit = sortedSlot.first;
      consensusBuffer.write(bestDigit.key);

      final double slotTotal =
          slotVotes.values.fold(0.0, (sum, v) => sum + v);
      final double slotConf = slotTotal > 0
          ? ((bestDigit.value / slotTotal) * 100.0).clamp(0.0, 100.0)
          : 0.0;
      digitConfidences.add(slotConf);
    }

    final String positionalConsensus = consensusBuffer.toString();

    // إذا كانت القراءة التوافقية الموضعية موجودة أو منطقية نضيف لها دعماً
    if (isValid(positionalConsensus)) {
      candidateScores[positionalConsensus] =
          (candidateScores[positionalConsensus] ?? 0.0) +
              (totalWeight * 0.22);
      candidateCounts[positionalConsensus] =
          math.max(candidateCounts[positionalConsensus] ?? 1, 1);
    }

    // ترتيب المرشحات النهائية
    final sortedCandidates = candidateScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final String bestReading = sortedCandidates.first.key;
    final int bestCount = candidateCounts[bestReading] ?? 1;

    // حساب نسبة الثقة الإجمالية من ثقة الخانات السبع وتكرار المرشح الأفضل
    final double avgDigitConfidence = digitConfidences.isEmpty
        ? 50.0
        : digitConfidences.reduce((a, b) => a + b) / digitConfidences.length;

    final double frequencyRatio = totalWeight > 0
        ? ((candidateScores[bestReading]! / (totalWeight * 1.22)) * 100.0)
            .clamp(0.0, 100.0)
        : 50.0;

    double confidence =
        avgDigitConfidence * 0.60 + frequencyRatio * 0.40;

    if (bestCount >= 4) {
      confidence += 12;
    } else if (bestCount >= 2) {
      confidence += 6;
    }

    confidence = confidence.clamp(15.0, 100.0);

    // البدائل المقترحة (إن وجدت قراءات أخرى قريبة)
    final List<String> alternatives = sortedCandidates
        .map((e) => e.key)
        .where((k) => k != bestReading)
        .take(3)
        .toList();

    String message;
    if (confidence >= 85) {
      message = 'تم التعرف على القراءة بدرجة ثقة عالية.';
    } else if (confidence >= 65) {
      message = 'تم التعرف على القراءة، يُرجى مراجعة الخانات والتأكيد.';
    } else {
      message =
          'القراءة مستخرجة بدرجة ثقة منخفضة، تحقّق من الخانات الملونة أو أعد التصوير.';
    }

    return MeterAnalysisResult(
      reading: bestReading,
      confidence: confidence,
      occurrences: bestCount,
      totalAttempts: allCandidates.length,
      isValid: true,
      message: message,
      alternatives: alternatives,
      digitConfidences: digitConfidences,
    );
  }
}
