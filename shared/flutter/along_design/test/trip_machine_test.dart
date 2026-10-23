import 'package:along_design/along_design.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('happy path runs pickup through receipt', () {
    TripPhase phase = const TripIdle();
    phase = TripMachine.reduce(
      phase,
      const PickupChosen('gate2', snapped: true),
    );
    phase = TripMachine.reduce(
      phase,
      const QuoteReady(totalMinor: 1500, expiresIn: Duration(minutes: 2)),
    );
    phase = TripMachine.reduce(phase, const QuoteAccepted());
    phase = TripMachine.reduce(phase, const DriverFound(DemoAdapter.pin));
    phase = TripMachine.reduce(phase, const ArrivalMarked());
    phase = TripMachine.reduce(phase, const PinSubmitted(DemoAdapter.pin));
    expect((phase as TripArrivedPhase).verified, isTrue);
    phase = TripMachine.reduce(phase, const TripBegun());
    phase = TripMachine.reduce(phase, const NavOpened());
    expect((phase as TripInProgressPhase).navigating, isTrue);
    phase = TripMachine.reduce(phase, const TripFinished());
    expect(phase, isA<TripReceiptPhase>());
  });

  test('a wrong PIN does not start the trip', () {
    final arrived = TripMachine.reduce(
      const TripAssignedPhase(DemoAdapter.pin),
      const ArrivalMarked(),
    );
    final rejected = TripMachine.reduce(arrived, const PinSubmitted('0000'));
    expect((rejected as TripArrivedPhase).rejected, isTrue);
    expect(
      () => TripMachine.reduce(rejected, const TripBegun()),
      throwsA(isA<TripTransitionException>()),
    );
  });

  test('no driver can widen, switch to keke, or schedule', () {
    final missed = TripMachine.reduce(
      const TripMatchingPhase(),
      const MatchMissed(),
    );
    final wider = TripMachine.reduce(missed, const RadiusWidened());
    expect((wider as TripMatchingPhase).radiusM, 1600);

    final keke = TripMachine.reduce(missed, const KekeRequested());
    expect((keke as TripMatchingPhase).mode, 'keke');

    final later = TripMachine.reduce(missed, const RideScheduled('16:30'));
    expect((later as TripScheduledPhase).whenLabel, '16:30');
  });

  test('quote expiry, driver cancel, and payment failure close the trip', () {
    final quote = TripQuotePhase(totalMinor: 1500, expiresIn: Duration.zero);
    expect(
      () => TripMachine.reduce(quote, const QuoteAccepted()),
      throwsA(isA<TripTransitionException>()),
    );
    expect(
      TripMachine.reduce(
        const TripQuotePhase(totalMinor: 1500, expiresIn: Duration(minutes: 1)),
        const QuoteLapsed(),
      ),
      isA<TripClosedPhase>().having(
        (phase) => phase.reason,
        'reason',
        'quote_expired',
      ),
    );
    expect(
      TripMachine.reduce(
        const TripInProgressPhase(),
        const DriverCancelledTrip(),
      ),
      isA<TripClosedPhase>().having(
        (phase) => phase.reason,
        'reason',
        'driver_cancelled',
      ),
    );
    expect(
      TripMachine.reduce(const TripReceiptPhase(), const PaymentDeclined()),
      isA<TripClosedPhase>().having(
        (phase) => phase.reason,
        'reason',
        'payment_failed',
      ),
    );
  });

  test('DemoAdapter snaps to an entrance and ignores a far pin', () {
    expect(DemoAdapter.name, 'DemoAdapter');
    expect(
      DemoAdapter.snap(
        DemoAdapter.landmarks.first.lat,
        DemoAdapter.landmarks.first.lng,
      )?.id,
      'gate2',
    );
    expect(DemoAdapter.snap(8.5, 7.0), isNull);
    expect(DemoAdapter.quote.totalMinor, 1500);
    expect(DemoAdapter.gps.etaLabel, '4-6 min');
    expect(DemoAdapter.gps.ageLabel, 'Updated 40s ago');
  });
}
