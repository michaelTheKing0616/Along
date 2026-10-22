import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('text map lists a heading arrow without tiles at 320dp', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: TextMapBoard(
          title: 'Vehicles nearby',
          emptyLabel: 'None',
          rows: [
            TextMapEntry(
              id: 'keke',
              title: 'Keke toward Wuse',
              detail: '2 free · NE · 4 min',
              heading: 'NE',
            ),
          ],
        ),
      ),
    );
    expect(find.byKey(const Key('text_map_keke')), findsOneWidget);
    expect(find.text('NE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
