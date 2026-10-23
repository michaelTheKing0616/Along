/// Client trip lifecycle. The server still owns `trip_transition` once a
/// trip row exists. Phases before `requested` (pickup, quote, matching)
/// live only on the device. See `docs/flows.md`.
sealed class TripPhase {
  const TripPhase();

  String get name;
}

final class TripIdle extends TripPhase {
  const TripIdle();

  @override
  String get name => 'idle';
}

final class TripPickupPhase extends TripPhase {
  const TripPickupPhase({required this.landmarkId, required this.snapped});

  final String landmarkId;
  final bool snapped;

  @override
  String get name => 'pickup';
}

final class TripQuotePhase extends TripPhase {
  const TripQuotePhase({required this.totalMinor, required this.expiresIn});

  final int totalMinor;
  final Duration expiresIn;

  bool get lapsed => expiresIn <= Duration.zero;

  @override
  String get name => 'quote';
}

final class TripMatchingPhase extends TripPhase {
  const TripMatchingPhase({this.radiusM = 800, this.mode = 'car'});

  final int radiusM;
  final String mode;

  @override
  String get name => 'matching';
}

final class TripNoDriverPhase extends TripPhase {
  const TripNoDriverPhase({required this.radiusM, required this.mode});

  final int radiusM;
  final String mode;

  @override
  String get name => 'no_driver';
}

final class TripScheduledPhase extends TripPhase {
  const TripScheduledPhase(this.whenLabel);

  final String whenLabel;

  @override
  String get name => 'scheduled';
}

final class TripAssignedPhase extends TripPhase {
  const TripAssignedPhase(this.pin);

  /// Four digits the rider reads and the driver enters.
  final String pin;

  @override
  String get name => 'assigned';
}

final class TripArrivedPhase extends TripPhase {
  const TripArrivedPhase({
    required this.pin,
    this.verified = false,
    this.rejected = false,
  });

  final String pin;
  final bool verified;
  final bool rejected;

  @override
  String get name => 'arrived';
}

final class TripInProgressPhase extends TripPhase {
  const TripInProgressPhase({this.navigating = false});

  final bool navigating;

  @override
  String get name => 'in_progress';
}

final class TripReceiptPhase extends TripPhase {
  const TripReceiptPhase();

  @override
  String get name => 'receipt';
}

final class TripClosedPhase extends TripPhase {
  const TripClosedPhase(this.reason);

  /// `quote_expired`, `quote_changed`, `driver_cancelled`,
  /// `rider_cancelled`, `payment_failed`.
  final String reason;

  @override
  String get name => 'closed';
}

sealed class TripEvent {
  const TripEvent();
}

final class PickupChosen extends TripEvent {
  const PickupChosen(this.landmarkId, {this.snapped = false});

  final String landmarkId;
  final bool snapped;
}

final class QuoteReady extends TripEvent {
  const QuoteReady({required this.totalMinor, required this.expiresIn});

  final int totalMinor;
  final Duration expiresIn;
}

final class QuoteAccepted extends TripEvent {
  const QuoteAccepted();
}

final class QuoteLapsed extends TripEvent {
  const QuoteLapsed();
}

final class QuoteRevised extends TripEvent {
  const QuoteRevised(this.totalMinor);

  final int totalMinor;
}

final class MatchMissed extends TripEvent {
  const MatchMissed();
}

final class RadiusWidened extends TripEvent {
  const RadiusWidened();
}

final class KekeRequested extends TripEvent {
  const KekeRequested();
}

final class RideScheduled extends TripEvent {
  const RideScheduled(this.whenLabel);

  final String whenLabel;
}

final class DriverFound extends TripEvent {
  const DriverFound(this.pin);

  final String pin;
}

final class ArrivalMarked extends TripEvent {
  const ArrivalMarked();
}

final class PinSubmitted extends TripEvent {
  const PinSubmitted(this.code);

  final String code;
}

final class TripBegun extends TripEvent {
  const TripBegun();
}

final class NavOpened extends TripEvent {
  const NavOpened();
}

final class TripFinished extends TripEvent {
  const TripFinished();
}

final class DriverCancelledTrip extends TripEvent {
  const DriverCancelledTrip();
}

final class RiderCancelledTrip extends TripEvent {
  const RiderCancelledTrip();
}

final class PaymentDeclined extends TripEvent {
  const PaymentDeclined();
}

final class TripTransitionException implements Exception {
  TripTransitionException(this.phase, this.event);

  final TripPhase phase;
  final TripEvent event;

  @override
  String toString() =>
      'TripTransitionException(${phase.name} + ${event.runtimeType})';
}

/// Pure reducer. Illegal edges throw. Wrong PIN stays on arrived.
abstract final class TripMachine {
  static TripPhase reduce(TripPhase phase, TripEvent event) {
    return switch ((phase, event)) {
      (TripIdle(), PickupChosen(:final landmarkId, :final snapped)) =>
        TripPickupPhase(landmarkId: landmarkId, snapped: snapped),
      (TripPickupPhase(), PickupChosen(:final landmarkId, :final snapped)) =>
        TripPickupPhase(landmarkId: landmarkId, snapped: snapped),
      (TripPickupPhase(), QuoteReady(:final totalMinor, :final expiresIn)) =>
        TripQuotePhase(totalMinor: totalMinor, expiresIn: expiresIn),
      (TripQuotePhase(:final lapsed), QuoteAccepted()) when !lapsed =>
        const TripMatchingPhase(),
      (TripQuotePhase(), QuoteLapsed()) => const TripClosedPhase(
        'quote_expired',
      ),
      (TripQuotePhase(:final expiresIn), QuoteRevised(:final totalMinor)) =>
        TripQuotePhase(totalMinor: totalMinor, expiresIn: expiresIn),
      (TripMatchingPhase(:final radiusM, :final mode), MatchMissed()) =>
        TripNoDriverPhase(radiusM: radiusM, mode: mode),
      (TripMatchingPhase(), DriverFound(:final pin)) => TripAssignedPhase(pin),
      (TripMatchingPhase(), RiderCancelledTrip()) => const TripClosedPhase(
        'rider_cancelled',
      ),
      (TripNoDriverPhase(:final radiusM, :final mode), RadiusWidened()) =>
        TripMatchingPhase(radiusM: radiusM + 800, mode: mode),
      (TripNoDriverPhase(:final radiusM), KekeRequested()) => TripMatchingPhase(
        radiusM: radiusM,
        mode: 'keke',
      ),
      (TripNoDriverPhase(), RideScheduled(:final whenLabel)) =>
        TripScheduledPhase(whenLabel),
      (TripNoDriverPhase(), RiderCancelledTrip()) => const TripClosedPhase(
        'rider_cancelled',
      ),
      (TripAssignedPhase(:final pin), ArrivalMarked()) => TripArrivedPhase(
        pin: pin,
      ),
      (TripAssignedPhase(), DriverCancelledTrip()) => const TripClosedPhase(
        'driver_cancelled',
      ),
      (TripAssignedPhase(), RiderCancelledTrip()) => const TripClosedPhase(
        'rider_cancelled',
      ),
      (TripArrivedPhase(:final pin), PinSubmitted(:final code)) =>
        TripArrivedPhase(
          pin: pin,
          verified: code == pin && code.length == 4,
          rejected: code != pin || code.length != 4,
        ),
      (TripArrivedPhase(:final verified), TripBegun()) when verified =>
        const TripInProgressPhase(),
      (TripArrivedPhase(), DriverCancelledTrip()) => const TripClosedPhase(
        'driver_cancelled',
      ),
      (TripArrivedPhase(), RiderCancelledTrip()) => const TripClosedPhase(
        'rider_cancelled',
      ),
      (TripInProgressPhase(), NavOpened()) => const TripInProgressPhase(
        navigating: true,
      ),
      (TripInProgressPhase(), TripFinished()) => const TripReceiptPhase(),
      (TripInProgressPhase(), DriverCancelledTrip()) => const TripClosedPhase(
        'driver_cancelled',
      ),
      (TripInProgressPhase(), RiderCancelledTrip()) => const TripClosedPhase(
        'rider_cancelled',
      ),
      (TripReceiptPhase(), PaymentDeclined()) => const TripClosedPhase(
        'payment_failed',
      ),
      _ => throw TripTransitionException(phase, event),
    };
  }
}
