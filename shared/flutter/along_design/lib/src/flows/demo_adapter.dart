import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../palette.dart';
import '../type.dart';

/// Simulated dispatch, GPS, and payment. The gallery and debug builds read
/// this. A live build would swap in the network adapters and hide the mark.
class DemoLandmark {
  const DemoLandmark({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
}

class DemoQuote {
  const DemoQuote({
    required this.baseMinor,
    required this.seatMinor,
    required this.feesMinor,
    required this.walletCreditMinor,
    required this.expiresIn,
    required this.cancelTerms,
  });

  final int baseMinor;
  final int seatMinor;
  final int feesMinor;
  final int walletCreditMinor;
  final Duration expiresIn;
  final String cancelTerms;

  int get totalMinor => baseMinor + seatMinor + feesMinor - walletCreditMinor;
}

class DemoGps {
  const DemoGps({
    required this.etaLowMin,
    required this.etaHighMin,
    required this.age,
    required this.approximate,
  });

  final int etaLowMin;
  final int etaHighMin;
  final Duration age;
  final bool approximate;

  String get etaLabel => '$etaLowMin-$etaHighMin min';

  String get ageLabel => 'Updated ${age.inSeconds}s ago';
}

class DemoPayment {
  const DemoPayment({required this.ok, required this.label});

  final bool ok;
  final String label;
}

class DemoNotice {
  const DemoNotice(this.label);

  final String label;
}

class DemoManeuver {
  const DemoManeuver({
    required this.street,
    required this.meters,
    required this.speedKmh,
  });

  final String street;
  final int meters;
  final int speedKmh;

  String get distanceLabel => '$meters m';

  String get speedLabel => '$speedKmh km/h';
}

/// Named stand-in for GPS, dispatch, and payment. Every figure it returns
/// is scripted.
class DemoAdapter {
  const DemoAdapter();

  static const name = 'DemoAdapter';

  static const detected = DemoLandmark(
    id: 'detected',
    label: 'Wuse Market',
    lat: 9.0742,
    lng: 7.4618,
  );

  static const landmarks = <DemoLandmark>[
    DemoLandmark(
      id: 'gate2',
      label: 'Wuse Market Gate 2',
      lat: 9.0761,
      lng: 7.4634,
    ),
    DemoLandmark(
      id: 'gate4',
      label: 'Wuse Market Gate 4',
      lat: 9.0718,
      lng: 7.4662,
    ),
    DemoLandmark(
      id: 'banex',
      label: 'Banex entrance',
      lat: 9.0694,
      lng: 7.4588,
    ),
  ];

  static const quote = DemoQuote(
    baseMinor: 1200,
    seatMinor: 400,
    feesMinor: 100,
    walletCreditMinor: 200,
    expiresIn: Duration(minutes: 1, seconds: 48),
    cancelTerms: 'Free cancel before arrival',
  );

  static const gps = DemoGps(
    etaLowMin: 4,
    etaHighMin: 6,
    age: Duration(seconds: 40),
    approximate: true,
  );

  static const payment = DemoPayment(ok: false, label: 'Demo payment');

  static const pin = '4821';

  /// Frozen window. The rider screen must not tick during a golden.
  static const pinFor = Duration(minutes: 1, seconds: 48);

  /// Scripted turn on the neighborhood street the nav camera locks to.
  static const maneuver = DemoManeuver(
    street: 'Obafemi Awolowo Way',
    meters: 180,
    speedKmh: 32,
  );

  static const notices = <DemoNotice>[
    DemoNotice('Location denied'),
    DemoNotice('Location is approximate'),
    DemoNotice('Offline · poor network'),
    DemoNotice('Driver cancelled the trip'),
    DemoNotice('Quote changed · review it'),
    DemoNotice('Payment failed'),
    DemoNotice('Welcome back'),
  ];

  /// Nearest entrance within [maxMeters]. Null keeps a dropped pin.
  static DemoLandmark? snap(double lat, double lng, {double maxMeters = 120}) {
    DemoLandmark? best;
    var bestMeters = maxMeters;
    for (final mark in landmarks) {
      final meters = _meters(lat, lng, mark.lat, mark.lng);
      if (meters < bestMeters) {
        best = mark;
        bestMeters = meters;
      }
    }
    return best;
  }

  static double _meters(double lat1, double lng1, double lat2, double lng2) {
    const earth = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}

/// Visible only in debug builds, including widget tests.
class AlongDemoMark extends StatelessWidget {
  const AlongDemoMark({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final palette = AlongPalette.of(context);
    return Semantics(
      key: const Key('demo_adapter'),
      label: DemoAdapter.name,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: palette.ink.withValues(alpha: 0.14),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Demo',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
