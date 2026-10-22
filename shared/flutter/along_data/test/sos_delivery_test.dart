import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_along_supabase.dart';

void main() {
  test('sosHelpMessage prefers the live share link', () {
    expect(
      sosHelpMessage(
        lat: 9.06,
        lng: 7.49,
        shareUrl: 'https://along.test/s/abc',
      ),
      contains('https://along.test/s/abc'),
    );
    expect(sosHelpMessage(lat: 9.06, lng: 7.49), contains('openstreetmap.org'));
  });

  test('sosContactChannels builds WhatsApp and SMS links', () {
    final channels = sosContactChannels(
      contacts: const [
        EmergencyContact(id: '1', name: 'Ada', phoneE164: '+2348011111111'),
      ],
      message: 'help',
    );
    expect(channels, hasLength(1));
    expect(
      channels.single.whatsappUrl,
      'https://wa.me/2348011111111?text=help',
    );
    expect(channels.single.smsUri, 'sms:+2348011111111?body=help');
  });

  test('normalizeEmergencyPhone accepts E.164 and Nigerian local form', () {
    expect(normalizeEmergencyPhone('+2348012345678'), '+2348012345678');
    expect(normalizeEmergencyPhone('08012345678'), '+2348012345678');
    expect(normalizeEmergencyPhone('2348012345678'), '+2348012345678');
    expect(normalizeEmergencyPhone('not-a-phone'), isNull);
  });

  test(
    'coordinator queues connectivity failures and rejects forbidden',
    () async {
      final db = AlongDatabase.memory();
      final outbox = SosOutbox(PendingActionQueue(db));
      final request = const SosRaiseRequest(tripId: 'trip-1', lat: 9, lng: 7);

      final forbidden = FakeAlongSupabase(
        rpcHandler: (fn, params) {
          throw const AlongException(
            code: AlongErrorCode.forbidden,
            message: 'FORBIDDEN',
          );
        },
      );
      final denied = SosRaiseCoordinator(
        repository: SafetyRepository(forbidden),
        outbox: outbox,
      );
      await expectLater(
        denied.submit(request),
        throwsA(
          isA<AlongException>().having(
            (error) => error.code,
            'code',
            AlongErrorCode.forbidden,
          ),
        ),
      );
      expect(await outbox.hasPending(), isFalse);

      var calls = 0;
      final flaky = FakeAlongSupabase(
        rpcHandler: (fn, params) {
          calls += 1;
          if (fn == 'raise_sos' && calls == 1) {
            throw Exception('offline');
          }
          return {
            'sos_id': 'sos-1',
            'emergency_number': '112',
            'share_url': 'https://along.test/s/abc',
          };
        },
      );
      final coordinator = SosRaiseCoordinator(
        repository: SafetyRepository(flaky),
        outbox: outbox,
      );
      final queued = await coordinator.submit(request);
      expect(queued.isQueued, isTrue);
      expect(await outbox.hasPending(), isTrue);

      final sent = await coordinator.flushPending();
      expect(sent.isQueued, isFalse);
      expect(sent.result?.sosId, 'sos-1');
      expect(sent.result?.shareUrl, 'https://along.test/s/abc');
      expect(await outbox.hasPending(), isFalse);
    },
  );

  test('emergency contact cache round-trips', () async {
    final db = AlongDatabase.memory();
    final store = EmergencyContactStore(db);
    expect(await store.read(), isEmpty);
    await store.write(const [
      EmergencyContact(id: 'c1', name: 'Ada', phoneE164: '+2348011111111'),
    ]);
    final read = await store.read();
    expect(read, hasLength(1));
    expect(read.single.name, 'Ada');
    expect(read.single.phoneE164, '+2348011111111');
  });
}
