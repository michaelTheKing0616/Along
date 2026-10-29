import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/fake_along_supabase.dart';

const _rider = User(
  id: 'rider-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-10-29T00:00:00Z',
);

const _draft = IncidentReportDraft(
  clientRef: 'ref-1',
  type: 'safety',
  description: 'strange road',
  tripId: 'trip-1',
  photoPaths: ['/tmp/a.jpg', '/tmp/b.jpg'],
);

Future<List<int>> _bytes(String _) async => const [1, 2, 3];

void main() {
  test('client refs are v4 UUIDs', () {
    final ref = newIncidentClientRef();
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(ref),
      isTrue,
    );
    expect(newIncidentClientRef(), isNot(ref));
  });

  test(
    'uploads photos under the rider folder, then files the report',
    () async {
      final uploads = <String>[];
      final gateway = FakeAlongSupabase(
        uploadHandler: (bucket, path) async => uploads.add('$bucket/$path'),
        rpcHandler: (fn, params) => {'incident_id': 'i-1'},
      )..user = _rider;
      final progress = <String>[];
      final reporter = IncidentReporter(
        gateway: gateway,
        safety: SafetyRepository(gateway),
        queue: PendingActionQueue(AlongDatabase.memory()),
        readBytes: _bytes,
      );

      final outcome = await reporter.submit(
        _draft,
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(outcome, IncidentDelivery.sent);
      expect(uploads, [
        'incidents/rider-1/ref-1-0.jpg',
        'incidents/rider-1/ref-1-1.jpg',
      ]);
      expect(progress, ['0/2', '1/2', '2/2']);
      final call = gateway.rpcCalls.single;
      expect(call.$1, 'report_incident');
      expect(call.$2['p_attachment_paths'], uploads);
      expect(call.$2['p_client_ref'], 'ref-1');
      expect(await reporter.hasPending(), isFalse);
    },
  );

  test('offline upload queues the draft; replay sends it once', () async {
    var online = false;
    final gateway = FakeAlongSupabase(
      uploadHandler: (bucket, path) async {
        if (!online) throw Exception('SocketException: offline');
      },
      rpcHandler: (fn, params) => {'incident_id': 'i-1'},
    )..user = _rider;
    final queue = PendingActionQueue(AlongDatabase.memory());
    final reporter = IncidentReporter(
      gateway: gateway,
      safety: SafetyRepository(gateway),
      queue: queue,
      readBytes: _bytes,
    );

    expect(await reporter.submit(_draft), IncidentDelivery.queued);
    expect(await reporter.hasPending(), isTrue);
    expect(gateway.rpcCalls, isEmpty);
    expect(
      queuedDeliveryFor(IncidentReporter.actionType),
      QueuedDelivery.sendsWhenOnline,
    );

    online = true;
    expect(await reporter.flush(), 1);
    expect(await reporter.hasPending(), isFalse);
    expect(gateway.rpcCalls.single.$2['p_client_ref'], 'ref-1');
  });

  test('validation failure is not queued', () async {
    final gateway = FakeAlongSupabase(
      rpcHandler: (fn, params) => throw const AlongException(
        code: AlongErrorCode.validation,
        message: 'photo not uploaded',
      ),
    )..user = _rider;
    final reporter = IncidentReporter(
      gateway: gateway,
      safety: SafetyRepository(gateway),
      queue: PendingActionQueue(AlongDatabase.memory()),
      readBytes: _bytes,
    );
    await expectLater(reporter.submit(_draft), throwsA(isA<AlongException>()));
    expect(await reporter.hasPending(), isFalse);
  });

  test('more than four photos is refused before any upload', () async {
    var uploads = 0;
    final gateway = FakeAlongSupabase(
      uploadHandler: (bucket, path) async => uploads++,
    )..user = _rider;
    final reporter = IncidentReporter(
      gateway: gateway,
      safety: SafetyRepository(gateway),
      queue: PendingActionQueue(AlongDatabase.memory()),
      readBytes: _bytes,
    );
    final big = IncidentReportDraft(
      clientRef: 'r',
      type: 'other',
      description: '',
      photoPaths: List.filled(5, '/tmp/x.jpg'),
    );
    await expectLater(reporter.submit(big), throwsA(isA<AlongException>()));
    expect(uploads, 0);
  });
}
