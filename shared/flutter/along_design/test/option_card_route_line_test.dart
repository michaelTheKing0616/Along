import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, OptionCard card) => tester.pumpWidget(
    MaterialApp(
      theme: alongTheme(),
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  );

  testWidgets('route line falls back to English', (tester) async {
    await pump(tester, const OptionCard());
    expect(find.text('Board at Lugbe Park → Area 1 Park'), findsOneWidget);
  });

  testWidgets('route line uses the localised override', (tester) async {
    await pump(
      tester,
      const OptionCard(routeLine: 'Wọ̀ ní Lugbe Park → Area 1 Park'),
    );
    expect(find.text('Wọ̀ ní Lugbe Park → Area 1 Park'), findsOneWidget);
    expect(find.textContaining('Board at'), findsNothing);
  });
}
