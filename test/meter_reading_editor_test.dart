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
    expect(find.text('?'), findsNWidgets(7));
    await tester.enterText(find.byType(TextField), '٠٦٥٠٠٤٠');
    await tester.pump();
    expect(value, '0650040');
    expect(find.text('?'), findsNothing);
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('6'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '91');
    await tester.pump();
    expect(value, '91');
    expect(find.text('?'), findsNWidgets(5));
    expect(find.text('9'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
