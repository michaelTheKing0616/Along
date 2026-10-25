import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ride UI is used many times a day, so springs settle inside 300ms.
/// The motion-grammar spring (stiffness 100, damping 20) is the character:
/// a short underdamped settle, scaled up so the sheet does not linger. [emil]
/// Named lengths. Springs live on [AlongSprings]. Nothing else invents a
/// duration. See the motion table in docs/art-direction.md.
abstract final class AlongDurations {
  /// Clock sample for the Na Me countdown. Not a transition.
  static const sample = Duration(milliseconds: 100);

  static const press = Duration(milliseconds: 120);
  static const fade = Duration(milliseconds: 180);
  static const stagger = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 280);

  /// Check stroke and the seat reveal. The rest pose is the finished mark.
  static const draw = Duration(milliseconds: 320);

  /// Shared-element expand. Rest is fully open or fully closed.
  static const expand = Duration(milliseconds: 360);
  static const refresh = Duration(milliseconds: 480);

  /// Splash mark, confetti, and a held value catching up.
  static const glide = Duration(milliseconds: 700);

  /// SOS hold. Distinct from [hold], which is a one-shot status.
  static const sos = Duration(milliseconds: 600);
  static const routeDraw = Duration(milliseconds: 900);

  /// Skeleton and map sheen. Gallery frames hold the rest position.
  static const shimmer = Duration(milliseconds: 1200);
  static const hold = Duration(milliseconds: 1400);
  static const scan = Duration(milliseconds: 1800);

  /// Map radar. It holds a rest pose and does not loop.
  static const radar = Duration(milliseconds: 2200);

  /// Demand glow on the three hot cells. One breath, then back.
  static const breath = Duration(milliseconds: 2400);
}

abstract final class AlongCurves {
  static const fade = Curves.easeOut;
  static const settle = Curves.easeOutCubic;

  /// Breath on the hot cells, and a held value catching up.
  static const breath = Curves.easeInOut;
}

abstract final class AlongSprings {
  static const sheet = SpringDescription(
    mass: 0.7,
    stiffness: 520,
    damping: 32,
  );

  static const route = SpringDescription(
    mass: 0.9,
    stiffness: 280,
    damping: 24,
  );

  /// Cushion press. Short, then back.
  static const press = SpringDescription(
    mass: 0.4,
    stiffness: 640,
    damping: 18,
  );

  /// Seat selection. Underdamped, so the scale returns past 1, then rests.
  static const select = SpringDescription(
    mass: 0.5,
    stiffness: 420,
    damping: 12,
  );

  /// A taken seat shakes once. The caller supplies the velocity.
  static const taken = SpringDescription(
    mass: 0.4,
    stiffness: 520,
    damping: 11,
  );
}

abstract final class AlongMotionPolicy {
  /// Widget tests set this to watch a motion run to its rest pose.
  static bool debugPlayMotion = false;

  static bool reduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static bool get inWidgetTest {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('Test');
  }

  /// Reduced motion always wins. Gallery goldens stay on the rest pose.
  static bool play(BuildContext context) {
    if (reduced(context)) return false;
    if (debugPlayMotion) return true;
    return !inWidgetTest;
  }
}

/// Haptics. The platform call is skipped when motion is reduced and in
/// widget tests, where the channel is absent. [requested] still counts.
abstract final class AlongHaptics {
  static int requested = 0;

  /// Settings toggle. Off skips the platform call and the request count.
  static bool enabled = true;

  static bool _skip(BuildContext context) {
    if (!enabled) return true;
    return AlongMotionPolicy.reduced(context) || AlongMotionPolicy.inWidgetTest;
  }

  static Future<void> tick(BuildContext context) async {
    if (!enabled) return;
    requested++;
    if (_skip(context)) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> selection(BuildContext context) => tick(context);

  static Future<void> confirm(BuildContext context) async {
    if (!enabled) return;
    requested++;
    if (_skip(context)) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> success(BuildContext context) async {
    if (!enabled) return;
    requested++;
    if (_skip(context)) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error(BuildContext context) async {
    if (!enabled) return;
    requested++;
    if (_skip(context)) return;
    await HapticFeedback.heavyImpact();
  }
}

/// Press scale for tappables. The rest pose is the child itself, so a
/// golden frame does not pick up a transform.
class AlongPressable extends StatefulWidget {
  const AlongPressable({super.key, required this.child});

  final Widget child;

  @override
  State<AlongPressable> createState() => _AlongPressableState();
}

class _AlongPressableState extends State<AlongPressable> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AlongMotionPolicy.reduced(context);
    final pressed = _down && (reduced || AlongMotionPolicy.play(context));
    return Listener(
      onPointerDown: (_) {
        if (!_down) setState(() => _down = true);
      },
      onPointerUp: (_) {
        if (_down) setState(() => _down = false);
      },
      onPointerCancel: (_) {
        if (_down) setState(() => _down = false);
      },
      child: !pressed
          ? widget.child
          : reduced
          ? Opacity(opacity: 0.72, child: widget.child)
          : Transform.scale(scale: 0.96, child: widget.child),
    );
  }
}

/// A named move: one length and one curve. Trip screens pick moves by name
/// instead of pairing durations and curves inline.
class AlongMove {
  const AlongMove(this.duration, this.curve);

  final Duration duration;
  final Curve curve;

  /// Zero length when motion is off (reduced motion, gallery frames).
  Duration of(BuildContext context) {
    return AlongMotionPolicy.play(context) ? duration : Duration.zero;
  }
}

/// The trip-screen motion set. See docs/art-direction.md, "Named moves".
abstract final class AlongMoves {
  /// A live number changes: ETA range, countdown, period total.
  static const roll = AlongMove(AlongDurations.fade, AlongCurves.settle);

  /// A notice or state block arrives in the sheet.
  static const arrive = AlongMove(AlongDurations.sheet, AlongCurves.settle);

  /// Selection inside a control: period switch, star fill.
  static const select = AlongMove(AlongDurations.press, AlongCurves.fade);

  /// Content swap between two states of one screen.
  static const swap = AlongMove(AlongDurations.stagger, AlongCurves.settle);
}
