import 'package:along_core/along_core.dart' show TripSummary;
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/live_trip/presentation/plate_scan_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

import 'support/trip_options_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TripSummary trip;

  setUp(() {
    PlateScanLog.last = null;
    trip = tripSummaryFromFixture(sampleAcceptedTripResponse());
  });

  testWidgets('denied camera keeps the plate tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final confirmed = _Result<bool?>();
    await tester.pumpWidget(
      _app(view: PlateScanDebugView.denied, trip: trip, confirmed: confirmed),
    );
    await tester.tap(find.byKey(const Key('open_scan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plate_scan_denied')), findsOneWidget);
    expect(find.text('I see this plate'), findsOneWidget);
    expect(find.byKey(const Key('meet_vehicle_boarded')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('plate_scan_confirm')));
    await tester.pumpAndSettle();
    expect(confirmed.value, isTrue);
    expect(PlateScanLog.last, isNull);
  });

  testWidgets('a mismatch warns and still lets the rider continue', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final confirmed = _Result<bool?>();
    await tester.pumpWidget(
      _app(view: PlateScanDebugView.mismatch, trip: trip, confirmed: confirmed),
    );
    await tester.tap(find.byKey(const Key('open_scan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plate_scan_mismatch')), findsOneWidget);
    expect(
      find.text('This plate does not match the registered one.'),
      findsOneWidget,
    );
    expect(PlateScanLog.last, 'mismatch');
    expect(PlateScanLog.last, isNot(contains('ABC')));
    expect(PlateScanLog.last, isNot(contains('jpg')));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('plate_scan_report')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report_open')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plate_scan_sos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos_open')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('plate_scan_confirm')));
    await tester.pumpAndSettle();
    expect(confirmed.value, isTrue);
  });

  testWidgets('a clear match continues', (tester) async {
    final confirmed = _Result<bool?>();
    await tester.pumpWidget(
      _app(view: PlateScanDebugView.match, trip: trip, confirmed: confirmed),
    );
    await tester.tap(find.byKey(const Key('open_scan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('plate_scan_match')), findsOneWidget);
    expect(PlateScanLog.last, 'match');
    await tester.tap(find.byKey(const Key('plate_scan_continue')));
    await tester.pumpAndSettle();
    expect(confirmed.value, isTrue);
  });

  testWidgets('the guide frame and torch fit a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        view: PlateScanDebugView.scanning,
        trip: trip,
        confirmed: _Result<bool?>(),
      ),
    );
    await tester.tap(find.byKey(const Key('open_scan')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plate_scan_frame')), findsOneWidget);
    expect(find.byKey(const Key('plate_scan_hint')), findsOneWidget);
    final frame = tester.getSize(find.byKey(const Key('plate_scan_frame')));
    expect(frame.width, 280);
    expect(frame.height, 88);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('plate_scan_torch')));
    await tester.pump();
    expect(find.byIcon(Icons.flashlight_on), findsOneWidget);
  });
}

class _Result<T> {
  T? value;
}

Widget _app({
  required PlateScanDebugView view,
  required TripSummary trip,
  required _Result<bool?> confirmed,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: TextButton(
            key: const Key('open_scan'),
            onPressed: () async {
              confirmed.value = await context.push<bool>(
                AppRoutes.plateScan,
                extra: PlateScanArgs(
                  expectedPlate: trip.vehicle.plateNumber,
                  tripId: trip.tripId,
                  trip: trip,
                  debugView: view,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.plateScan,
        builder: (context, state) =>
            PlateScanScreen(args: state.extra! as PlateScanArgs),
      ),
      GoRoute(
        path: AppRoutes.reportIncident,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Report')),
          body: const Text('report', key: Key('report_open')),
        ),
      ),
      GoRoute(
        path: AppRoutes.sosActive,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('SOS')),
          body: const Text('sos', key: Key('sos_open')),
        ),
      ),
    ],
  );
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}
