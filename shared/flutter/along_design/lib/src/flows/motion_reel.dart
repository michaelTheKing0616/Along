import 'package:flutter/material.dart';

import '../components/seat_map.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'delights.dart';
import 'live_arrival.dart';
import 'map_sketch.dart';
import 'spring_sheet.dart';

/// Fifteen seconds of the ride motions, in one frame.
///
/// Sheet spring, seat select, fare count-up, arrival check, and the route
/// draw. The gallery stays on rest poses. This reel is the recording.
class AlongMotionReel extends StatefulWidget {
  const AlongMotionReel({super.key});

  @override
  State<AlongMotionReel> createState() => _AlongMotionReelState();
}

class _AlongMotionReelState extends State<AlongMotionReel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  var _fare = 1200;
  var _held = false;
  var _arrived = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();
    _clock.addListener(_cue);
  }

  void _cue() {
    final t = _clock.value * 15;
    var held = _held;
    var fare = _fare;
    var arrived = _arrived;
    if (!held && t >= 4) held = true;
    if (fare == 1200 && t >= 7) fare = 6400;
    if (fare == 6400 && t >= 9.5) fare = 18400;
    if (!arrived && t >= 12) arrived = true;
    if (held == _held && fare == _fare && arrived == _arrived) return;
    setState(() {
      _held = held;
      _fare = fare;
      _arrived = arrived;
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final t = _clock.value * 15;
    final drawn = (t / 3.2).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFE6E7EA))),
          Positioned.fill(
            child: AlongMapSketch(
              progress: drawn,
              showRoute: true,
              showVehicle: drawn > 0.02,
            ),
          ),
          AlongSpringSheet(
            fraction: 0.48,
            child: _ReelSheet(held: _held, fare: _fare, arrived: _arrived),
          ),
        ],
      ),
    );
  }
}

class _ReelSheet extends StatelessWidget {
  const _ReelSheet({
    required this.held,
    required this.fare,
    required this.arrived,
  });

  final bool held;
  final int fare;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wuse to Nyanya', style: AlongType.title(palette)),
        const SizedBox(height: 8),
        SeatMap(
          body: 'sedan',
          onSeatTap: (_) {},
          rows: [
            SeatMapRowView(
              id: 'front',
              seats: [
                SeatMapSeat(
                  id: 'a',
                  label: 'A',
                  role: 'passenger',
                  status: held ? 'yours' : 'open',
                  statusWord: held ? 'Yours' : 'Open',
                ),
                const SeatMapSeat(
                  id: 'b',
                  label: 'B',
                  role: 'passenger',
                  status: 'open',
                  statusWord: 'Open',
                ),
              ],
            ),
          ],
        ),
        AlongOdometer(
          value: fare,
          style: AlongType.numeric(palette).copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        if (arrived) const AlongArrivalMark() else const SizedBox(height: 28),
      ],
    );
  }
}
