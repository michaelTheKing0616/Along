import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../craft.dart';
import '../palette.dart';

/// A polished light band that drifts across a hero card or primary button
/// as the page scrolls or the phone tilts, like metal catching room light.
///
/// Dark mode only. One static gradient on the foreground layer, repainted
/// (never rebuilt) from the scroll position and a shared, throttled tilt
/// signal. Under reduce-motion the band is parked and no sensor is read.
/// Peak alpha stays under 10% and motion follows the hand, never a timer,
/// so it cannot flash.
class AlongShimmer extends StatefulWidget {
  const AlongShimmer({
    super.key,
    required this.child,
    this.corner = 16,
    this.rim = false,
    this.strength = 1,
  });

  final Widget child;
  final double corner;

  /// Also paint the specular rim, for heroes that bring their own fill.
  final bool rim;

  /// Band brightness multiplier (1 = 7% peak).
  final double strength;

  @override
  State<AlongShimmer> createState() => _AlongShimmerState();
}

class _AlongShimmerState extends State<AlongShimmer> {
  ScrollPosition? _position;
  bool _tilting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position = Scrollable.maybeOf(context)?.position;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final want =
        !still && AlongPalette.of(context).brightness == Brightness.dark;
    if (want != _tilting) {
      _tilting = want;
      want ? AlongTilt.acquire() : AlongTilt.release();
    }
  }

  @override
  void dispose() {
    if (_tilting) AlongTilt.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AlongPalette.of(context).brightness == Brightness.dark;
    if (!dark) return widget.child;
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _SheenPainter(
          position: _tilting ? _position : null,
          tilt: _tilting ? AlongTilt.value : null,
          corner: widget.corner,
          rim: widget.rim,
          strength: widget.strength,
        ),
        child: widget.child,
      ),
    );
  }
}

/// One accelerometer subscription shared by every shimmer on screen.
/// Sampled at ~15 Hz, low-passed, and only published when the change is
/// visible, so a phone at rest causes zero repaints.
abstract final class AlongTilt {
  static final ValueNotifier<double> value = ValueNotifier(0);
  static StreamSubscription<AccelerometerEvent>? _sub;
  static int _users = 0;
  static double _smooth = 0;

  static bool get _supported {
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static void acquire() {
    _users++;
    if (_sub != null || !_supported) return;
    _sub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 66),
        ).listen(
          (e) {
            final x = (e.x / 9.8).clamp(-1.0, 1.0);
            _smooth += (x - _smooth) * 0.2;
            if ((_smooth - value.value).abs() > 0.015) value.value = _smooth;
          },
          onError: (Object _) => _stop(),
          cancelOnError: true,
        );
  }

  static void release() {
    _users--;
    if (_users <= 0) _stop();
  }

  static void _stop() {
    _users = _users < 0 ? 0 : _users;
    _sub?.cancel();
    _sub = null;
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter({
    this.position,
    this.tilt,
    required this.corner,
    required this.rim,
    required this.strength,
  }) : super(repaint: Listenable.merge([?position, ?tilt]));

  final ScrollPosition? position;
  final ValueListenable<double>? tilt;
  final double corner;
  final bool rim;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final pixels = position?.hasPixels == true ? position!.pixels : 0.0;
    // Parked at 0.35; scroll walks it across, tilt leans it +-0.3.
    final t =
        0.35 +
        ((pixels % 600) / 600) * 1.4 * (pixels == 0 ? 0 : 1) +
        (tilt?.value ?? 0) * 0.3;
    final c = ((t + 0.2) % 1.4) - 0.2;
    const white = Color(0xFFFFFFFF);
    final peak = (0.07 * strength).clamp(0.0, 0.12);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: [
        (c - 0.16).clamp(0.0, 1.0),
        (c - 0.02).clamp(0.0, 1.0),
        (c + 0.02).clamp(0.0, 1.0),
        (c + 0.16).clamp(0.0, 1.0),
      ],
      colors: [
        white.withValues(alpha: 0),
        white.withValues(alpha: peak),
        white.withValues(alpha: peak),
        white.withValues(alpha: 0),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawPath(
      AlongCraft.path(Offset.zero & size, corner),
      Paint()..shader = shader,
    );
    if (rim) {
      AlongSpecularBorder(AlongCraft.border(corner))
          .paint(canvas, Offset.zero & size);
    }
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.position != position ||
      old.tilt != tilt ||
      old.strength != strength ||
      old.corner != corner;
}
