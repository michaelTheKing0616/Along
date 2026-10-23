import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'demo_adapter.dart';
import 'trip_machine.dart';

void _noop() {}

/// Pickup with a detected fix, a draggable pin, and entrance chips.
class AlongFlowPickup extends StatelessWidget {
  const AlongFlowPickup({super.key});

  @override
  Widget build(BuildContext context) => const _PickupBody();
}

class _PickupBody extends StatefulWidget {
  const _PickupBody();

  @override
  State<_PickupBody> createState() => _PickupBodyState();
}

class _PickupBodyState extends State<_PickupBody> {
  DemoLandmark _landmark = DemoAdapter.landmarks.first;
  var _offset = Offset.zero;
  var _snapped = true;

  void _choose(DemoLandmark mark) {
    setState(() {
      _landmark = mark;
      _offset = Offset.zero;
      _snapped = true;
    });
    AlongHaptics.selection(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final label = _snapped ? _landmark.label : 'Dropped pin';
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              sheetInset: 0,
              bare: true,
              demoLabel: false,
              fix: AlongFix.hidden,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: _offset,
              child: GestureDetector(
                key: const Key('pickup_pin'),
                onPanUpdate: (details) {
                  setState(() {
                    _offset += details.delta;
                    _snapped = false;
                  });
                },
                child: Semantics(label: label, child: const _Pin()),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _SolidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detected · ${DemoAdapter.detected.label}',
                          key: const Key('pickup_detected'),
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.body(
                            palette,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.1),
                        ),
                      ),
                      const AlongDemoMark(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    key: const Key('pickup_label'),
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(
                      palette,
                    ).copyWith(color: palette.ink, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    DemoAdapter.gps.approximate
                        ? 'Approximate · ${DemoAdapter.gps.ageLabel}'
                        : DemoAdapter.gps.ageLabel,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _SolidCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                children: [
                  for (final mark in DemoAdapter.landmarks)
                    _LandmarkChip(
                      mark: mark,
                      selected: _snapped && mark.id == _landmark.id,
                      onTap: () => _choose(mark),
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

class _LandmarkChip extends StatelessWidget {
  const _LandmarkChip({
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  final DemoLandmark mark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: mark.label,
        child: Material(
          color: selected ? palette.ink : palette.surface,
          shape: AlongCraft.border(
            16,
            side: BorderSide(
              color: palette.ink.withValues(alpha: 0.14),
              width: 0.5,
            ),
          ),
          child: InkWell(
            key: Key('landmark_${mark.id}'),
            customBorder: AlongCraft.border(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: roomy ? 10 : 0,
                ),
                child: Row(
                  children: [
                    Icon(
                      AlongIcons.locate,
                      size: 20,
                      color: selected ? palette.onInk : palette.ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mark.label,
                        maxLines: roomy ? 2 : 1,
                        softWrap: roomy,
                        style: AlongType.body(palette).copyWith(
                          color: selected ? palette.onInk : palette.ink,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(painter: _PinPainter(fill: palette.roles.stale)),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({required this.fill});

  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawCircle(center, 10, ring);
    canvas.drawLine(
      center + const Offset(0, 10),
      center + const Offset(0, 18),
      ring,
    );
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.fill != fill;
}

/// Fare breakdown, a frozen expiry, and the cancel line.
class AlongFlowQuote extends StatelessWidget {
  const AlongFlowQuote({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final quote = DemoAdapter.quote;
    final clock = _clock(quote.expiresIn);
    return _JourneyPage(
      bottom: AlongButton(
        key: const Key('quote_accept'),
        label: 'Confirm fare',
        onPressed: _noop,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Quote', style: AlongType.display(palette))),
              const AlongDemoMark(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wuse Market to Nyanya',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _FareLine(label: 'Base', value: alongNaira(quote.baseMinor)),
          _FareLine(label: 'Seat', value: alongNaira(quote.seatMinor)),
          _FareLine(label: 'Fees', value: alongNaira(quote.feesMinor)),
          _FareLine(
            label: 'Wallet credit',
            value: alongNaira(-quote.walletCreditMinor),
          ),
          const SizedBox(height: 8),
          _FareLine(
            label: 'Total',
            value: alongNaira(quote.totalMinor),
            strong: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Expires in $clock',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette).copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            quote.cancelTerms,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _FareLine extends StatelessWidget {
  const _FareLine({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final style = (strong ? AlongType.title(palette) : AlongType.body(palette))
        .copyWith(
          fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          height: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: strong ? 40 : 32),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: roomy ? 4 : 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: roomy ? 2 : 1,
                softWrap: roomy,
                style: style,
              ),
            ),
            Text(value, maxLines: 1, softWrap: false, style: style),
          ],
        ),
      ),
    );
  }
}

/// Searching. The rings rotate when motion plays, and fade when reduced.
class AlongFlowMatching extends StatelessWidget {
  const AlongFlowMatching({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              sheetInset: 0,
              bare: true,
              demoLabel: false,
              fix: AlongFix.hidden,
            ),
          ),
          const Align(alignment: Alignment(0, 0.2), child: _SearchPulse()),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _SolidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Looking nearby',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.title(palette).copyWith(height: 1.1),
                        ),
                      ),
                      const AlongDemoMark(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wuse Market',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette)
                        .copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 12),
                  const AlongButton(
                    key: Key('cancel_search'),
                    label: 'Cancel search',
                    variant: AlongButtonVariant.secondary,
                    onPressed: _noop,
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

class _SearchPulse extends StatefulWidget {
  const _SearchPulse();

  @override
  State<_SearchPulse> createState() => _SearchPulseState();
}

class _SearchPulseState extends State<_SearchPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: AlongDurations.hold,
      value: 0.35,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = AlongMotionPolicy.reduced(context);
    // One rest pose. "Looking nearby" is the status, not a loop.
    _motion.value = reduced ? 0.2 : 0.35;
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final reduced = AlongMotionPolicy.reduced(context);
        final play = AlongMotionPolicy.play(context);
        final t = _motion.value;
        final opacity = reduced ? 0.35 + 0.65 * t : 1.0;
        final angle = (!reduced && play) ? t * math.pi * 2 : 0.0;
        return Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: angle,
            child: CustomPaint(
              size: const Size(128, 128),
              painter: _RingPainter(color: palette.ink),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.28);
    canvas.drawCircle(center, 28, paint);
    canvas.drawCircle(center, 46, paint..color = color.withValues(alpha: 0.16));
    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// No driver. Widen, schedule, or switch to keke.
class AlongFlowRecovery extends StatelessWidget {
  const AlongFlowRecovery({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              sheetInset: 0,
              bare: true,
              demoLabel: false,
              fix: AlongFix.approximate,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _SolidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'No driver yet',
                          maxLines: 1,
                          softWrap: false,
                          style: AlongType.title(palette).copyWith(height: 1.1),
                        ),
                      ),
                      const AlongDemoMark(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AlongButton(
                    key: Key('widen_radius'),
                    label: 'Widen radius',
                    onPressed: _noop,
                  ),
                  const SizedBox(height: 8),
                  const AlongButton(
                    key: Key('schedule_ride'),
                    label: 'Schedule',
                    variant: AlongButtonVariant.secondary,
                    onPressed: _noop,
                  ),
                  const SizedBox(height: 8),
                  const AlongButton(
                    key: Key('try_keke'),
                    label: 'Try keke',
                    variant: AlongButtonVariant.secondary,
                    onPressed: _noop,
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

/// Rider side of the 4-digit start PIN.
class AlongFlowTripPin extends StatelessWidget {
  const AlongFlowTripPin({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _JourneyPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Trip PIN', style: AlongType.display(palette)),
              ),
              const AlongDemoMark(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wuse Market to Nyanya',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Show this when the driver arrives',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette),
          ),
          const SizedBox(height: 24),
          const Center(child: _PinReadout(code: DemoAdapter.pin)),
        ],
      ),
    );
  }
}

class _PinReadout extends StatelessWidget {
  const _PinReadout({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return _PinSlots(code: code);
  }
}

class _PinSlots extends StatelessWidget {
  const _PinSlots({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final slots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _PinBox(digit: i < code.length ? code[i] : ''),
        ],
      ],
    );
    return Semantics(
      label: 'Trip PIN ${code.split('').join(' ')}',
      child: _roomy(context) ? FittedBox(child: slots) : slots,
    );
  }
}

class _PinBox extends StatelessWidget {
  const _PinBox({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final scale = _roomy(context)
        ? MediaQuery.textScalerOf(context).scale(1)
        : 1.0;
    return DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: 12, hairline: true),
      child: SizedBox(
        width: 56 * scale,
        height: 64 * scale,
        child: Center(
          child: Text(
            digit,
            maxLines: 1,
            softWrap: false,
            style: AlongType.numeric(palette).copyWith(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

/// Driver steps: arrived, PIN, start, complete. The golden rests on PIN.
class AlongFlowDriver extends StatelessWidget {
  const AlongFlowDriver({super.key});

  @override
  Widget build(BuildContext context) => const _DriverBody();
}

class _DriverBody extends StatefulWidget {
  const _DriverBody();

  @override
  State<_DriverBody> createState() => _DriverBodyState();
}

class _DriverBodyState extends State<_DriverBody> {
  var _phase = TripArrivedPhase(pin: DemoAdapter.pin);
  var _digits = DemoAdapter.pin;

  void _press(String key) {
    setState(() {
      if (key == 'del') {
        if (_digits.isNotEmpty) {
          _digits = _digits.substring(0, _digits.length - 1);
        }
      } else if (_digits.length < 4) {
        _digits += key;
      }
    });
    AlongHaptics.selection(context);
  }

  void _verify() {
    final next = TripMachine.reduce(_phase, PinSubmitted(_digits));
    if (next is! TripArrivedPhase) return;
    setState(() => _phase = next);
    if (next.verified) AlongHaptics.success(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final verified = _phase.verified;
    final roomy = _roomy(context);
    return _JourneyPage(
      bottom: AlongButton(
        key: const Key('verify_pin'),
        label: verified ? 'PIN matched' : 'Verify PIN',
        onPressed: verified ? null : _verify,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your trip', style: AlongType.display(palette)),
              ),
              const AlongDemoMark(),
            ],
          ),
          const SizedBox(height: 8),
          const _DriverSteps(),
          const SizedBox(height: 8),
          Text(
            'Enter the rider\'s PIN',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Center(child: _PinSlots(code: _digits)),
          if (_phase.rejected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(AlongIcons.close, size: 20, color: palette.roles.error),
                const SizedBox(width: 6),
                Text(
                  'Wrong PIN',
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.caption(
                    palette,
                  ).copyWith(color: palette.ink, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (!roomy) const Spacer(),
          _Keypad(onKey: _press),
        ],
      ),
    );
  }
}

class _DriverSteps extends StatelessWidget {
  const _DriverSteps();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    const steps = ['Arrived', 'PIN', 'Start', 'Done'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Icon(
                  i < 1
                      ? AlongIcons.check
                      : i == 1
                      ? AlongIcons.verified
                      : AlongIcons.caretRight,
                  size: 16,
                  color: i <= 1 ? palette.ink : palette.muted,
                ),
                Text(
                  steps[i],
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: AlongType.caption(palette).copyWith(
                    color: i == 1
                        ? palette.ink
                        : i < 1
                        ? palette.ink
                        : palette.muted,
                    fontWeight: i == 1 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _KeyCap(label: key, onKey: onKey),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label, required this.onKey});

  final String label;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    if (label.isEmpty) return const SizedBox(height: 48);
    final del = label == 'del';
    return Semantics(
      button: true,
      label: del ? 'Delete' : label,
      child: Material(
        color: palette.surface,
        shape: AlongCraft.border(12),
        child: InkWell(
          customBorder: AlongCraft.border(12),
          onTap: () => onKey(label),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: roomy ? 8 : 0),
              child: Center(
                child: del
                    ? Icon(AlongIcons.close, size: 20, color: palette.ink)
                    : Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.title(palette).copyWith(height: 1),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Driving. One ETA range, one stale-GPS line, no extra chrome.
class AlongFlowNav extends StatelessWidget {
  const AlongFlowNav({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final gps = DemoAdapter.gps;
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.trip,
              progress: 0.42,
              sheetInset: 0.18,
              fix: AlongFix.stale,
              demoLabel: false,
            ),
          ),
          const Positioned(top: 12, right: 12, child: AlongDemoMark()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _SolidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gps.etaLabel,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.display(palette),
                  ),
                  Text(
                    'Nyanya',
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.body(palette)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    gps.ageLabel,
                    maxLines: 1,
                    softWrap: false,
                    style: AlongType.caption(palette)
                        .copyWith(color: palette.ink),
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

/// Receipt, the seat motif, and the issue entry.
class AlongFlowReceipt extends StatelessWidget {
  const AlongFlowReceipt({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final quote = DemoAdapter.quote;
    return _JourneyPage(
      bottom: const AlongButton(
        key: Key('report_issue'),
        label: 'Report an issue',
        variant: AlongButtonVariant.secondary,
        onPressed: _noop,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Receipt', style: AlongType.display(palette)),
              ),
              const AlongDemoMark(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Wuse Market to Nyanya',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const AlongSeatCount(count: 2, glyph: 16),
          const SizedBox(height: 8),
          const Center(
            child: AlongCabinDiagram(
              seat: 36,
              rows: [
                ['driver', 'free', 'free'],
                ['occupied', 'yours', 'free'],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _FareLine(
            label: 'Total',
            value: alongNaira(quote.totalMinor),
            strong: true,
          ),
          Text(
            DemoAdapter.payment.label,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(color: palette.ink),
          ),
        ],
      ),
    );
  }
}

/// The interrupted states, each a solid one-line banner.
class AlongFlowNotices extends StatelessWidget {
  const AlongFlowNotices({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _JourneyPage(
      bottom: const AlongButton(
        key: Key('notices_retry'),
        label: 'Try again',
        onPressed: _noop,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notices', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'One notice at a time in the app',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          for (final notice in DemoAdapter.notices) ...[
            _NoticeBanner(label: notice.label),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final role = _noticeRole(palette, label);
    final roomy = _roomy(context);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: AlongCraft.surface(palette, radius: 12, hairline: true),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: roomy ? 8 : 0,
            ),
            child: Row(
              children: [
                Icon(role.icon, size: 20, color: role.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: roomy ? 3 : 1,
                    softWrap: roomy,
                    style: AlongType.body(palette)
                        .copyWith(fontWeight: FontWeight.w600, height: 1.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeRole {
  const _NoticeRole(this.icon, this.color);

  final IconData icon;
  final Color color;
}

_NoticeRole _noticeRole(AlongPalette palette, String label) {
  final roles = palette.roles;
  return switch (label) {
    'Location denied' => _NoticeRole(AlongIcons.close, roles.error),
    'Location is approximate' => _NoticeRole(AlongIcons.locate, roles.warn),
    'Offline · poor network' => _NoticeRole(AlongIcons.info, roles.stale),
    'Driver cancelled the trip' => _NoticeRole(AlongIcons.user, roles.error),
    'Quote changed · review it' => _NoticeRole(AlongIcons.tag, roles.warn),
    'Payment failed' => _NoticeRole(AlongIcons.wallet, roles.error),
    'Welcome back' => _NoticeRole(AlongIcons.check, roles.success),
    _ => _NoticeRole(AlongIcons.info, roles.stale),
  };
}

/// Haptics toggle. Reduce motion is the system setting; this screen says
/// what the app does with it.
class AlongFlowSettings extends StatelessWidget {
  const AlongFlowSettings({super.key});

  @override
  Widget build(BuildContext context) => const _SettingsBody();
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final reduced = AlongMotionPolicy.reduced(context);
    final roomy = _roomy(context);
    return _JourneyPage(
      bottom: AlongButton(
        key: const Key('haptics_try'),
        label: 'Test haptic',
        variant: AlongButtonVariant.secondary,
        onPressed: () => AlongHaptics.success(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AlongType.display(palette)),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: AlongCraft.surface(palette, radius: 16, hairline: true),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: roomy ? 8 : 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Haptics',
                        maxLines: 1,
                        softWrap: false,
                        style: AlongType.body(palette)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      height: 48,
                      child: FittedBox(
                        child: Switch(
                          key: const Key('haptics_switch'),
                          value: AlongHaptics.enabled,
                          onChanged: (value) {
                            setState(() => AlongHaptics.enabled = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reduced ? 'Reduce motion is on' : 'Reduce motion uses fades',
            maxLines: roomy ? 2 : 1,
            softWrap: roomy,
            style: AlongType.caption(palette).copyWith(color: palette.ink),
          ),
        ],
      ),
    );
  }
}

class _JourneyPage extends StatelessWidget {
  const _JourneyPage({required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (roomy)
                Expanded(child: SingleChildScrollView(child: child))
              else
                Expanded(child: child),
              if (bottom != null) ...[const SizedBox(height: 12), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

bool _roomy(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.15;

class _SolidCard extends StatelessWidget {
  const _SolidCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        palette,
        radius: 20,
        shadow: AlongElevation.sheet(palette.ink),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

String _clock(Duration duration) {
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
