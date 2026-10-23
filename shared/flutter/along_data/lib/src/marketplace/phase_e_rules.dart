import 'package:along_data/src/safety/phase_d_rules.dart';

/// Safety ceiling for an anchored counter. A city may set a tighter band.
const anchoredPercentCap = 20;

const anchoredTimeoutMinSeconds = 5;
const anchoredTimeoutMaxSeconds = 30;

/// ~440 m, the same scale as an H3 resolution-8 cell.
const marketplaceCellDegrees = 0.004;

/// One counter around the graph fare. Null when the city has not turned it on.
class AnchoredWindow {
  const AnchoredWindow({
    required this.anchorMinor,
    required this.lowMinor,
    required this.highMinor,
    required this.timeoutSeconds,
    required this.percent,
  });

  final int anchorMinor;
  final int lowMinor;
  final int highMinor;
  final int timeoutSeconds;
  final int percent;
}

class FareSample {
  const FareSample({
    required this.hour,
    required this.amountMinor,
    required this.kind,
  });

  final int hour;
  final int amountMinor;

  /// `paid` feeds the crowd median. `dispute` never does.
  final String kind;
}

class FareShield {
  const FareShield({
    required this.medianMinor,
    required this.samples,
    required this.confidence,
    required this.showComparison,
    required this.aboveUsual,
  });

  final int? medianMinor;
  final int samples;
  final double? confidence;
  final bool showComparison;
  final bool aboveUsual;
}

class WeatherFare {
  const WeatherFare({
    required this.amountMinor,
    required this.applied,
    this.reason,
  });

  final int amountMinor;
  final bool applied;
  final String? reason;
}

class GoalProgress {
  const GoalProgress({
    required this.targetMinor,
    required this.earnedMinor,
    required this.seatsLeft,
  });

  final int targetMinor;
  final int earnedMinor;
  final int seatsLeft;
}

class CorridorDemand {
  const CorridorDemand({required this.label, required this.requests});

  final String label;
  final int requests;
}

class FuelNote {
  const FuelNote({
    required this.label,
    required this.priceNaira,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double priceNaira;
  final double lat;
  final double lng;
}

class StageVehicle {
  const StageVehicle({
    required this.driverId,
    required this.name,
    required this.plate,
    required this.seatsFree,
    required this.seatsTotal,
    required this.startedAt,
    this.verified = false,
  });

  final String driverId;
  final String name;
  final String plate;
  final int seatsFree;
  final int seatsTotal;
  final DateTime startedAt;
  final bool verified;
}

class MatchCandidate {
  const MatchCandidate({
    required this.driverId,
    required this.cell,
    required this.seatsFree,
    required this.trust,
  });

  final String driverId;
  final String cell;
  final int seatsFree;
  final int trust;
}

class PickupWindow {
  const PickupWindow({required this.starts, required this.ends});

  final DateTime starts;
  final DateTime ends;
}

/// City percent and timeout. Wider than the ceiling is clamped to it.
/// A missing percent or timeout leaves the existing chips in place.
AnchoredWindow? anchoredWindow({
  required int anchorMinor,
  required int? percent,
  required int? timeoutSeconds,
}) {
  if (anchorMinor < 1 || percent == null || percent < 1) return null;
  if (timeoutSeconds == null) return null;
  if (timeoutSeconds < anchoredTimeoutMinSeconds ||
      timeoutSeconds > anchoredTimeoutMaxSeconds) {
    return null;
  }
  final used = percent > anchoredPercentCap ? anchoredPercentCap : percent;
  final delta = (anchorMinor * used / 100).round();
  return AnchoredWindow(
    anchorMinor: anchorMinor,
    lowMinor: anchorMinor - delta,
    highMinor: anchorMinor + delta,
    timeoutSeconds: timeoutSeconds,
    percent: used,
  );
}

bool anchoredAmountAllowed(AnchoredWindow window, int amountMinor) {
  return amountMinor >= window.lowMinor && amountMinor <= window.highMinor;
}

/// The anchored offer is a single counter.
bool anchoredCounterAllowed(int countersAlready) => countersAlready < 1;

int? medianMinor(List<int> amounts) {
  if (amounts.isEmpty) return null;
  final sorted = [...amounts]..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// Crowd median for this corridor and hour. Disputes are not samples.
/// The comparison stays quiet until the city sets both a sample floor and
/// the confidence at which the shield may speak.
FareShield fairFareShield({
  required int offeredMinor,
  required List<int> paidAmounts,
  required int? minSamples,
  required double? showAt,
}) {
  final median = medianMinor(paidAmounts);
  double? confidence;
  if (minSamples != null && minSamples > 0 && paidAmounts.isNotEmpty) {
    final raw = paidAmounts.length / minSamples;
    confidence = raw > 1 ? 1 : raw;
  }
  final show =
      median != null &&
      confidence != null &&
      showAt != null &&
      confidence + 1e-9 >= showAt;
  return FareShield(
    medianMinor: median,
    samples: paidAmounts.length,
    confidence: confidence,
    showComparison: show,
    aboveUsual: show && offeredMinor > median,
  );
}

/// A dispute is a record. It does not change the fare.
bool disputeChangesFare() => false;

Map<int, int> fareHistoryByHour(List<FareSample> samples) {
  final groups = <int, List<int>>{};
  for (final sample in samples) {
    if (sample.kind != 'paid') continue;
    if (sample.hour < 0 || sample.hour > 23) continue;
    groups.putIfAbsent(sample.hour, () => []).add(sample.amountMinor);
  }
  final history = <int, int>{};
  for (final entry in groups.entries) {
    final median = medianMinor(entry.value);
    if (median != null) history[entry.key] = median;
  }
  return history;
}

/// A weather change needs a reason and a city cap. Otherwise the graph fare stands.
WeatherFare explainWeatherFare({
  required int baseMinor,
  required double? multiplier,
  required String? reason,
  required double? cap,
}) {
  if (multiplier == null || (multiplier - 1).abs() < 0.000001) {
    return WeatherFare(amountMinor: baseMinor, applied: false);
  }
  if (cap == null || cap < 1) {
    return WeatherFare(amountMinor: baseMinor, applied: false);
  }
  final text = reason?.trim() ?? '';
  if (text.isEmpty) {
    return WeatherFare(amountMinor: baseMinor, applied: false);
  }
  var used = multiplier;
  if (used > cap) used = cap;
  if (used < 0) used = 0;
  return WeatherFare(
    amountMinor: (baseMinor * used).round(),
    applied: true,
    reason: text,
  );
}

GoalProgress? dailyGoal({
  required int? targetMinor,
  required int earnedMinor,
  required int? typicalFareMinor,
}) {
  if (targetMinor == null || targetMinor < 1) return null;
  final left = targetMinor - earnedMinor;
  var seats = 0;
  if (left > 0 && typicalFareMinor != null && typicalFareMinor > 0) {
    seats = (left / typicalFareMinor).ceil();
  }
  return GoalProgress(
    targetMinor: targetMinor,
    earnedMinor: earnedMinor,
    seatsLeft: seats,
  );
}

/// The busiest corridor the driver wrote down. Empty demand has no tip.
String? corridorTip(List<CorridorDemand> rows) {
  CorridorDemand? best;
  for (final row in rows) {
    final label = row.label.trim();
    if (label.isEmpty || row.requests < 1) continue;
    if (best == null || row.requests > best.requests) {
      best = CorridorDemand(label: label, requests: row.requests);
    }
  }
  return best?.label;
}

List<FuelNote> cheaperPumps({
  required List<FuelNote> notes,
  required double lat,
  required double lng,
  required double? radiusMeters,
  required double? lastPriceNaira,
}) {
  if (radiusMeters == null || radiusMeters <= 0) return const [];
  final inside = <FuelNote>[];
  for (final note in notes) {
    final metres = distanceMeters(
      lat1: lat,
      lng1: lng,
      lat2: note.lat,
      lng2: note.lng,
    );
    if (metres > radiusMeters) continue;
    if (lastPriceNaira != null && note.priceNaira >= lastPriceNaira) continue;
    inside.add(note);
  }
  inside.sort((a, b) => a.priceNaira.compareTo(b.priceNaira));
  return inside;
}

List<StageVehicle> stageRadarOrder(List<StageVehicle> rows) {
  final copy = [...rows];
  copy.sort((a, b) {
    final seats = a.seatsFree.compareTo(b.seatsFree);
    if (seats != 0) return seats;
    return a.startedAt.compareTo(b.startedAt);
  });
  return copy;
}

String marketplaceCell(
  double lat,
  double lng, {
  double degrees = marketplaceCellDegrees,
}) {
  final latCell = (lat / degrees).floor();
  final lngCell = (lng / degrees).floor();
  return '$latCell:$lngCell';
}

int driverTrustRank({
  required String verifiedStatus,
  required String standing,
  required int ratingCount,
}) {
  if (standing == 'deactivated' ||
      standing == 'matching_paused' ||
      verifiedStatus == 'suspended' ||
      verifiedStatus == 'rejected') {
    return 0;
  }
  final base = switch (verifiedStatus) {
    'verified' => 3,
    'pending' => 2,
    _ => 1,
  };
  return base * 1000 + (ratingCount < 0 ? 0 : ratingCount);
}

/// Same cell, then a favourite, then trust, then a vehicle with a free seat.
List<MatchCandidate> rankMatches({
  required List<MatchCandidate> candidates,
  required String? riderCell,
  required Set<String> favouriteIds,
}) {
  final copy = [...candidates];
  copy.sort((a, b) {
    final cellA = riderCell != null && a.cell == riderCell ? 0 : 1;
    final cellB = riderCell != null && b.cell == riderCell ? 0 : 1;
    if (cellA != cellB) return cellA.compareTo(cellB);
    final favA = favouriteIds.contains(a.driverId) ? 0 : 1;
    final favB = favouriteIds.contains(b.driverId) ? 0 : 1;
    if (favA != favB) return favA.compareTo(favB);
    final trust = b.trust.compareTo(a.trust);
    if (trust != 0) return trust;
    final seats = b.seatsFree.compareTo(a.seatsFree);
    if (seats != 0) return seats;
    return a.driverId.compareTo(b.driverId);
  });
  return copy;
}

bool routeRequestNotifies({required int count, required int? threshold}) {
  if (threshold == null || threshold < 1) return false;
  return count >= threshold;
}

bool pickupEventOpen({
  required DateTime starts,
  required DateTime ends,
  required DateTime now,
}) {
  return !now.isBefore(starts) && now.isBefore(ends);
}
