import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_water/ocr/ocr_quality_widgets.dart';

void main() {
  testWidgets('manual entry accepts Arabic digits and preserves zeros', (tester) async {
    String value = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MeterReadingEditor(
          reading: '',
          digitCount: 7,
          previousReading: 100,
          onChanged: (reading) => value = reading,
          onDigitCountChanged: (_) {},
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), '٠٦٥٠٠٤٠');
    await tester.pump();
    expect(value, '0650040');
  });
}
