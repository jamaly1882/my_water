import 'package:flutter_test/flutter_test.dart';
import 'package:my_water/ocr/meter_analysis.dart';

void main() {
  group('MeterAnalyzer.isValid', () {
    test('accepts exactly 6 or 7 digits and keeps leading zeros', () {
      expect(MeterAnalyzer.isValid('065004'), isTrue);
      expect(MeterAnalyzer.isValid('0650040'), isTrue);
      expect(MeterAnalyzer.isValid('000000'), isTrue);
      expect(MeterAnalyzer.isValid('0000000'), isTrue);
    });

    test('rejects missing or extra digits instead of padding/truncating', () {
      expect(MeterAnalyzer.isValid('65004'), isFalse);
      expect(MeterAnalyzer.isValid('06500400'), isFalse);
      expect(MeterAnalyzer.isValid(''), isFalse);
      expect(MeterAnalyzer.isValid('065 004'), isFalse);
    });

    test('can enforce the meter digit count', () {
      expect(MeterAnalyzer.isValid('065004', expectedDigits: 6), isTrue);
      expect(MeterAnalyzer.isValid('0650040', expectedDigits: 6), isFalse);
      expect(MeterAnalyzer.isValid('0650040', expectedDigits: 7), isTrue);
      expect(MeterAnalyzer.isValid('065004', expectedDigits: 7), isFalse);
      expect(MeterAnalyzer.isValid('065004', expectedDigits: 5), isFalse);
    });
  });

  group('MeterAnalyzer.normalize', () {
    test('normalizes Arabic and Persian digits without dropping zeros', () {
      expect(MeterAnalyzer.normalize('٠٦٥٠٠٤٠'), '0650040');
      expect(MeterAnalyzer.normalize('۰۶۵۰۰۴'), '065004');
    });

    test('maps common OCR letter confusions inside the digit window', () {
      expect(MeterAnalyzer.normalize('O65OO4O'), '0650040');
      expect(MeterAnalyzer.normalize('0 6 5 0 0 4'), '065004');
    });
  });

  group('MeterAnalyzer.extractCandidatesFromText', () {
    test('extracts 6 and 7 digit candidates', () {
      final six = MeterAnalyzer.extractCandidatesFromText('065004');
      final seven = MeterAnalyzer.extractCandidatesFromText('0650040');
      expect(six.map((c) => c.text), contains('065004'));
      expect(seven.map((c) => c.text), contains('0650040'));
    });

    test('extracts separated drums', () {
      final candidates =
          MeterAnalyzer.extractCandidatesFromText('0 6 5 0 0 4 0');
      expect(candidates.map((c) => c.text), contains('0650040'));
    });

    test('does not turn an 8 digit serial number into a 7 digit reading', () {
      final candidates = MeterAnalyzer.extractCandidatesFromText('12345678');
      expect(candidates.where((c) => c.text.length == 7), isEmpty);
    });

    test('respects expectedDigits', () {
      final candidates = MeterAnalyzer.extractCandidatesFromText(
        '065004 0650040',
        expectedDigits: 6,
      );
      expect(candidates.map((c) => c.text), contains('065004'));
      expect(candidates.map((c) => c.text), isNot(contains('0650040')));
    });
  });

  group('MeterAnalyzer.analyze', () {
    test('returns a 6 digit reading without padding to 7', () {
      final result = MeterAnalyzer.analyze(['065004', '065004']);
      expect(result.isValid, isTrue);
      expect(result.reading, '065004');
      expect(result.digitCount, 6);
      expect(result.digitConfidences.length, 6);
    });

    test('returns a 7 digit reading with leading zeros', () {
      final result = MeterAnalyzer.analyze(['0650040', '0650040']);
      expect(result.isValid, isTrue);
      expect(result.reading, '0650040');
      expect(result.digitCount, 7);
      expect(result.digitConfidences.length, 7);
    });

    test('chooses the better supported digit count when both appear', () {
      final result = MeterAnalyzer.analyze([
        '065004',
        '065004',
        '065004',
        '0650040',
      ]);
      expect(result.isValid, isTrue);
      expect(result.reading, '065004');
    });

    test('can force the expected digit count', () {
      final result = MeterAnalyzer.analyze(
        ['065004', '0650040'],
        expectedDigits: 7,
      );
      expect(result.isValid, isTrue);
      expect(result.reading, '0650040');
    });

    test('does not invent a reading from a partial result', () {
      final result = MeterAnalyzer.analyze(['0650']);
      expect(result.isValid, isFalse);
      expect(result.reading, '');
      expect(result.partialReading, isNot('0000650'));
    });

    test('single candidate is not reported as high confidence', () {
      final result = MeterAnalyzer.analyze(['0650040']);
      expect(result.isValid, isTrue);
      expect(result.confidence, lessThan(85));
    });
  });
}
