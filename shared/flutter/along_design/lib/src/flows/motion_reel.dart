import 'package:flutter/material.dart';

import '../motion.dart';
import 'flow_stages.dart';
import 'journey_stages.dart';

/// Fifteen seconds of the ride, on the screens a rider actually sees.
///
/// The quote card springs up over the Abuja tiles and the corridor draws in
/// while the total counts to the quoted fare. The cabin then selects the
/// front-right seat. The rating screen draws the arrival check.
class AlongMotionReel extends StatefulWidget {
  const AlongMotionReel({super.key});

  static const length = Duration(seconds: 15);

  @override
  State<AlongMotionReel> createState() => _AlongMotionReelState();
}

class _ReelCue {
  const _ReelCue({
    required this.beat,
    required this.sheet,
    required this.route,
    required this.count,
    required this.seat,
  });

  final int beat;
  final bool sheet;
  final double route;
  final bool count;
  final String? seat;

  @override
  bool operator ==(Object other) {
    return other is _ReelCue &&
        other.beat == beat &&
        other.sheet == sheet &&
        other.route == route &&
        other.count == count &&
        other.seat == seat;
  }

  @override
  int get hashCode => Object.hash(beat, sheet, route, count, seat);
}

class _AlongMotionReelState extends State<AlongMotionReel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  _ReelCue _cue = const _ReelCue(
    beat: 0,
    sheet: false,
    route: 0,
    count: false,
    seat: null,
  );

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: AlongMotionReel.length)
      ..addListener(_onTick)
      ..forward();
  }

  void _onTick() {
    final next = _cueAt(_clock.value * 15);
    if (next == _cue) return;
    setState(() => _cue = next);
  }

  _ReelCue _cueAt(double t) {
    if (t < 5) {
      return _ReelCue(
        beat: 0,
        sheet: t >= 0.28,
        route: t >= 0.42 ? 1 : 0,
        count: t >= 0.28,
        seat: null,
      );
    }
    if (t < 10) {
      return _ReelCue(
        beat: 1,
        sheet: true,
        route: 1,
        count: true,
        seat: t >= 6.3 ? 'fr' : null,
      );
    }
    return const _ReelCue(
      beat: 2,
      sheet: true,
      route: 1,
      count: true,
      seat: 'fr',
    );
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cue = _cue;
    final Widget screen = switch (cue.beat) {
      0 => AlongFlowQuote(
        key: const ValueKey('reel_quote'),
        revealSheet: cue.sheet,
        routeProgress: cue.route,
        fareClock: cue.count ? _clock : null,
      ),
      1 => AlongFlowSeats(
        key: const ValueKey('reel_seats'),
        selectedSeatId: cue.seat,
      ),
      _ => const AlongFlowRating(key: ValueKey('reel_rating')),
    };
    return AnimatedSwitcher(
      duration: AlongDurations.fade,
      switchInCurve: AlongCurves.fade,
      switchOutCurve: AlongCurves.fade,
      child: screen,
    );
  }
}
