import 'dart:math' as math;

/// Rider-authored Guardian thresholds. Empty numbers mean that check is off.
class GuardianPrefs {
  const GuardianPrefs({
    this.enabled = false,
    this.offRouteMeters,
    this.longStopMinutes,
    this.checkInMinutes,
    this.safeWord = '',
  });

  final bool enabled;
  final int? offRouteMeters;
  final int? longStopMinutes;
  final int? checkInMinutes;
  final String safeWord;

  static const disabled = GuardianPrefs();

  GuardianPrefs copyWith({
    bool? enabled,
    int? offRouteMeters,
    int? longStopMinutes,
    int? checkInMinutes,
    String? safeWord,
    bool clearOffRoute = false,
    bool clearLongStop = false,
    bool clearCheckIn = false,
  }) {
    return GuardianPrefs(
      enabled: enabled ?? this.enabled,
      offRouteMeters: clearOffRoute
          ? null
          : (offRouteMeters ?? this.offRouteMeters),
      longStopMinutes: clearLongStop
          ? null
          : (longStopMinutes ?? this.longStopMinutes),
      checkInMinutes: clearCheckIn
          ? null
          : (checkInMinutes ?? this.checkInMinutes),
      safeWord: safeWord ?? this.safeWord,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'off_route_m': offRouteMeters,
    'long_stop_minutes': longStopMinutes,
    'check_in_minutes': checkInMinutes,
    'safe_word': safeWord,
  };

  factory GuardianPrefs.fromJson(Map<String, dynamic> json) {
    return GuardianPrefs(
      enabled: json['enabled'] as bool? ?? false,
      offRouteMeters: (json['off_route_m'] as num?)?.toInt(),
      longStopMinutes: (json['long_stop_minutes'] as num?)?.toInt(),
      checkInMinutes: (json['check_in_minutes'] as num?)?.toInt(),
      safeWord: json['safe_word'] as String? ?? '',
    );
  }
}

enum GuardianPrompt { none, offRoute, longStop, checkIn, missed }

/// What the rider should see. Thresholds come only from [prefs].
GuardianPrompt evaluateGuardian({
  required GuardianPrefs prefs,
  required double? riderToDriverMeters,
  required Duration stationaryFor,
  required Duration sinceLastConfirm,
  required bool promptOpen,
  required Duration promptOpenFor,
}) {
  if (!prefs.enabled) return GuardianPrompt.none;
  final checkIn = prefs.checkInMinutes;
  if (promptOpen &&
      checkIn != null &&
      checkIn > 0 &&
      promptOpenFor >= Duration(minutes: checkIn)) {
    return GuardianPrompt.missed;
  }
  final offRoute = prefs.offRouteMeters;
  if (offRoute != null &&
      offRoute > 0 &&
      riderToDriverMeters != null &&
      riderToDriverMeters > offRoute) {
    return GuardianPrompt.offRoute;
  }
  final longStop = prefs.longStopMinutes;
  if (longStop != null &&
      longStop > 0 &&
      stationaryFor >= Duration(minutes: longStop)) {
    return GuardianPrompt.longStop;
  }
  if (checkIn != null &&
      checkIn > 0 &&
      sinceLastConfirm >= Duration(minutes: checkIn)) {
    return GuardianPrompt.checkIn;
  }
  return GuardianPrompt.none;
}

/// The rider's word, compared without case. An empty word never matches.
bool safeWordMatches(String configured, String said) {
  final word = configured.trim().toLowerCase();
  if (word.isEmpty) return false;
  return said.trim().toLowerCase() == word;
}

/// Five taps inside a short window. One tap does nothing.
class SilentTapSeries {
  SilentTapSeries({
    this.requiredTaps = 5,
    this.window = const Duration(seconds: 3),
  });

  final int requiredTaps;
  final Duration window;
  DateTime? _windowStart;
  int _count = 0;

  bool register(DateTime now) {
    final start = _windowStart;
    if (start == null || now.difference(start) > window) {
      _windowStart = now;
      _count = 1;
      return false;
    }
    _count += 1;
    if (_count >= requiredTaps) {
      _windowStart = null;
      _count = 0;
      return true;
    }
    return false;
  }
}

/// Metres between two WGS84 points. Used for the rider's off-route check.
double distanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earth = 6371000.0;
  final lat = ((lat1 + lat2) / 2) * math.pi / 180;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final x = dLng * math.cos(lat);
  return earth * math.sqrt(x * x + dLat * dLat);
}

/// Driver-authored rest lengths. Null means the nudge is off.
class RestPrefs {
  const RestPrefs({this.driveMinutes, this.restMinutes});

  final int? driveMinutes;
  final int? restMinutes;

  Map<String, dynamic> toJson() => {
    'drive_minutes': driveMinutes,
    'rest_minutes': restMinutes,
  };

  factory RestPrefs.fromJson(Map<String, dynamic> json) {
    return RestPrefs(
      driveMinutes: (json['drive_minutes'] as num?)?.toInt(),
      restMinutes: (json['rest_minutes'] as num?)?.toInt(),
    );
  }
}

bool drivingRestDue({required Duration driven, required int? driveMinutes}) {
  if (driveMinutes == null || driveMinutes < 1) return false;
  return driven >= Duration(minutes: driveMinutes);
}

bool restQualifies({required Duration rested, required int? restMinutes}) {
  if (restMinutes == null || restMinutes < 1) return false;
  return rested >= Duration(minutes: restMinutes);
}

/// Lost-and-found stays open for 48 hours after the trip ends.
const tripMessageWindow = Duration(hours: 48);

bool tripMessageWindowOpen({
  required DateTime? endedAt,
  required DateTime now,
}) {
  if (endedAt == null) return false;
  return !now.isAfter(endedAt.add(tripMessageWindow));
}
