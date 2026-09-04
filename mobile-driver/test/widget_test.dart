import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/main.dart';

void main() {
  testWidgets('Along Driver bootstrap', (tester) async {
    await tester.pumpWidget(const AlongDriverApp());
    expect(find.text('Along Driver'), findsOneWidget);
  });
}
