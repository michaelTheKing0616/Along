import 'dart:async';
import 'dart:math' as math;

import 'package:along_core/along_core.dart';
import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../components/na_me_mapper.dart';
import '../components/na_me_shape_painter.dart';
import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import '../utils/name_signal.dart';
import 'pin_entry.dart';

/// One colour + shape pairing, as the server sends it.
class AlongNaMeChoice {
  const AlongNaMeChoice({
    required this.colorToken,
    required this.shape,
    required this.label,
  });

  final String colorToken;
  final String shape;
  final String label;

  Color get color => naMeColourFromToken(colorToken).color;
  NaMeShape get shapeKind => naMeShapeFromToken(shape);

  @override
  bool operator ==(Object other) =>
      other is AlongNaMeChoice &&
      other.colorToken == colorToken &&
      other.shape == shape;

  @override
  int get hashCode => Object.hash(colorToken, shape);
}

/// What the server said about one handshake attempt.
enum AlongNaMeVerdict { matched, wrong, rateLimited, locked, failed }

class AlongNaMeResult {
  const AlongNaMeResult(
    this.verdict, {
    this.attemptsLeft,
    this.tapLocked = false,
  });

  final AlongNaMeVerdict verdict;
  final int? attemptsLeft;

  /// One wrong tap locks tap-match: with four choices a second tap would
  /// let a guesser win by elimination.
  final bool tapLocked;
}

/// Ink that reads on a saturated Na Me colour: near-black on light hues.
Color _inkOn(Color c) =>
    c.computeLuminance() > 0.4 ? const Color(0xFF0B0B0C) : Colors.white;

class _Shape extends StatelessWidget {
  const _Shape({required this.choice, required this.size, this.color});

  final AlongNaMeChoice choice;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: NaMeShapePainter(
        shape: choice.shapeKind,
        color: color ?? choice.color,
      ),
    ),
  );
}

/// R-12b The rider's show screen. Zero taps: it opens itself when the
/// driver is at the pickup, runs at full brightness and keeps the screen on
/// (the app wires both). The pairing sits on top so the driver can match it
/// by eye; under it a colour panel flashes the optical code
/// ([NaMeOptical.frames]) for the driver's camera. Without frames (flag off
/// or no secret yet) the panel is replaced by a tap-match hint.
class AlongNaMeShowScreen extends StatefulWidget {
  const AlongNaMeShowScreen({
    super.key,
    required this.pairing,
    required this.driverName,
    this.frames = const [],
    this.frameIndex,
    this.onClose,
  });

  final AlongNaMeChoice pairing;
  final String driverName;

  /// RGB frames for one loop; empty hides the optical panel.
  final List<int> frames;

  /// Golden seed: pins the panel to one frame and stops the clock.
  final int? frameIndex;
  final VoidCallback? onClose;

  @override
  State<AlongNaMeShowScreen> createState() => _AlongNaMeShowScreenState();
}

class _AlongNaMeShowScreenState extends State<AlongNaMeShowScreen> {
  Timer? _timer;
  late int _frame = widget.frameIndex ?? 0;

  @override
  void initState() {
    super.initState();
    if (widget.frameIndex == null && widget.frames.isNotEmpty) {
      _timer = Timer.periodic(
        const Duration(milliseconds: NaMeOptical.frameMs),
        (_) => setState(() => _frame = (_frame + 1) % widget.frames.length),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final optical = widget.frames.isNotEmpty;
    final name = widget.driverName;
    return Scaffold(
      key: const Key('na_me_show'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _SquareButton(
                  icon: AlongIcons.close,
                  label: 'Close',
                  onTap: widget.onClose ?? () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 8),
              Text('Show $name this', style: AlongType.display(p)),
              const SizedBox(height: 4),
              Text(
                optical
                    ? 'Hold it up. Their camera reads the colours.'
                    : 'They tap the colour and shape you see here.',
                style: AlongType.body(p).copyWith(color: p.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: p.surface,
                    shape: AlongCraft.border(28),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Shape(choice: widget.pairing, size: 120),
                      const SizedBox(height: 16),
                      Text(
                        widget.pairing.label,
                        key: const Key('na_me_show_label'),
                        style: AlongType.title(p),
                      ),
                      if (optical) ...[
                        const SizedBox(height: 24),
                        Semantics(
                          label: 'Colour code for the driver\'s camera',
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              shape: AlongCraft.border(28).copyWith(
                                side: BorderSide(color: p.line, width: 2),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SizedBox.square(
                                key: const Key('na_me_signal'),
                                dimension: 152,
                                child: DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: Color(
                                      0xFF000000 | widget.frames[_frame],
                                    ),
                                    shape: AlongCraft.border(20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Camera code',
                          style: AlongType.caption(p).copyWith(color: p.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AlongIcon(AlongIcons.lock, size: 16, color: p.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only $name\'s phone can read this code.',
                      style: AlongType.caption(p).copyWith(color: p.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// D-16c The driver's camera view. The camera feed fills the screen
/// ([preview]); a squircle reticle shows where to aim. A bar under it runs
/// down the 6 s before the flow falls back to tap-match on its own.
class AlongNaMeCameraView extends StatelessWidget {
  const AlongNaMeCameraView({
    super.key,
    required this.riderName,
    required this.preview,
    required this.fallbackProgress,
    this.onPickInstead,
    this.onClose,
  });

  final String riderName;
  final Widget preview;

  /// 0 → just opened, 1 → switching to tap-match.
  final double fallbackProgress;
  final VoidCallback? onPickInstead;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      key: const Key('na_me_camera'),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          preview,
          const ColoredBox(color: Color(0x66000000)),
          Align(
            alignment: const Alignment(0, -0.3),
            child: Container(
              width: 240,
              height: 240,
              decoration: ShapeDecoration(
                shape: AlongCraft.border(32).copyWith(
                  side: const BorderSide(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: _SquareButton(
                  icon: AlongIcons.close,
                  label: 'Close',
                  onTap: onClose ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: p.bg,
                shape: AlongCraft.border(32),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Point at $riderName\'s screen',
                        style: AlongType.title(p),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reading the colours. If it can\'t in 6 s, you\'ll tap instead.',
                        style: AlongType.body(p).copyWith(color: p.muted),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          key: const Key('na_me_fallback_bar'),
                          value: 1 - fallbackProgress.clamp(0, 1),
                          minHeight: 4,
                          color: p.ink,
                          backgroundColor: p.line,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AlongButton(
                        key: const Key('na_me_pick_instead'),
                        label: 'Tap their colour instead',
                        variant: AlongButtonVariant.secondary,
                        onPressed: onPickInstead,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// D-16d One-tap match: the rider's pairing among three decoys the server
/// drew from pairings no other live trip at the stage holds.
class AlongNaMeTapMatch extends StatelessWidget {
  const AlongNaMeTapMatch({
    super.key,
    required this.riderName,
    required this.options,
    required this.onPick,
    this.onUsePin,
    this.onClose,
    this.checking,
  });

  final String riderName;
  final List<AlongNaMeChoice> options;
  final ValueChanged<AlongNaMeChoice> onPick;
  final VoidCallback? onUsePin;
  final VoidCallback? onClose;

  /// The choice being checked; the grid is disabled meanwhile.
  final AlongNaMeChoice? checking;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Scaffold(
      key: const Key('na_me_tap'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _SquareButton(
                  icon: AlongIcons.close,
                  label: 'Close',
                  onTap: onClose ?? () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 8),
              Text('What is $riderName showing?', style: AlongType.display(p)),
              const SizedBox(height: 4),
              Text(
                'Tap the colour and shape on their screen.',
                style: AlongType.body(p).copyWith(color: p.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final tileH = math.min(168.0, (c.maxHeight - 12) / 2);
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < options.length; i++)
                          SizedBox(
                            width: (c.maxWidth - 12) / 2,
                            height: tileH,
                            child: _ChoiceTile(
                              key: Key('na_me_choice_$i'),
                              choice: options[i],
                              busy: checking == options[i],
                              onTap: checking == null
                                  ? () => onPick(options[i])
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (onUsePin != null)
                AlongButton(
                  key: const Key('na_me_use_pin'),
                  label: 'Use the PIN instead',
                  variant: AlongButtonVariant.secondary,
                  onPressed: onUsePin,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.choice,
    required this.busy,
    this.onTap,
  });

  final AlongNaMeChoice choice;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: choice.label,
      excludeSemantics: true,
      child: AlongPressable(
        child: Material(
          color: p.surface,
          shape: AlongCraft.border(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    AlongHaptics.tick(context);
                    onTap!();
                  },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: busy ? 0.32 : 1,
                  child: _Shape(choice: choice, size: 64),
                ),
                const SizedBox(height: 12),
                Text(
                  busy ? 'Checking…' : choice.label,
                  style: AlongType.label(p)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// D-16e A wrong tap. Neutral on purpose: no colour, no hint of which
/// pairing was right.
class AlongNaMeNoMatch extends StatelessWidget {
  const AlongNaMeNoMatch({
    super.key,
    required this.riderName,
    required this.result,
    this.onRetry,
    this.onUsePin,
  });

  final String riderName;
  final AlongNaMeResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onUsePin;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final left = result.attemptsLeft;
    final canRetry =
        onRetry != null &&
        !result.tapLocked &&
        result.verdict != AlongNaMeVerdict.locked &&
        (left == null || left > 0);
    final body = switch (result.verdict) {
      AlongNaMeVerdict.rateLimited =>
        'Too fast. Wait a moment, then try again.',
      AlongNaMeVerdict.failed =>
        'Couldn\'t check. Check your connection, or use the PIN.',
      AlongNaMeVerdict.locked =>
        'Too many tries. Ask $riderName for their PIN.',
      _ =>
        'Make sure this is $riderName. Ask for the 4-digit PIN in their app.',
    };
    return Scaffold(
      key: const Key('na_me_no_match'),
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: p.surface,
                    shape: AlongCraft.border(24),
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Center(
                      child: AlongIcon(AlongIcons.info, size: 32, color: p.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Not a match',
                textAlign: TextAlign.center,
                style: AlongType.display(p),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                key: const Key('na_me_no_match_body'),
                textAlign: TextAlign.center,
                style: AlongType.body(p).copyWith(color: p.muted),
              ),
              const Spacer(),
              if (onUsePin != null)
                AlongButton(
                  key: const Key('na_me_no_match_pin'),
                  label: 'Enter their PIN',
                  variant: canRetry
                      ? AlongButtonVariant.secondary
                      : AlongButtonVariant.primary,
                  onPressed: onUsePin,
                ),
              if (canRetry) ...[
                const SizedBox(height: 12),
                AlongButton(
                  key: const Key('na_me_retry'),
                  label: 'Try again',
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The match ([AlongMoves.match], docs/art-direction.md "The match"). Shown
/// on both phones only once the server (or the driver's local check of the
/// optical code) confirms. The pairing colour floods out from the centre,
/// the shape morphs into a check, and the haptic pattern plays. Done in
/// 1 s. The driver then sees one Start button; the rider's screen closes
/// itself. Reduced motion shows the rest pose at once.
class AlongNaMeCelebration extends StatefulWidget {
  const AlongNaMeCelebration({
    super.key,
    required this.pairing,
    required this.title,
    this.subtitle,
    this.startLabel,
    this.onStart,
    this.onDone,
    this.onChime,
    this.progress,
  });

  final AlongNaMeChoice pairing;
  final String title;
  final String? subtitle;

  /// Driver only: one tap to start the trip.
  final String? startLabel;
  final VoidCallback? onStart;

  /// Rider only: called when the moment has played (under 1.2 s).
  final VoidCallback? onDone;

  /// The app plays the chime asset here, in step with the haptic.
  final VoidCallback? onChime;

  /// Golden seed: 0..1 through the moment.
  final double? progress;

  @override
  State<AlongNaMeCelebration> createState() => _AlongNaMeCelebrationState();
}

class _AlongNaMeCelebrationState extends State<AlongNaMeCelebration>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AlongMoves.match.duration,
  );
  Timer? _done;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.progress != null) return;
      AlongHaptics.match(context);
      widget.onChime?.call();
      if (AlongMotionPolicy.reduced(context)) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
      _done = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) widget.onDone?.call();
      });
    });
  }

  @override
  void dispose() {
    _done?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final flood = widget.pairing.color;
    final ink = _inkOn(flood);
    return Scaffold(
      key: const Key('na_me_match'),
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = widget.progress ?? _c.value;
          final reveal = Curves.easeOutCubic.transform((t / 0.35).clamp(0, 1));
          final morph = AlongCurves.settle.transform(
            ((t - 0.3) / 0.45).clamp(0, 1),
          );
          final text = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: _CircleReveal(reveal),
                child: ColoredBox(color: flood),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: SizedBox.square(
                          dimension: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: 1 - morph,
                                child: Transform.scale(
                                  scale: 1 - 0.4 * morph,
                                  child: _Shape(
                                    choice: widget.pairing,
                                    size: 140,
                                    color: ink,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size.square(120),
                                painter: _CheckPainter(morph, ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: text,
                        child: Column(
                          children: [
                            Text(
                              widget.title,
                              key: const Key('na_me_match_title'),
                              textAlign: TextAlign.center,
                              style: AlongType.display(p).copyWith(color: ink),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.subtitle!,
                                textAlign: TextAlign.center,
                                style: AlongType.body(
                                  p,
                                ).copyWith(color: ink.withValues(alpha: 0.86)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.onStart != null)
                        Opacity(
                          opacity: text,
                          child: _FloodButton(
                            label: widget.startLabel ?? 'Start trip',
                            ink: ink,
                            flood: flood,
                            onTap: text > 0 ? widget.onStart! : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloodButton extends StatelessWidget {
  const _FloodButton({
    required this.label,
    required this.ink,
    required this.flood,
    this.onTap,
  });

  final String label;
  final Color ink;
  final Color flood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: ink,
        shape: AlongCraft.border(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('na_me_start'),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                label,
                style: AlongType.button(p).copyWith(color: flood),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleReveal extends CustomClipper<Path> {
  _CircleReveal(this.t);
  final double t;

  @override
  Path getClip(Size size) {
    final r = size.longestSide * 0.75 * t;
    return Path()
      ..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: r));
  }

  @override
  bool shouldReclip(_CircleReveal old) => old.t != t;
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.2, w * 0.52)
      ..lineTo(w * 0.42, w * 0.72)
      ..lineTo(w * 0.8, w * 0.3);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color;
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: AlongCraft.border(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: AlongIcon(icon, size: 24, color: p.ink, tone: false),
            ),
          ),
        ),
      ),
    );
  }
}

/// D-16 The driver's boarding flow, fastest path first:
/// optical (0 taps) → tap-match (1 tap) → PIN (1 tap + 4 digits).
///
/// The camera stage runs only when [opticalProofs] is given. Each decoded
/// proof is checked locally against the trip secret by the app, so
/// [onOptical] answering `matched` can fire offline and queue the RPC.
/// After [fallbackAfter] with no match the flow moves to tap-match.
class AlongNaMeDriverFlow extends StatefulWidget {
  const AlongNaMeDriverFlow({
    super.key,
    required this.riderName,
    required this.pairing,
    required this.options,
    required this.onTap,
    required this.onPin,
    required this.onStart,
    this.cameraPreview,
    this.opticalProofs,
    this.onOptical,
    this.onChime,
    this.fallbackAfter = const Duration(seconds: 6),
    this.onClose,
  });

  final String riderName;

  /// The trip's real pairing: colours the celebration.
  final AlongNaMeChoice pairing;
  final List<AlongNaMeChoice> options;
  final Future<AlongNaMeResult> Function(AlongNaMeChoice choice) onTap;
  final Future<AlongPinResult> Function(String pin) onPin;
  final VoidCallback onStart;
  final Widget? cameraPreview;
  final Stream<NaMeOpticalProof>? opticalProofs;
  final Future<AlongNaMeResult> Function(NaMeOpticalProof proof)? onOptical;
  final VoidCallback? onChime;
  final Duration fallbackAfter;
  final VoidCallback? onClose;

  @override
  State<AlongNaMeDriverFlow> createState() => _AlongNaMeDriverFlowState();
}

enum _Stage { camera, tap, noMatch, pin, matched }

class _AlongNaMeDriverFlowState extends State<AlongNaMeDriverFlow> {
  late _Stage _stage = widget.opticalProofs != null && widget.onOptical != null
      ? _Stage.camera
      : _Stage.tap;
  AlongNaMeChoice? _checking;
  AlongNaMeResult? _last;
  StreamSubscription<NaMeOpticalProof>? _sub;
  Timer? _fallback;
  Timer? _tick;
  final _clock = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (_stage == _Stage.camera) {
      _clock.start();
      _sub = widget.opticalProofs!.listen(_onProof);
      _fallback = Timer(widget.fallbackAfter, () => _go(_Stage.tap));
      _tick = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => mounted ? setState(() {}) : null,
      );
    }
  }

  void _stopCamera() {
    _sub?.cancel();
    _fallback?.cancel();
    _tick?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  void _go(_Stage s) {
    if (!mounted) return;
    if (s != _Stage.camera) _stopCamera();
    setState(() => _stage = s);
  }

  Future<void> _onProof(NaMeOpticalProof proof) async {
    final r = await widget.onOptical!(proof);
    if (r.verdict == AlongNaMeVerdict.matched) _go(_Stage.matched);
    // Anything else: keep scanning; the fallback timer still runs.
  }

  Future<void> _pick(AlongNaMeChoice c) async {
    setState(() => _checking = c);
    AlongNaMeResult r;
    try {
      r = await widget.onTap(c);
    } catch (_) {
      r = const AlongNaMeResult(AlongNaMeVerdict.failed);
    }
    if (!mounted) return;
    _checking = null;
    if (r.verdict == AlongNaMeVerdict.matched) {
      _go(_Stage.matched);
    } else {
      AlongHaptics.error(context);
      _last = r;
      _go(_Stage.noMatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.riderName;
    final child = switch (_stage) {
      _Stage.camera => AlongNaMeCameraView(
        riderName: name,
        preview: widget.cameraPreview ?? const ColoredBox(color: Colors.black),
        fallbackProgress:
            _clock.elapsedMilliseconds / widget.fallbackAfter.inMilliseconds,
        onPickInstead: () => _go(_Stage.tap),
        onClose: widget.onClose,
      ),
      _Stage.tap => AlongNaMeTapMatch(
        riderName: name,
        options: widget.options,
        checking: _checking,
        onPick: _pick,
        onUsePin: () => _go(_Stage.pin),
        onClose: widget.onClose,
      ),
      _Stage.noMatch => AlongNaMeNoMatch(
        riderName: name,
        result: _last!,
        onRetry: () => _go(_Stage.tap),
        onUsePin: () => _go(_Stage.pin),
      ),
      _Stage.pin => AlongPinEntryScreen(
        riderName: name,
        onSubmit: widget.onPin,
        onVerified: widget.onStart,
        onClose: widget.onClose,
      ),
      _Stage.matched => AlongNaMeCelebration(
        pairing: widget.pairing,
        title: '$name is in',
        subtitle: 'Matched. Start when you\'re ready.',
        startLabel: 'Start trip',
        onStart: widget.onStart,
        onChime: widget.onChime,
      ),
    };
    return KeyedSubtree(key: ValueKey(_stage), child: child);
  }
}
