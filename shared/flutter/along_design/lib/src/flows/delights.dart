import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'vehicle_art.dart';

/// Gallery hour. The live app can pass the clock; goldens stay on afternoon.
enum AlongDayPhase { morning, afternoon, evening, night }

extension AlongDayPhaseCopy on AlongDayPhase {
  String get greeting => switch (this) {
    AlongDayPhase.morning => 'Good morning',
    AlongDayPhase.afternoon => 'Good afternoon',
    AlongDayPhase.evening => 'Good evening',
    AlongDayPhase.night => 'Good night',
  };

  String get weather => switch (this) {
    AlongDayPhase.morning => '24° · clear',
    AlongDayPhase.afternoon => '28° · clear',
    AlongDayPhase.evening => '26° · breeze',
    AlongDayPhase.night => '23° · clear',
  };

  List<Color> scrim(bool dark) => switch (this) {
    AlongDayPhase.morning => [
      dark ? const Color(0xCC1A1408) : const Color(0x99F6E2A8),
      const Color(0x00000000),
    ],
    AlongDayPhase.afternoon => [
      dark ? const Color(0xCC14160F) : const Color(0x66F7D117),
      const Color(0x00000000),
    ],
    AlongDayPhase.evening => [
      dark ? const Color(0xCC2A140C) : const Color(0x99E8A06A),
      const Color(0x00000000),
    ],
    AlongDayPhase.night => [
      dark ? const Color(0xE60E1018) : const Color(0x99202838),
      const Color(0x00000000),
    ],
  };
}

String alongNaira(int value) {
  final raw = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '−₦' : '₦');
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
    buf.write(raw[i]);
  }
  return buf.toString();
}

/// Frosted surface for controls that float on the map.
class AlongFrost extends StatelessWidget {
  const AlongFrost({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.circle = false,
    this.solid = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool circle;

  /// Text sits on an opaque surface. Blur stays on icon chrome over the map.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    if (solid) {
      final shape = circle ? const CircleBorder() : AlongCraft.border(radius);
      return DecoratedBox(
        decoration: ShapeDecoration(color: palette.surface, shape: shape),
        child: Padding(
          padding: padding,
          child: IconTheme.merge(
            data: IconThemeData(color: palette.ink),
            child: DefaultTextStyle.merge(child: child),
          ),
        ),
      );
    }
    final blur = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: ColoredBox(
        color: palette.surface.withValues(alpha: 0.78),
        child: Padding(
          padding: padding,
          child: IconTheme.merge(
            data: IconThemeData(color: palette.ink),
            child: DefaultTextStyle.merge(child: child),
          ),
        ),
      ),
    );
    if (circle) return ClipOval(child: blur);
    return ClipPath(
      clipper: ShapeBorderClipper(shape: AlongCraft.border(radius)),
      child: blur,
    );
  }
}

class AlongDayGradient extends StatelessWidget {
  const AlongDayGradient({super.key, required this.phase});

  final AlongDayPhase phase;

  @override
  Widget build(BuildContext context) {
    final dark = AlongPalette.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: phase.scrim(dark),
        ),
      ),
    );
  }
}

class AlongGreeting extends StatelessWidget {
  const AlongGreeting({super.key, required this.phase});

  final AlongDayPhase phase;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final title = AlongType.title(palette).copyWith(fontSize: 16, height: 1.1);
    final meta = AlongType.meta(palette).copyWith(height: 1.1);
    return Align(
      alignment: Alignment.centerLeft,
      child: AlongFrost(
        solid: true,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(phase.greeting, maxLines: 1, softWrap: false, style: title),
            Text(phase.weather, maxLines: 1, softWrap: false, style: meta),
          ],
        ),
      ),
    );
  }
}

class AlongSuggestionChips extends StatelessWidget {
  const AlongSuggestionChips({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final chips = <Widget>[
      for (var i = 0; i < labels.length; i++)
        AlongStagger(
          index: i,
          child: Padding(
            padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 6),
            child: AlongPressable(
              child: AlongFrost(
                solid: true,
                radius: 99,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: palette.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: chips),
    );
  }
}

class AlongStagger extends StatelessWidget {
  const AlongStagger({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No entrance on every row. The list is already there.
    return child;
  }
}

class AlongTabBar extends StatefulWidget {
  const AlongTabBar({super.key, this.index = 0});

  final int index;

  @override
  State<AlongTabBar> createState() => AlongTabBarState();
}

class AlongTabBarState extends State<AlongTabBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late int _index;

  static const _icons = <(IconData, String)>[
    (AlongIcons.home, 'Home'),
    (AlongIcons.taxi, 'Rides'),
    (AlongIcons.wallet, 'Wallet'),
    (AlongIcons.shield, 'Safety'),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _pop = AnimationController(
      vsync: this,
      duration: AlongDurations.sheet,
      value: 1,
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void select(int index) {
    setState(() => _index = index);
    if (!AlongMotionPolicy.play(context)) {
      _pop.value = 1;
      return;
    }
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AlongFrost(
      radius: 24,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            for (var i = 0; i < _icons.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == _index,
                  label: _icons[i].$2,
                  child: GestureDetector(
                    onTap: () {
                      AlongHaptics.selection(context);
                      select(i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pop,
                        builder: (context, child) {
                          final scale = i == _index
                              ? 0.86 + 0.14 * _pop.value
                              : 1.0;
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i == _index
                                ? palette.accent
                                : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SizedBox(
                            width: 36,
                            height: 32,
                            child: Icon(
                              _icons[i].$1,
                              size: 20,
                              color: i == _index
                                  ? palette.accentInk
                                  : palette.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AlongWordmark extends StatelessWidget {
  const AlongWordmark({super.key, required this.color, this.progress = 1});

  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final palette = AlongPalette.of(context);
    return Opacity(
      opacity: t < 0.15 ? t / 0.15 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: CustomPaint(
              size: const Size(56, 56),
              painter: _MarkPainter(color: color, progress: t),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Along',
                maxLines: 1,
                softWrap: false,
                style: AlongType.display(palette).copyWith(
                  color: color,
                  fontSize: 28,
                  height: 1,
                  letterSpacing: -1.0,
                ),
              ),
              Text(
                'ABUJA',
                maxLines: 1,
                softWrap: false,
                style: AlongType.caption(palette).copyWith(
                  color: color.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.062
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF111111);
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.28,
        size.width * 0.58,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.70,
        size.width * 0.80,
        size.height * 0.36,
      );
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(drawn, ink);
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.36),
      size.width * 0.07,
      Paint()..color = const Color(0xFFF7D117),
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Splash mark that settles, then hands off to onboarding.
class AlongSplash extends StatefulWidget {
  const AlongSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<AlongSplash> createState() => AlongSplashState();
}

class AlongSplashState extends State<AlongSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;
  var _reported = false;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (!AlongMotionPolicy.play(context)) {
      _draw.value = 1;
      _finish();
      return;
    }
    _draw.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_reported || !mounted) return;
    _reported = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ColoredBox(
      color: palette.bg,
      child: Center(
        child: AnimatedBuilder(
          animation: _draw,
          builder: (context, _) {
            return AlongWordmark(color: palette.ink, progress: _draw.value);
          },
        ),
      ),
    );
  }
}

class AlongOdometer extends StatefulWidget {
  const AlongOdometer({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  State<AlongOdometer> createState() => AlongOdometerState();
}

class AlongOdometerState extends State<AlongOdometer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll;
  late int _from;
  late int _shown;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _shown = widget.value;
    _roll = AnimationController(
      vsync: this,
      duration: AlongDurations.refresh,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AlongOdometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _from = _shown;
    if (!AlongMotionPolicy.play(context)) {
      setState(() => _shown = widget.value);
      _roll.value = 1;
      return;
    }
    _roll.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _shown = widget.value);
    });
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_roll.value >= 1 || !AlongMotionPolicy.play(context)) {
      return AlongMoney(value: _shown, style: widget.style);
    }
    final t = Curves.easeOutCubic.transform(_roll.value);
    final current = (_from + (widget.value - _from) * t).round();
    return AlongMoney(value: current, style: widget.style);
  }
}

/// Mechanical digit window. Gallery frames rest on [text]. A change rolls
/// each numeral with [AlongDurations.refresh].
class AlongRollingDigits extends StatefulWidget {
  const AlongRollingDigits({
    super.key,
    required this.text,
    required this.style,
    this.suffix = '',
  });

  final String text;
  final TextStyle style;
  final String suffix;

  @override
  State<AlongRollingDigits> createState() => AlongRollingDigitsState();
}

class AlongRollingDigitsState extends State<AlongRollingDigits>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll;
  late String _from;

  @override
  void initState() {
    super.initState();
    _from = widget.text;
    _roll = AnimationController(
      vsync: this,
      duration: AlongDurations.refresh,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant AlongRollingDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    _from = oldWidget.text;
    if (!AlongMotionPolicy.play(context)) {
      _roll.value = 1;
      _from = widget.text;
      return;
    }
    _roll.forward(from: 0);
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      label: '${widget.text}${widget.suffix}',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _roll,
          builder: (context, _) {
            final rolling = _roll.value < 1 && AlongMotionPolicy.play(context);
            final t = AlongCurves.settle.transform(_roll.value.clamp(0.0, 1.0));
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: AlongCraft.surface(
                    palette,
                    radius: 10,
                    color: palette.recessed,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.text.length; i++)
                          _DigitDrum(
                            from: i < _from.length ? _from[i] : widget.text[i],
                            to: widget.text[i],
                            t: rolling ? t : 1,
                            style: widget.style,
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.suffix.isNotEmpty)
                  Text(
                    widget.suffix,
                    maxLines: 1,
                    softWrap: false,
                    style: widget.style,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DigitDrum extends StatelessWidget {
  const _DigitDrum({
    required this.from,
    required this.to,
    required this.t,
    required this.style,
  });

  final String from;
  final String to;
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 34;
    final height = size * (style.height ?? 1);
    final drum = style.copyWith(height: 1);
    final fromDigit = int.tryParse(from);
    final toDigit = int.tryParse(to);
    if (fromDigit == null || toDigit == null || t >= 1) {
      return Text(to, maxLines: 1, softWrap: false, style: drum);
    }
    var delta = toDigit - fromDigit;
    if (delta <= 0) delta += 10;
    final pos = fromDigit + delta * t;
    final shown = pos.floor() % 10;
    final next = (shown + 1) % 10;
    final frac = pos - pos.floor();
    return ClipRect(
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, -frac * height),
              child: Text('$shown', maxLines: 1, softWrap: false, style: drum),
            ),
            Transform.translate(
              offset: Offset(0, (1 - frac) * height),
              child: Text('$next', maxLines: 1, softWrap: false, style: drum),
            ),
          ],
        ),
      ),
    );
  }
}

class AlongFareSplit extends StatelessWidget {
  const AlongFareSplit({super.key, required this.each});

  final int each;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final caption = AlongType.caption(palette).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      key: const Key('seat_fare_split'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: palette.accent,
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: palette.ink,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'You ${alongNaira(each)}',
              maxLines: 1,
              softWrap: false,
              style: caption,
            ),
            const Spacer(),
            Text(
              'Them ${alongNaira(each)}',
              maxLines: 1,
              softWrap: false,
              style: caption.copyWith(color: palette.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class AlongSwipeConfirm extends StatefulWidget {
  const AlongSwipeConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  final String label;
  final VoidCallback onConfirmed;

  @override
  State<AlongSwipeConfirm> createState() => AlongSwipeConfirmState();
}

class AlongSwipeConfirmState extends State<AlongSwipeConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle;
  double _x = 0;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(() {
        if (mounted) setState(() => _x = _settle.value);
      });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  double _travel = 0;

  void _finish({double velocity = 0}) {
    if (_done) return;
    setState(() => _done = true);
    _spring(_travel, velocity);
    AlongHaptics.success(context);
    widget.onConfirmed();
  }

  void _spring(double target, double velocity) {
    if (!AlongMotionPolicy.play(context)) {
      _settle.value = target;
      setState(() => _x = target);
      return;
    }
    _settle.animateWith(
      SpringSimulation(AlongSprings.sheet, _x, target, velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 280.0;
          final travel = math.max(0.0, width - 56);
          _travel = travel;
          final x = _x.clamp(0.0, travel);
          final fade = _done
              ? 1.0
              : (1 - (travel == 0 ? 0.0 : x / travel)).clamp(0.0, 1.0);
          return SizedBox(
            width: width,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(color: palette.recessed),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56),
                      child: Opacity(
                        opacity: fade,
                        child: Text(
                          _done ? 'Held' : widget.label,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: AlongType.button(palette)
                              .copyWith(color: palette.ink),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 4 + x,
                      top: 4,
                      child: GestureDetector(
                        key: const Key('swipe_thumb'),
                        onHorizontalDragUpdate: (details) {
                          if (_done) return;
                          setState(() {
                            _x = (_x + details.delta.dx).clamp(0.0, travel);
                            _settle.value = _x;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragEnd: (details) {
                          if (_done) return;
                          final velocity = details.primaryVelocity ?? 0;
                          // Read the state field. The recognizer can fire end
                          // with the closure from the pointer-down frame.
                          if (_x > travel * 0.72 || velocity > 900) {
                            _finish(velocity: velocity);
                          } else {
                            _spring(0, velocity);
                          }
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              AlongIcons.navigate,
                              color: palette.accentInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Semantics(
                        button: true,
                        label: 'Confirm',
                        child: Material(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            key: const Key('confirm_without_swipe'),
                            onTap: _finish,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(AlongIcons.check, color: palette.ink),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlongProgressRing extends StatelessWidget {
  const AlongProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 44,
    this.celebrate = false,
  });

  final double progress;
  final String label;
  final double size;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          track: palette.recessed,
          ink: palette.accent,
        ),
        child: Center(
          child: celebrate && progress >= 1
              ? Icon(AlongIcons.check, size: size * 0.42, color: palette.ink)
              : Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(palette).copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: palette.ink,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.ink,
  });

  final double progress;
  final Color track;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, size.width * 0.08)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(stroke.strokeWidth),
      0,
      math.pi * 2,
      false,
      stroke..color = track,
    );
    canvas.drawArc(
      rect.deflate(stroke.strokeWidth),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      stroke..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.ink != ink;
}

class AlongPinDrop extends StatefulWidget {
  const AlongPinDrop({super.key, required this.child});

  final Widget child;

  @override
  State<AlongPinDrop> createState() => AlongPinDropState();
}

class AlongPinDropState extends State<AlongPinDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop;

  @override
  void initState() {
    super.initState();
    _drop = AnimationController.unbounded(vsync: this, value: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _drop.value = -18;
      _drop.animateWith(SpringSimulation(AlongSprings.route, -18, 0, 0));
    });
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AlongMotionPolicy.play(context) && _drop.value == 0) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _drop,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _drop.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Sample path with a gradient segment that travels once, then rests.
class AlongRoutePulse extends StatefulWidget {
  const AlongRoutePulse({super.key, this.onCycle});

  final VoidCallback? onCycle;

  @override
  State<AlongRoutePulse> createState() => AlongRoutePulseState();
}

class AlongRoutePulseState extends State<AlongRoutePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AlongDurations.routeDraw,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _pulse.forward().whenComplete(() => widget.onCycle?.call());
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return CustomPaint(
          painter: AlongRoutePulsePainter(
            t: AlongMotionPolicy.play(context) ? _pulse.value : 0,
            color: palette.accent,
          ),
          child: const SizedBox(width: 120, height: 48),
        );
      },
    );
  }
}

class AlongRoutePulsePainter extends CustomPainter {
  AlongRoutePulsePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(4, size.height / 2)
      ..quadraticBezierTo(size.width * 0.4, 4, size.width - 4, size.height / 2);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35),
    );
    if (t <= 0) return;
    alongPaintRoutePulse(canvas, path, t, color);
  }

  @override
  bool shouldRepaint(covariant AlongRoutePulsePainter oldDelegate) =>
      oldDelegate.t != t;
}

void alongPaintRoutePulse(Canvas canvas, Path path, double t, Color color) {
  if (t <= 0) return;
  for (final metric in path.computeMetrics()) {
    final start = metric.length * t;
    final end = math.min(metric.length, start + metric.length * 0.18);
    if (end <= 0) continue;
    final segment = metric.extractPath(math.max(0, start - 8), end);
    canvas.drawPath(
      segment,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(segment.getBounds()),
    );
  }
}

class AlongKekeRefresh extends StatefulWidget {
  const AlongKekeRefresh({super.key, required this.child, this.onRefresh});

  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  State<AlongKekeRefresh> createState() => AlongKekeRefreshState();
}

class AlongKekeRefreshState extends State<AlongKekeRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rock;
  var _pulling = false;

  @override
  void initState() {
    super.initState();
    _rock = AnimationController(vsync: this, duration: AlongDurations.refresh);
  }

  @override
  void dispose() {
    _rock.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_pulling) return;
    setState(() => _pulling = true);
    if (AlongMotionPolicy.play(context)) _rock.repeat();
    try {
      await widget.onRefresh?.call();
    } finally {
      if (mounted) {
        _rock.stop();
        setState(() => _pulling = false);
      }
    }
  }

  bool _onScroll(ScrollNotification notice) {
    if (_pulling) return false;
    if (notice is OverscrollNotification &&
        notice.overscroll < 0 &&
        notice.metrics.pixels <= 0) {
      refresh();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          if (_pulling)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _rock,
                builder: (context, _) {
                  final progress = AlongMotionPolicy.play(context)
                      ? _rock.value
                      : 0.55;
                  return AlongDriveTrack(progress: progress);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A car crossing a short road. [progress] is 0 at the left curb and 1 at
/// the right. The refresh loop drives it. A still frame passes a fixed value.
class AlongDriveTrack extends StatelessWidget {
  const AlongDriveTrack({super.key, this.progress = 0});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final t = progress.clamp(0.0, 1.0);
    return SizedBox(
      key: const Key('keke_refresh'),
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = math.max(0.0, constraints.maxWidth - 88);
          return Stack(
            children: [
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Positioned(
                left: 8 + travel * t,
                top: 2,
                child: const AlongVehicleMark(
                  kind: AlongVehicleKind.car,
                  width: 72,
                  height: 32,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AlongConfetti extends StatefulWidget {
  const AlongConfetti({super.key, required this.play, this.onDone});

  final bool play;
  final VoidCallback? onDone;

  @override
  State<AlongConfetti> createState() => AlongConfettiState();
}

class AlongConfettiState extends State<AlongConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant AlongConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      if (!AlongMotionPolicy.play(context)) {
        widget.onDone?.call();
        return;
      }
      _burst.forward(from: 0).whenComplete(() => widget.onDone?.call());
    } else if (!widget.play && _burst.value != 0) {
      _burst.value = 0;
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.play || _burst.value == 0) {
      return const SizedBox.shrink();
    }
    final palette = AlongPalette.of(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burst,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConfettiPainter(
              t: _burst.value,
              accent: palette.accent,
              ink: palette.ink,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t, required this.accent, required this.ink});

  final double t;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final origin = Offset(size.width / 2, size.height * 0.2);
    for (var i = 0; i < 14; i++) {
      final angle = (i / 14) * math.pi + 0.4;
      final dist = 28 + 90 * t + (i % 3) * 8;
      final center =
          origin +
          Offset(
            math.cos(angle) * dist,
            math.sin(angle) * dist * 0.65 + 40 * t,
          );
      final paint = Paint()
        ..color = (i.isEven ? accent : ink).withValues(alpha: (1 - t) * 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 6, height: 3),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}

class AlongContainerTransform extends StatefulWidget {
  const AlongContainerTransform({
    super.key,
    required this.closed,
    required this.destination,
    this.open = false,
  });

  final Widget closed;
  final Widget destination;
  final bool open;

  @override
  State<AlongContainerTransform> createState() =>
      AlongContainerTransformState();
}

class AlongContainerTransformState extends State<AlongContainerTransform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: widget.open ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant AlongContainerTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    if (!AlongMotionPolicy.play(context)) {
      _expand.value = widget.open ? 1 : 0;
      return;
    }
    if (widget.open) {
      _expand.forward();
    } else {
      _expand.reverse();
    }
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        if (_expand.value == 0) return widget.closed;
        final t = Curves.easeOutCubic.transform(_expand.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(20 * (1 - t)),
          child: ColoredBox(
            color: palette.bg,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 0.2 + 0.8 * t,
              child: Opacity(opacity: t, child: widget.destination),
            ),
          ),
        );
      },
    );
  }
}

/// Wallet card. Sensors tilt it; tests and reduced motion stay level.
class AlongGyroCard extends StatefulWidget {
  const AlongGyroCard({super.key, required this.child});

  final Widget child;

  static Offset debugTilt = Offset.zero;

  @override
  State<AlongGyroCard> createState() => AlongGyroCardState();
}

class AlongGyroCardState extends State<AlongGyroCard> {
  StreamSubscription<AccelerometerEvent>? _sensor;
  Offset _tilt = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (AlongMotionPolicy.inWidgetTest) return;
    _sensor = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      if (!AlongMotionPolicy.play(context)) return;
      setState(() {
        _tilt = Offset(
          (event.x / 10).clamp(-1.0, 1.0),
          (event.y / 10).clamp(-1.0, 1.0),
        );
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sensor?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tilt = AlongMotionPolicy.inWidgetTest
        ? AlongGyroCard.debugTilt
        : _tilt;
    final reduced = AlongMotionPolicy.reduced(context);
    final applied = reduced ? Offset.zero : tilt;
    Widget card = Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment(-0.8 + applied.dx, -1 + applied.dy),
                  end: Alignment(0.8 + applied.dx, 0.2 + applied.dy),
                  colors: const [
                    Color(0x33FFFFFF),
                    Color(0x00FFFFFF),
                    Color(0x14000000),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (applied == Offset.zero) return card;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0012)
        ..rotateX(applied.dy * 0.08)
        ..rotateY(-applied.dx * 0.08),
      child: card,
    );
  }
}

enum AlongMomentKind { confirmed, arriving, complete }

class AlongMoment extends StatelessWidget {
  const AlongMoment({super.key, required this.kind, this.size = 72});

  final AlongMomentKind kind;
  final double size;

  String get _asset => switch (kind) {
    AlongMomentKind.confirmed => 'assets/motion/confirmed.json',
    AlongMomentKind.arriving => 'assets/motion/arriving.json',
    AlongMomentKind.complete => 'assets/motion/complete.json',
  };

  @override
  Widget build(BuildContext context) {
    final play = AlongMotionPolicy.play(context);
    return Lottie.asset(
      _asset,
      package: 'along_design',
      width: size,
      height: size,
      animate: play,
      repeat: false,
    );
  }
}

class AlongTickingEta extends StatefulWidget {
  const AlongTickingEta({super.key, required this.label, required this.style});

  final String label;
  final TextStyle style;

  @override
  State<AlongTickingEta> createState() => AlongTickingEtaState();
}

class AlongTickingEtaState extends State<AlongTickingEta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: AlongDurations.routeDraw,
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _tick.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AlongMotionPolicy.play(context)) {
      return Text(
        widget.label,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      );
    }
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        return Opacity(
          opacity: 0.72 + 0.28 * _tick.value,
          child: Text(
            widget.label,
            maxLines: 1,
            softWrap: false,
            style: widget.style,
          ),
        );
      },
    );
  }
}

class AlongVehicleHero extends StatelessWidget {
  const AlongVehicleHero({
    super.key,
    required this.kind,
    this.width = 72,
    this.height,
  });

  final AlongVehicleKind kind;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'along-vehicle-${kind.name}',
      child: AlongVehicleMark(kind: kind, width: width, height: height),
    );
  }
}
