import 'dart:async';
import 'dart:math' as math;

import 'package:along_core/along_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../components/na_me_mapper.dart';
import '../components/na_me_shape_painter.dart';
import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
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
  const _Shape({required this.choice, required this.size});

  final AlongNaMeChoice choice;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: NaMeShapePainter(shape: choice.shapeKind, color: choice.color),
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
                  child: optical
                      ? _OpticalFace(
                          pairing: widget.pairing,
                          frame: widget.frames[_frame],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Shape(choice: widget.pairing, size: 120),
                            const SizedBox(height: 16),
                            Text(
                              widget.pairing.label,
                              key: const Key('na_me_show_label'),
                              style: AlongType.title(p),
                            ),
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

/// The optical face of the show card. The camera code is the 0-tap path,
/// so it leads; the pairing sits under it as the 1-tap fallback the driver
/// taps if the camera can't read the code.
class _OpticalFace extends StatelessWidget {
  const _OpticalFace({required this.pairing, required this.frame});

  final AlongNaMeChoice pairing;
  final int frame;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Semantics(
              label: 'Colour code for the driver\'s camera',
              // Photosensitivity (WCAG 2.3.1): the white sync frame
              // flashes ~0.5/s; the 6 Hz colour frames stay under the
              // small-area limit (152 dp is well below 25% of a 10°
              // field at arm's length).
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: p.recessed,
                  shape: AlongCraft.border(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox.square(
                    key: const Key('na_me_signal'),
                    dimension: 152,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Color(0xFF000000 | frame),
                        shape: AlongCraft.border(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Camera code',
            style: AlongType.label(p).copyWith(color: p.muted),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: ShapeDecoration(
              color: p.recessed,
              shape: AlongCraft.border(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _Shape(choice: pairing, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pairing.label,
                          key: const Key('na_me_show_label'),
                          style: AlongType.title(p),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Backup: they tap this',
                          style: AlongType.label(p).copyWith(color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    this.locked = false,
    this.onPickInstead,
    this.onClose,
  });

  final String riderName;
  final Widget preview;

  /// The camera sees the code's sync frame: the brackets close in on it.
  final bool locked;

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
          // Vignette: clear over the reticle, darker toward the edges, so
          // the eye lands on the frame and the white UI reads on any scene.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 0.9,
                colors: [Color(0x33000000), Color(0xB3000000)],
                stops: [0.35, 1],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Reticle(locked: locked),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: AlongMotionPolicy.reduced(context)
                      ? Duration.zero
                      : AlongMoves.lockOn.duration,
                  child: DecoratedBox(
                    key: ValueKey(locked),
                    // Circular radius, not superellipse: host-stable over
                    // the camera feed.
                    decoration: BoxDecoration(
                      color: const Color(0xA6000000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AlongIcon(
                            locked ? AlongIcons.check : AlongIcons.locate,
                            size: 20,
                            color: locked
                                ? AlongColors.brandYellow
                                : Colors.white,
                            tone: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locked
                                ? 'Got it. Hold still.'
                                : 'Fit their screen inside the corners',
                            style: AlongType.label(p).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
              // Flush to the bottom edge like a sheet; circular top corners
              // render the same on every host (superellipse AA does not).
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
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
                      // Flat bar, not LinearProgressIndicator: host-stable.
                      SizedBox(
                        key: const Key('na_me_fallback_bar'),
                        height: 4,
                        child: ColoredBox(
                          color: p.line,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 1 - fallbackProgress.clamp(0, 1),
                              heightFactor: 1,
                              child: ColoredBox(color: p.ink),
                            ),
                          ),
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
                    // Tiles share the height so the grid meets the PIN button.
                    // Short screens and large text: keep tiles tappable and
                    // let the grid scroll rather than squash.
                    final tileH = math.max(112.0, (c.maxHeight - 12) / 2);
                    return SingleChildScrollView(
                      physics: tileH * 2 + 12 > c.maxHeight
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      child: Wrap(
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
                      ),
                    );
                  },
                ),
              ),
              if (onUsePin != null) ...[
                const SizedBox(height: 16),
                AlongButton(
                  key: const Key('na_me_use_pin'),
                  label: 'Use the PIN instead',
                  variant: AlongButtonVariant.secondary,
                  onPressed: onUsePin,
                ),
              ],
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
                  child: _Shape(choice: choice, size: 72),
                ),
                const SizedBox(height: 16),
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
    final art = switch (result.verdict) {
      AlongNaMeVerdict.failed => _Art.offline,
      AlongNaMeVerdict.rateLimited => _Art.wait,
      _ => _Art.mismatch,
    };
    final title = switch (result.verdict) {
      AlongNaMeVerdict.failed => 'Couldn\'t check',
      AlongNaMeVerdict.rateLimited => 'One moment',
      AlongNaMeVerdict.locked => 'Use their PIN',
      _ => 'Not a match',
    };
    final body = switch (result.verdict) {
      AlongNaMeVerdict.rateLimited => 'Wait a few seconds, then try again.',
      AlongNaMeVerdict.failed => 'Check your connection, or use the PIN.',
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
                child: CustomPaint(
                  key: const Key('na_me_no_match_art'),
                  size: const Size(208, 112),
                  painter: _MismatchArt(
                    art: art,
                    line: p.ink,
                    fill: p.recessed,
                    soft: p.muted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                key: const Key('na_me_no_match_title'),
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
/// Two phones link around the pairing, the pairing colour blooms out in
/// one smooth ramp, an ink seal lands and a check draws on, with the haptic
/// and chime on the seal. Done in 1 s; Start is live from the first frame. The driver then sees one Start button; the rider's screen closes
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
  Timer? _beat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.progress != null) return;
      final reduced = AlongMotionPolicy.reduced(context);
      if (reduced) {
        _c.value = 1;
      } else {
        _c.forward(from: 0);
      }
      // Haptic and chime land with the seal (t ≈ 0.45), not the tap.
      _beat = Timer(reduced ? Duration.zero : AlongMoves.matchSeal, () {
        if (!mounted) return;
        AlongHaptics.match(context);
        widget.onChime?.call();
      });
      _done = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) widget.onDone?.call();
      });
    });
  }

  @override
  void dispose() {
    _done?.cancel();
    _beat?.cancel();
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
          double phase(double from, double to, [Curve c = Curves.linear]) =>
              c.transform(((t - from) / (to - from)).clamp(0.0, 1.0));
          // Linking: the two phones slide in and meet at the pairing.
          final link = phase(0, 0.3, AlongCurves.settle);
          // Bloom: one smooth ramp of the pairing colour. Not a flash.
          final bloom = phase(0.15, 0.62, Curves.easeInOutCubic);
          // Seal: an ink disc lands on the shape, then the check draws.
          final seal = phase(0.38, 0.68, Curves.easeOutBack);
          final check = phase(0.46, 0.66, Curves.easeOutQuart);
          final text = phase(0.55, 0.9, Curves.easeOutCubic);
          // The button is live from frame one: the moment never blocks.
          final button = phase(0, 0.2);
          return Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: SizedBox(
                          width: 280,
                          height: 176,
                          child: CustomPaint(
                            painter: _LinkPainter(
                              link: link,
                              bloom: bloom,
                              flood: flood,
                              line: Color.lerp(p.ink, ink, bloom)!,
                              seal: seal.clamp(0.0, 1.0),
                              // Bloom radius: reaches every corner from
                              // wherever the seal sits, at any text scale.
                              reach:
                                  MediaQuery.sizeOf(context).longestSide * 1.2,
                              ink: ink,
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 1 - seal.clamp(0.0, 1.0),
                                    child: Transform.scale(
                                      scale: 0.7 + 0.3 * link,
                                      child: _Shape(
                                        choice: widget.pairing,
                                        size: 96,
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: seal,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: ink,
                                        shape: BoxShape.circle,
                                      ),
                                      child: SizedBox.square(
                                        dimension: 120,
                                        child: CustomPaint(
                                          painter: _CheckPainter(check, flood),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - text)),
                          child: Column(
                            children: [
                              Text(
                                widget.title,
                                key: const Key('na_me_match_title'),
                                textAlign: TextAlign.center,
                                style: AlongType.display(p)
                                    .copyWith(color: ink),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.subtitle!,
                                  textAlign: TextAlign.center,
                                  style: AlongType.body(p).copyWith(
                                    color: ink.withValues(alpha: 0.86),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.onStart != null)
                        Opacity(
                          opacity: button,
                          child: _FloodButton(
                            label: widget.startLabel ?? 'Start trip',
                            ink: Color.lerp(p.ink, ink, bloom)!,
                            flood: Color.lerp(p.onInk, flood, bloom)!,
                            onTap: widget.onStart!,
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

/// Two phones slide in from the sides and meet at the pairing; three soft
/// rings ripple out as they link, then everything hands over to the bloom.
class _LinkPainter extends CustomPainter {
  _LinkPainter({
    required this.link,
    required this.bloom,
    required this.flood,
    required this.line,
    required this.seal,
    required this.ink,
    required this.reach,
  });

  final double reach;

  final double seal;
  final Color ink;
  final double link;
  final double bloom;
  final Color flood;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    // The bloom grows out of the shape itself (paints past this box).
    if (bloom > 0) {
      canvas.drawCircle(c, reach * bloom, Paint()..color = flood);
    }
    // Rest pose: two tone-on-tone halos hold the seal.
    for (final r in [80.0, 100.0]) {
      canvas.drawCircle(
        c,
        r * (0.9 + 0.1 * seal),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ink.withValues(alpha: 0.12 * seal),
      );
    }
    final fade = (1 - bloom * 1.6).clamp(0.0, 1.0);
    if (fade <= 0) return;
    // Ripples: alpha only, no luminance jump.
    for (var i = 0; i < 3; i++) {
      final r = (link - i * 0.18).clamp(0.0, 1.0);
      if (r <= 0) continue;
      canvas.drawCircle(
        c,
        56 + 64 * r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          // Flood deepened toward ink so the rings hold on light paper.
          ..color = Color.lerp(
            flood,
            line,
            0.35,
          )!.withValues(alpha: (1 - r) * 0.9 * fade),
      );
    }
    // Phones: travel from the edges to just outside the shape.
    final travel = (1 - link) * 40;
    for (final side in [-1.0, 1.0]) {
      final x = c.dx + side * (104 + travel);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, c.dy), width: 36, height: 64),
        const Radius.circular(10),
      );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = line.withValues(alpha: fade);
      canvas.drawRRect(rect, paint);
      canvas.drawLine(
        Offset(x - 6, c.dy + 24),
        Offset(x + 6, c.dy + 24),
        paint..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LinkPainter old) =>
      old.link != link ||
      old.seal != seal ||
      old.reach != reach ||
      old.ink != ink ||
      old.bloom != bloom ||
      old.flood != flood ||
      old.line != line;
}

/// What the no-match art shows: different shapes, still connecting, or a
/// short wait.
enum _Art { mismatch, offline, wait }

/// No-match art: two phones leaning apart, each showing a different shape,
/// with a soft dotted gap between them. Calm, no red, no cross.
class _MismatchArt extends CustomPainter {
  const _MismatchArt({
    required this.art,
    required this.line,
    required this.fill,
    required this.soft,
  });

  final _Art art;
  final Color line;
  final Color fill;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;
    final solid = Paint()..color = line;
    void phone(Offset c, double tilt, void Function() glyph) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 56, height: 96),
        const Radius.circular(14),
      );
      canvas.drawRRect(body, Paint()..color = fill);
      canvas.drawRRect(body, stroke);
      canvas.drawLine(const Offset(-8, 38), const Offset(8, 38), stroke);
      glyph();
      canvas.restore();
    }

    final waiting = art != _Art.mismatch;
    final tilt = waiting ? 0.0 : 0.12;
    phone(Offset(size.width * 0.2, size.height / 2), -tilt, () {
      if (waiting) return;
      canvas.drawCircle(const Offset(0, -6), 14, solid);
    });
    phone(Offset(size.width * 0.8, size.height / 2), tilt, () {
      if (waiting) return;
      canvas.drawPath(
        Path()
          ..moveTo(0, -22)
          ..lineTo(15, 6)
          ..lineTo(-15, 6)
          ..close(),
        solid,
      );
    });
    // The gap: three soft dots, the middle one slightly larger.
    final cy = size.height / 2;
    if (art == _Art.wait) {
      // A small clock in the gap: try again shortly.
      final c = Offset(size.width / 2, cy);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = soft;
      canvas.drawCircle(c, 13, ring);
      canvas.drawLine(c, c + const Offset(0, -7), ring);
      canvas.drawLine(c, c + const Offset(5, 3), ring);
      return;
    }
    final dots = Paint()..color = soft;
    for (final dx in [-16.0, 0.0, 16.0]) {
      canvas.drawCircle(Offset(size.width / 2 + dx, cy), dx == 0 ? 4 : 3, dots);
    }
  }

  @override
  bool shouldRepaint(_MismatchArt old) =>
      old.art != art ||
      old.line != line ||
      old.fill != fill ||
      old.soft != soft;
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
    this.opticalSignal,
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

  /// True while the camera sees the code's sync frame (reticle lock-on).
  final ValueListenable<bool>? opticalSignal;
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
        locked: widget.opticalSignal?.value ?? false,
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

/// Four corner brackets drawn from straight bars (crisp on every host).
/// When the camera finds the code they pull in 12 px and thicken: the
/// lock-on hint ([AlongMoves.lockOn]).
class _Reticle extends StatelessWidget {
  const _Reticle({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    final d = reduce ? Duration.zero : AlongMoves.lockOn.duration;
    final inset = locked ? 12.0 : 0.0;
    final w = locked ? 5.0 : 4.0;
    final len = locked ? 28.0 : 36.0;
    return SizedBox.square(
      key: Key(locked ? 'na_me_reticle_locked' : 'na_me_reticle'),
      dimension: 240,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: locked ? AlongColors.brandYellow : Colors.white),
        duration: reduce ? Duration.zero : AlongMoves.lockTint.duration,
        curve: AlongMoves.lockTint.curve,
        builder: (context, c, _) => AnimatedPadding(
          duration: d,
          curve: AlongMoves.lockOn.curve,
          padding: EdgeInsets.all(inset),
          child: Stack(
            children: [
              for (final a in const [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ]) ...[
                Align(
                  alignment: a,
                  child: SizedBox(
                    width: len,
                    height: w,
                    child: ColoredBox(color: c ?? Colors.white),
                  ),
                ),
                Align(
                  alignment: a,
                  child: SizedBox(
                    width: w,
                    height: len,
                    child: ColoredBox(color: c ?? Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
