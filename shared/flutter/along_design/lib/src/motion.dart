import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Ride UI is used many times a day, so springs settle inside 300ms.
/// The motion-grammar spring (stiffness 100, damping 20) is the character:
/// a short underdamped settle, scaled up so the sheet does not linger. [emil]
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
}

abstract final class AlongMotionPolicy {
  static bool reduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static bool get inWidgetTest {
    final name = WidgetsBinding.instance.runtimeType.toString();
    return name.contains('Test');
  }
}

/// Selection haptics. Skipped when motion is reduced and in widget tests,
/// where the platform channel is absent. [emil]
abstract final class AlongHaptics {
  static Future<void> tick(BuildContext context) async {
    if (AlongMotionPolicy.reduced(context) || AlongMotionPolicy.inWidgetTest) {
      return;
    }
    await HapticFeedback.selectionClick();
  }

  static Future<void> confirm(BuildContext context) async {
    if (AlongMotionPolicy.reduced(context) || AlongMotionPolicy.inWidgetTest) {
      return;
    }
    await HapticFeedback.lightImpact();
  }
}
