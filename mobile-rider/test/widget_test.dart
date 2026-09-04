import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/main.dart';

void main() {
  testWidgets('Along Rider bootstrap', (tester) async {
    await tester.pumpWidget(const AlongRiderApp());
    expect(find.text('Along Rider'), findsOneWidget);
  });
}
