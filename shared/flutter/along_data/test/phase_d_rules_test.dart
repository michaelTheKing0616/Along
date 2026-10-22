import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fuzz rejects every trip edge the lifecycle does not list', () {
    const actors = TripActorType.values;
    var legal = 0;
    var illegal = 0;
    for (final from in tripTransitionStatuses) {
      for (final to in tripTransitionStatuses) {
        for (final actor in actors) {
          for (final matchable in [false, true]) {
            for (final isRider in [false, true]) {
              for (final isDriver in [false, true]) {
                final request = TripTransitionRequest(
                  fromStatus: from,
                  toStatus: to,
                  actor: actor,
                  actorIsRider: isRider,
                  actorIsDriver: isDriver,
                  driverMatchable: matchable,
                );
                final allowed = tripTransitionAllowed(request);
                expect(
                  allowed,
                  _listed(request),
                  reason:
                      '$from -> $to by $actor '
                      'rider=$isRider driver=$isDriver matchable=$matchable',
                );
                if (allowed) {
                  legal++;
                } else {
                  illegal++;
                }
              }
            }
          }
        }
      }
    }
    expect(legal, greaterThan(0));
    expect(illegal, greaterThan(legal));
  });

  test('same status is never a transition', () {
    expect(
      tripTransitionAllowed(
        const TripTransitionRequest(
          fromStatus: 'accepted',
          toStatus: 'accepted',
          actor: TripActorType.driver,
          actorIsRider: false,
          actorIsDriver: true,
          driverMatchable: true,
        ),
      ),
      isFalse,
    );
  });

  test('guardian stays quiet until the rider sets a threshold', () {
    expect(
      evaluateGuardian(
        prefs: GuardianPrefs.disabled,
        riderToDriverMeters: 5000,
        stationaryFor: const Duration(hours: 2),
        sinceLastConfirm: const Duration(hours: 2),
        promptOpen: false,
        promptOpenFor: Duration.zero,
      ),
      GuardianPrompt.none,
    );

    expect(
      evaluateGuardian(
        prefs: const GuardianPrefs(enabled: true, offRouteMeters: 80),
        riderToDriverMeters: 120,
        stationaryFor: Duration.zero,
        sinceLastConfirm: Duration.zero,
        promptOpen: false,
        promptOpenFor: Duration.zero,
      ),
      GuardianPrompt.offRoute,
    );
  });

  test('a missed check-in is the open prompt past the rider window', () {
    expect(
      evaluateGuardian(
        prefs: const GuardianPrefs(enabled: true, checkInMinutes: 5),
        riderToDriverMeters: 10,
        stationaryFor: Duration.zero,
        sinceLastConfirm: const Duration(minutes: 6),
        promptOpen: true,
        promptOpenFor: const Duration(minutes: 5),
      ),
      GuardianPrompt.missed,
    );
  });

  test('safe word and five taps stay exact', () {
    expect(safeWordMatches('  Pepper  ', 'pepper'), isTrue);
    expect(safeWordMatches('', 'pepper'), isFalse);
    expect(safeWordMatches('pepper', 'salt'), isFalse);

    final taps = SilentTapSeries();
    final start = DateTime.utc(2026, 10, 22, 12);
    for (var i = 0; i < 4; i++) {
      expect(
        taps.register(start.add(Duration(milliseconds: 200 * i))),
        isFalse,
      );
    }
    expect(taps.register(start.add(const Duration(milliseconds: 800))), isTrue);
    expect(taps.register(start.add(const Duration(seconds: 4))), isFalse);
  });

  test('rest and lost-and-found follow the driver and the 48 hour window', () {
    expect(
      drivingRestDue(driven: const Duration(minutes: 90), driveMinutes: null),
      isFalse,
    );
    expect(
      drivingRestDue(driven: const Duration(minutes: 90), driveMinutes: 60),
      isTrue,
    );
    expect(
      restQualifies(rested: const Duration(minutes: 20), restMinutes: 15),
      isTrue,
    );
    final ended = DateTime.utc(2026, 10, 22, 8);
    expect(
      tripMessageWindowOpen(
        endedAt: ended,
        now: ended.add(const Duration(hours: 48)),
      ),
      isTrue,
    );
    expect(
      tripMessageWindowOpen(
        endedAt: ended,
        now: ended.add(const Duration(hours: 48, seconds: 1)),
      ),
      isFalse,
    );
    expect(tripMessageWindowOpen(endedAt: null, now: ended), isFalse);
  });
}

bool _listed(TripTransitionRequest request) {
  if (request.fromStatus == request.toStatus) return false;
  final party = switch (request.actor) {
    TripActorType.rider => request.actorIsRider,
    TripActorType.driver => request.actorIsDriver,
    TripActorType.system => true,
  };
  if (!party) return false;
  const legal = <(String, String, TripActorType)>{
    ('requested', 'accepted', TripActorType.driver),
    ('requested', 'declined', TripActorType.driver),
    ('requested', 'expired', TripActorType.system),
    ('requested', 'cancelled_by_rider', TripActorType.rider),
    ('accepted', 'cancelled_by_rider', TripActorType.rider),
    ('accepted', 'cancelled_by_driver', TripActorType.driver),
    ('accepted', 'no_show', TripActorType.driver),
    ('accepted', 'released_before_arrival', TripActorType.driver),
    ('accepted', 'boarded', TripActorType.system),
    ('accepted', 'boarded', TripActorType.rider),
    ('accepted', 'boarded', TripActorType.driver),
    ('boarded', 'in_transit', TripActorType.system),
    ('boarded', 'in_transit', TripActorType.driver),
    ('boarded', 'cancelled_by_driver', TripActorType.driver),
    ('boarded', 'cancelled_by_rider', TripActorType.rider),
    ('in_transit', 'completed', TripActorType.driver),
    ('in_transit', 'cancelled_by_driver', TripActorType.driver),
    ('in_transit', 'cancelled_by_rider', TripActorType.rider),
  };
  if (!legal.contains((request.fromStatus, request.toStatus, request.actor))) {
    return false;
  }
  if (request.fromStatus == 'requested' &&
      request.toStatus == 'accepted' &&
      !request.driverMatchable) {
    return false;
  }
  return true;
}
