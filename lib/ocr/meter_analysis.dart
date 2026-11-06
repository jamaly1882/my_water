// ============================================================
// meter_analysis.dart
// تحليل قراءة العداد محليًا مع التصويت الموضعي للخانات (6 أو 7)
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

  /// Number of digits in the recognised reading (6 or 7 when valid).
  int get digitCount => reading.length;

  String get confidenceText {
    if (confidence >= 85) {
      return 'High';
    }
    if (confidence >= 65) {
      return 'Medium';
    }
    return 'Low';
  }

  bool get isHighConfidence {
    return confidence >= 85;
  }
}

// ============================================================
// تحليل نتائج OCR
// ============================================================

class MeterAnalyzer {
  /// Water meters in this project expose either 6 or 7 integer digits.
  /// Fractional (red) drums must never be appended to the billing reading.
  static const int minDigits = 6;
  static const int maxDigits = 7;

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
  // التحقق من 6 أو 7 خانات بالضبط.
  // لا نضيف أصفارًا ولا نقصّ خانات أبدًا.
  // ----------------------------------------------------------

  static bool isValid(String value, {int? expectedDigits}) {
    final String clean = value.trim();
    if (expectedDigits != null) {
      if (expectedDigits != minDigits && expectedDigits != maxDigits) {
        return false;
      }
      return RegExp('^\\d{$expectedDigits}\$').hasMatch(clean);
    }
    return RegExp(r'^\d{6,7}$').hasMatch(clean);
  }

  // ----------------------------------------------------------
  // استخراج المرشحات ذات 6 أو 7 أرقام من سطر أو نص OCR
  // يعالج الفواصل بين الخانات وحدود الإطار المقروءة كـ 1
  // ----------------------------------------------------------

  static List<WeightedOcrCandidate> extractCandidatesFromText(
    String rawText, {
    double baseWeight = 1.0,
    String source = 'ocr',
    int? expectedDigits,
  }) {
    final List<WeightedOcrCandidate> results = <WeightedOcrCandidate>[];
    if (rawText.trim().isEmpty) {
      return results;
    }

    final String normalized = normalizeTextKeepSeparators(rawText);

    bool allowedLength(int length) {
      if (expectedDigits != null) {
        return length == expectedDigits;
      }
      return length == minDigits || length == maxDigits;
    }

    // 1. ستة أو سبعة أرقام متجاورة مباشرة
    final Iterable<RegExpMatch> directMatches =
        RegExp(r'(?<!\d)\d{6,7}(?!\d)').allMatches(normalized);

    for (final match in directMatches) {
      final String candidate = match.group(0)!;
      if (!allowedLength(candidate.length)) continue;
      results.add(
        WeightedOcrCandidate(
          text: candidate,
          weight: baseWeight * 1.25,
          source: '$source-direct',
        ),
      );
    }

    // 2. أرقام مفصولة بمسافات أو فواصل إطارات الخانات
    final Iterable<RegExpMatch> separatedMatches = RegExp(
      r'(?<!\d)(\d(?:[\s.,:;|_/\-\[\]()]*\d){5,6})(?!\d)',
    ).allMatches(normalized);

    for (final match in separatedMatches) {
      final String digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
      if (!allowedLength(digits.length)) continue;
      final bool alreadyDirect = results.any((c) => c.text == digits);
      results.add(
        WeightedOcrCandidate(
          text: digits,
          weight: alreadyDirect ? baseWeight * 0.5 : baseWeight * 1.0,
          source: '$source-separated',
        ),
      );
    }

    // 3. إذا كان السطر كله بعد إزالة غير الأرقام يساوي 6 أو 7 خانات بالضبط
    final String allDigits = normalized.replaceAll(RegExp(r'\D'), '');
    if (allowedLength(allDigits.length) &&
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
  // استخراج أفضل قراءة جزئية (4 أو 5 أرقام) لمساعدة المستخدم
  // عند صعوبة الصورة. لا تُستخدم كفواتير ولا تُكمل بأصفار.
  // ----------------------------------------------------------

  static String extractBestPartialReading(List<String> rawResults) {
    final Map<String, int> partials = <String, int>{};

    for (final raw in rawResults) {
      final String norm = normalizeTextKeepSeparators(raw);
      for (final match in RegExp(r'\d{4,5}').allMatches(norm)) {
        final String d = match.group(0)!;
        partials[d] = (partials[d] ?? 0) + 1;
      }
      final String clean = normalize(raw);
      if (clean.length >= 4 && clean.length <= 5) {
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
    int? expectedDigits,
  }) {
    final List<WeightedOcrCandidate> allCandidates = <WeightedOcrCandidate>[];

    if (weightedCandidates != null) {
      for (final wc in weightedCandidates) {
        final String clean = normalize(wc.text);
        if (isValid(clean, expectedDigits: expectedDigits)) {
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
              expectedDigits: expectedDigits,
            ),
          );
        }
      }
    }

    for (final raw in rawResults) {
      final String clean = normalize(raw);
      if (isValid(clean, expectedDigits: expectedDigits)) {
        allCandidates.add(
          WeightedOcrCandidate(
            text: clean,
            weight: 1.0,
            source: 'raw',
          ),
        );
      } else {
        allCandidates.addAll(
          extractCandidatesFromText(
            raw,
            baseWeight: 0.9,
            expectedDigits: expectedDigits,
          ),
        );
      }
    }

    // --------------------------------------------------------
    // لا توجد قراءة من 6 أو 7 أرقام
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
            ? 'Only part of the reading ($partial) was recognised. Re-crop to the full 6 or 7 digit window or enter the missing digits.'
            : 'No clear 6 or 7 digit meter reading was found.',
      );
    }

    // نحلّل كل طول على حدة حتى لا تختلط خانة من قراءة 6 بأخرى من 7.
    final Map<int, List<WeightedOcrCandidate>> byLength =
        <int, List<WeightedOcrCandidate>>{};
    for (final candidate in allCandidates) {
      byLength.putIfAbsent(candidate.text.length, () => []).add(candidate);
    }

    final List<_LengthAnalysis> lengthAnalyses = <_LengthAnalysis>[];
    for (final entry in byLength.entries) {
      lengthAnalyses.add(
        _analyzeLength(
          entry.value,
          digitCount: entry.key,
          previousReading: previousReading,
        ),
      );
    }

    lengthAnalyses.sort((a, b) {
      final int scoreCmp = b.selectionScore.compareTo(a.selectionScore);
      if (scoreCmp != 0) return scoreCmp;
      return b.result.confidence.compareTo(a.result.confidence);
    });

    final _LengthAnalysis best = lengthAnalyses.first;
    final List<String> alternatives = <String>[
      ...best.result.alternatives,
      for (final other in lengthAnalyses.skip(1))
        if (other.result.reading.isNotEmpty) other.result.reading,
    ];

    String message = best.result.message;
    if (lengthAnalyses.length > 1 &&
        (lengthAnalyses[0].selectionScore - lengthAnalyses[1].selectionScore)
                .abs() <
            4) {
      message =
          'Both 6 and 7 digit candidates were found — confirm the digit count against the photo. $message';
    }

    return MeterAnalysisResult(
      reading: best.result.reading,
      confidence: best.result.confidence,
      occurrences: best.result.occurrences,
      totalAttempts: allCandidates.length,
      isValid: true,
      message: message,
      alternatives: alternatives.take(4).toList(),
      digitConfidences: best.result.digitConfidences,
    );
  }

  static _LengthAnalysis _analyzeLength(
    List<WeightedOcrCandidate> candidates, {
    required int digitCount,
    int? previousReading,
  }) {
    final Map<String, double> candidateScores = <String, double>{};
    final Map<String, int> candidateCounts = <String, int>{};
    final List<Map<String, double>> positionalVotes = List.generate(
      digitCount,
      (_) => <String, double>{},
    );

    double totalWeight = 0;

    for (final item in candidates) {
      final String val = item.text;
      if (val.length != digitCount) continue;

      double w = item.weight;

      // تعزيز المرشحات المنطقية بناءً على القراءة السابقة إن وجدت
      if (previousReading != null && previousReading > 0) {
        final int? parsed = int.tryParse(val);
        if (parsed != null) {
          if (parsed >= previousReading) {
            final int diff = parsed - previousReading;
            if (diff <= 10000) {
              w *= 1.35;
            } else if (diff <= 100000) {
              w *= 1.15;
            }
          } else {
            w *= 0.55;
          }
        }
      }

      candidateScores[val] = (candidateScores[val] ?? 0.0) + w;
      candidateCounts[val] = (candidateCounts[val] ?? 0) + 1;
      totalWeight += w;

      for (int i = 0; i < digitCount; i++) {
        final String d = val[i];
        positionalVotes[i][d] = (positionalVotes[i][d] ?? 0.0) + w;
      }
    }

    // تركيب القراءة التوافقية من التصويت الموضعي
    final StringBuffer consensusBuffer = StringBuffer();
    final List<double> digitConfidences = <double>[];

    for (int i = 0; i < digitCount; i++) {
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
    if (positionalConsensus.length == digitCount) {
      candidateScores[positionalConsensus] =
          (candidateScores[positionalConsensus] ?? 0.0) +
              (totalWeight * 0.22);
      candidateCounts[positionalConsensus] =
          math.max(candidateCounts[positionalConsensus] ?? 1, 1);
    }

    final sortedCandidates = candidateScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final String bestReading = sortedCandidates.first.key;
    final int bestCount = candidateCounts[bestReading] ?? 1;

    final double avgDigitConfidence = digitConfidences.isEmpty
        ? 50.0
        : digitConfidences.reduce((a, b) => a + b) / digitConfidences.length;

    final double frequencyRatio = totalWeight > 0
        ? ((candidateScores[bestReading]! / (totalWeight * 1.22)) * 100.0)
            .clamp(0.0, 100.0)
        : 50.0;

    double confidence = avgDigitConfidence * 0.55 + frequencyRatio * 0.35;

    if (bestCount >= 4) {
      confidence += 10;
    } else if (bestCount >= 2) {
      confidence += 5;
    }

    // قراءة واحدة غير مؤكدة لا يجب أن تظهر كثقة عالية.
    if (candidates.length == 1) {
      confidence = math.min(confidence, 60.0);
    } else if (bestCount == 1) {
      confidence = math.min(confidence, 75.0);
    }

    confidence = confidence.clamp(10.0, 99.0);

    final List<String> alternatives = sortedCandidates
        .map((e) => e.key)
        .where((k) => k != bestReading)
        .take(3)
        .toList();

    String message;
    if (confidence >= 85) {
      message = 'The $digitCount-digit reading was recognised with high confidence.';
    } else if (confidence >= 65) {
      message = 'The $digitCount-digit reading was recognised — review the digits and confirm.';
    } else {
      message =
          'Low-confidence $digitCount-digit reading — check the highlighted digits or retake the photo.';
    }

    final MeterAnalysisResult result = MeterAnalysisResult(
      reading: bestReading,
      confidence: confidence,
      occurrences: bestCount,
      totalAttempts: candidates.length,
      isValid: true,
      message: message,
      alternatives: alternatives,
      digitConfidences: digitConfidences,
    );

    // ترجيح الطول الذي يملك أدلة أكثر وثقة أعلى، دون افتراض 7 دائمًا.
    final double selectionScore =
        confidence + math.min(candidates.length, 8) * 2.0;

    return _LengthAnalysis(result: result, selectionScore: selectionScore);
  }
}

class _LengthAnalysis {
  final MeterAnalysisResult result;
  final double selectionScore;

  const _LengthAnalysis({
    required this.result,
    required this.selectionScore,
  });
}
