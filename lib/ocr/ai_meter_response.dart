import 'dart:convert';

import 'meter_analysis.dart';

/// A vision response is accepted only if it is unambiguous and self-consistent.
/// Model-reported confidence is not a substitute for human review.
String? parseAiMeterResponse(String text, {int? expectedDigits}) {
  var jsonText = text.trim();
  final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', caseSensitive: false)
      .firstMatch(jsonText);
  if (fence != null) jsonText = fence.group(1)!;

  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map || decoded['reading'] is! String) return null;
    final confidence = decoded['confidence'];
    final count = decoded['digit_count'];
    if (confidence is! num || !confidence.isFinite ||
        confidence < 0.85 || confidence > 1 || count is! int) return null;

    final candidate = (decoded['reading'] as String).trim();
    // Do not harvest digits from prose, JSON metadata, decimal readings or
    // multiple numbers. Similar-looking glyphs are accepted only here, in the
    // reading field, not in explanatory text.
    if (!RegExp(r'^[0-9٠-٩۰-۹OoDdQqUIiLl!ZzEAaSsGgTBb\s]+$')
        .hasMatch(candidate)) return null;
    final reading = MeterAnalyzer.normalize(candidate);
    if (!MeterAnalyzer.isValid(reading, expectedDigits: expectedDigits) ||
        count != reading.length) return null;
    return reading;
  } catch (_) {
    return null;
  }
}
