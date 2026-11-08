import 'package:flutter_test/flutter_test.dart';
import 'package:my_water/ocr/ai_meter_response.dart';

void main() {
  test('accepts exact digit strings in supported numeral systems', () {
    expect(parseAiMeterResponse('{"reading":"٠٦٥٠٠٤٠","digit_count":7,"confidence":0.95}'), '0650040');
    expect(parseAiMeterResponse('```json\n{"reading":"۰۶۵۰۰۴","digit_count":6,"confidence":0.9}\n```'), '065004');
    expect(parseAiMeterResponse('{"reading":"O65OO4O","digit_count":7,"confidence":0.9}'), '0650040');
  });

  test('rejects uncertain, inconsistent, partial or excessive readings', () {
    expect(parseAiMeterResponse('{"reading":"0650040","digit_count":7,"confidence":0.4}'), isNull);
    expect(parseAiMeterResponse('{"reading":"0650040","digit_count":6,"confidence":0.99}'), isNull);
    expect(parseAiMeterResponse('{"reading":"0650040","digit_count":7}'), isNull);
    expect(parseAiMeterResponse('{"reading":"06500400","digit_count":8,"confidence":0.99}'), isNull);
    expect(parseAiMeterResponse('{"reading":"0650040","digit_count":7,"confidence":0.99}', expectedDigits: 6), isNull);
  });

  test('never harvests digits from prose or malformed JSON', () {
    expect(parseAiMeterResponse('reading: 0650040'), isNull);
    expect(parseAiMeterResponse('{"reading":"0650040", "confidence": 0.99'), isNull);
    expect(parseAiMeterResponse('{"reading":"serial 0650040","digit_count":7,"confidence":0.99}'), isNull);
    expect(parseAiMeterResponse('{"reading":650040,"digit_count":6,"confidence":0.99}'), isNull);
    expect(parseAiMeterResponse('{"reading":"065004.0","digit_count":7,"confidence":0.99}'), isNull);
  });
}
