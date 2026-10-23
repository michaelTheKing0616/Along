import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ride UI is used many times a day, so springs settle inside 300ms.
/// The motion-grammar spring (stiffness 100, damping 20) is the character:
/// a short underdamped settle, scaled up so the sheet does not linger. [emil]
/// Named lengths. Springs live on [AlongSprings]. Nothing else invents a
/// duration. See the motion table in docs/art-direction.md.
abstract final class AlongDurations {
  static const press = Duration(milliseconds: 120);
  static const fade = Duration(milliseconds: 180);
  static const stagger = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 280);
  static const refresh = Duration(milliseconds: 480);
  static const routeDraw = Duration(milliseconds: 900);
  static const hold = Duration(milliseconds: 1400);
  static const scan = Duration(milliseconds: 1800);

  /// Demand glow on the three hot cells. One breath, then back.
  static const breath = Duration(milliseconds: 2400);
}

abstract final class AlongCurves {
  static const fade = Curves.easeOut;
  static const settle = Curves.easeOutCubic;
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

  /// Cushion press. Short, then back. The seat scale uses its own settle.
  static const press = SpringDescription(
    mass: 0.4,
    stiffness: 640,
    damping: 18,
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
