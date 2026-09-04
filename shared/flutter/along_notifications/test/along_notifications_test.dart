import 'package:along_notifications/along_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PushDeepLinkRouter maps trip request to along:// URI', () {
    const router = PushDeepLinkRouter();
    final link = router.routeFor(
      PushMessage.fromData({'type': 'trip_request', 'trip_id': 'abc'}),
    );
    expect(link, 'along://trip/abc');
  });

  test('PushMessage identifies driver request', () {
    final message = PushMessage.fromData({'type': 'trip_request', 'trip_id': 't1'});
    expect(message.isDriverRequest, isTrue);
  });
}
