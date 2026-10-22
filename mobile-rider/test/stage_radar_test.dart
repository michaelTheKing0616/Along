import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/marketplace/presentation/fare_shield_screen.dart';
import 'package:mobile_rider/features/marketplace/presentation/stage_radar_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

void main() {
  testWidgets('the fullest car leaves next and the row has no phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final early = DateTime.utc(2026, 10, 22, 8);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StageRadarScreen(
          rows: [
            StageVehicle(
              driverId: 'b',
              name: 'Ada',
              plate: 'ABC-123XY',
              seatsFree: 4,
              seatsTotal: 6,
              startedAt: early,
            ),
            StageVehicle(
              driverId: 'a',
              name: 'Musa',
              plate: 'KJA-22-AA',
              seatsFree: 1,
              seatsTotal: 6,
              startedAt: early.add(const Duration(minutes: 2)),
              verified: true,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage_leaving_next')), findsOneWidget);
    expect(find.text('1 of 6 free'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.textContaining('+234'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fair fare screen keeps the usual fare after a dispute tap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final window = anchoredWindow(
      anchorMinor: 100000,
      percent: 20,
      timeoutSeconds: 15,
    );
    var disputes = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FareShieldScreen(
          args: FareShieldArgs(
            offeredLabel: '₦1,500',
            usualLabel: 'Usual fare ₦900',
            weatherReason: 'Heavy rain on Nyanya road',
            window: window,
            history: const {7: '₦900'},
            onDispute: () => disputes += 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('One offer, open for 15 seconds'), findsOneWidget);
    expect(find.text('Usual fare ₦900'), findsOneWidget);
    expect(find.text('7:00 · ₦900'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('fair_fare_dispute')));
    await tester.pump();
    expect(disputes, 1);
    expect(find.text('Usual fare ₦900'), findsOneWidget);
  });
}
