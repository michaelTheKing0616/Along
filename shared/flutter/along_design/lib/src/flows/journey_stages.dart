import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../components/along_button.dart';
import '../components/seat_map.dart';
import '../craft.dart';
import '../elevation.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';
import 'city_map.dart';
import 'delights.dart';
import 'live_arrival.dart';
import 'demo_adapter.dart';
import 'driver_portrait.dart';
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
  final _map = MapController();
  DemoLandmark _landmark = DemoAdapter.landmarks.first;
  var _dropped = false;
  var _lifted = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _choose(DemoLandmark mark) {
    setState(() {
      _landmark = mark;
      _dropped = false;
      _lifted = false;
    });
    _moveTo(LatLng(mark.lat, mark.lng));
    AlongHaptics.selection(context);
  }

  void _moveTo(LatLng at) {
    try {
      _map.move(at, _map.camera.zoom);
    } catch (_) {}
  }

  /// The pin stays put. The finger drags the map that sits under it.
  void _panBy(Offset delta) {
    try {
      final camera = _map.camera;
      final screenCenter = camera.nonRotatedSize.center(Offset.zero);
      final next = camera.screenOffsetToLatLng(screenCenter - delta);
      _map.move(next, camera.zoom);
    } catch (_) {}
  }

  void _settle() {
    DemoLandmark? hit;
    try {
      final at = _map.camera.center;
      hit = DemoAdapter.snap(at.latitude, at.longitude);
    } catch (_) {}
    setState(() {
      _lifted = false;
      if (hit == null) {
        _dropped = true;
      } else {
        _dropped = false;
        _landmark = hit;
      }
    });
    if (hit != null) _moveTo(LatLng(hit.lat, hit.lng));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final play = AlongMotionPolicy.play(context);
    final label = _dropped ? 'Dropped pin' : _landmark.label;
    final gate = DemoAdapter.landmarks.first;
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AlongCityMap(
              controller: _map,
              center: LatLng(gate.lat, gate.lng),
              zoom: 17,
              sheetInset: 0,
              bare: true,
              place: true,
              demoLabel: false,
              fix: AlongFix.hidden,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              key: const Key('pickup_pin'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) {
                if (!_lifted) setState(() => _lifted = true);
              },
              onPanUpdate: (details) => _panBy(details.delta),
              onPanEnd: (_) => _settle(),
              onPanCancel: _settle,
              child: AnimatedSlide(
                offset: play && _lifted ? const Offset(0, -0.28) : Offset.zero,
                duration: play ? AlongDurations.sheet : Duration.zero,
                curve: AlongCurves.settle,
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
                      selected: !_dropped && mark.id == _landmark.id,
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
            AlongRadius.control.x,
            side: BorderSide(
              color: palette.ink.withValues(alpha: 0.14),
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('landmark_${mark.id}'),
            customBorder: AlongCraft.border(AlongRadius.control.x),
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
    final clock = _mmss(quote.expiresIn);
    final roomy = _roomy(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.trip,
              progress: 0,
              sheetInset: 0.62,
              demoLabel: false,
            ),
          ),
          _AnchoredSheet(
            child: _SolidCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quote', style: AlongType.title(palette)),
                  const SizedBox(height: 4),
                  Text(
                    'Wuse Market to Nyanya',
                    maxLines: roomy ? 2 : 1,
                    softWrap: roomy,
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
                  AlongFareLock(
                    clock: clock,
                    progress: quote.expiresIn.inSeconds / 120,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quote.cancelTerms,
                    maxLines: roomy ? 2 : 1,
                    softWrap: roomy,
                    style: AlongType.caption(palette)
                        .copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: 12),
                  const AlongButton(
                    key: Key('quote_accept'),
                    label: 'Confirm fare',
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
      constraints: BoxConstraints(
        minHeight: strong ? 40 : 32,
      ),
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
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              center: AlongCityMap.wuseMarket,
              sheetInset: 0,
              bare: true,
              demoLabel: false,
              fix: AlongFix.approximate,
              nearby: true,
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

/// No driver. Widen, schedule, or switch to keke.
class AlongFlowRecovery extends StatelessWidget {
  const AlongFlowRecovery({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final secondary = [
      const AlongButton(
        key: Key('schedule_ride'),
        label: 'Schedule',
        variant: AlongButtonVariant.secondary,
        onPressed: _noop,
      ),
      const AlongButton(
        key: Key('try_keke'),
        label: 'Try keke',
        variant: AlongButtonVariant.secondary,
        onPressed: _noop,
      ),
    ];
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              center: AlongCityMap.wuseMarket,
              sheetInset: 0,
              bare: true,
              demoLabel: false,
              fix: AlongFix.approximate,
              nearby: true,
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
                  if (roomy) ...[
                    for (final button in secondary) ...[
                      button,
                      const SizedBox(height: 8),
                    ],
                  ] else
                    Row(
                      children: [
                        for (var i = 0; i < secondary.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: secondary[i]),
                        ],
                      ],
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

/// Rider side of the 4-digit start PIN. A live approach map sits on top.
/// The driver card follows it, so the page does not open on empty paper.
class AlongFlowTripPin extends StatelessWidget {
  const AlongFlowTripPin({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final short = MediaQuery.sizeOf(context).height < 700;
    final handoff = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipPath(
          clipper: ShapeBorderClipper(
            shape: AlongCraft.border(AlongRadius.card.x),
          ),
          child: SizedBox(
            height: short ? 156 : 196,
            width: double.infinity,
            child: const AlongCityMap(
              center: AlongCityMap.approachCenter,
              zoom: AlongCityMap.approachZoom,
              progress: 0.52,
              sheetInset: 0,
              bare: true,
              approach: true,
              demoLabel: false,
              fix: AlongFix.hidden,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _PinDriverCard(),
        const SizedBox(height: 16),
        Text(
          'Share this with Chinedu',
          maxLines: roomy ? 2 : 1,
          softWrap: roomy,
          textAlign: TextAlign.center,
          style: AlongType.body(palette).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          _clock(DemoAdapter.pinFor),
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette)
              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 12),
        const _PinReadout(code: DemoAdapter.pin),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy
              ? SingleChildScrollView(child: handoff)
              : Align(alignment: Alignment.topCenter, child: handoff),
        ),
      ),
    );
  }
}

class _PinDriverCard extends StatelessWidget {
  const _PinDriverCard();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AlongDriverPortrait(size: 48, verified: true),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Chinedu',
                maxLines: 1,
                softWrap: false,
                style: AlongType.title(palette).copyWith(height: 1.1),
              ),
            ),
            const AlongDemoMark(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'ABC-123-XY',
          maxLines: 1,
          softWrap: false,
          style: AlongType.title(palette).copyWith(
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
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
  const _PinSlots({required this.code, this.compact = false});

  final String code;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final slots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _PinBox(digit: i < code.length ? code[i] : '', compact: compact),
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
  const _PinBox({required this.digit, this.compact = false});

  final String digit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final scale = _roomy(context)
        ? MediaQuery.textScalerOf(context).scale(1)
        : 1.0;
    final wide = MediaQuery.sizeOf(context).width >= 340;
    final width = compact ? (wide ? 64 : 56) : (wide ? 72 : 62);
    final height = compact ? 56 : (wide ? 112 : 96);
    return DecoratedBox(
      decoration: AlongCraft.surface(
        palette,
        radius: AlongRadius.control.x,
        hairline: true,
      ),
      child: SizedBox(
        width: width * (compact ? 1 : scale),
        height: height * (compact ? 1 : scale),
        child: Center(
          child: Text(
            digit,
            maxLines: 1,
            softWrap: false,
            style: compact
                ? AlongType.title(palette).copyWith(
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )
                : AlongType.numeric(palette),
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
    final column = Column(
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
          style: AlongType.body(palette).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Center(child: _PinSlots(code: _digits, compact: true)),
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
                style: AlongType.caption(palette)
                    .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _Keypad(onKey: _press),
        const SizedBox(height: 12),
        AlongButton(
          key: const Key('verify_pin'),
          label: verified ? 'PIN matched' : 'Verify PIN',
          onPressed: verified ? null : _verify,
        ),
      ],
    );
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: SingleChildScrollView(child: column),
        ),
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
                  size: 20,
                  color: i <= 1
                      ? palette.ink
                      : palette.ink.withValues(alpha: 0.72),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: AlongType.label(palette).copyWith(
                    color: i <= 1
                        ? palette.ink
                        : palette.ink.withValues(alpha: 0.72),
                    fontWeight: i == 1 ? FontWeight.w600 : FontWeight.w500,
                    height: 1.1,
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

class _KeyCap extends StatefulWidget {
  const _KeyCap({required this.label, required this.onKey});

  final String label;
  final ValueChanged<String> onKey;

  @override
  State<_KeyCap> createState() => _KeyCapState();
}

class _KeyCapState extends State<_KeyCap> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final play = AlongMotionPolicy.play(context);
    if (widget.label.isEmpty) return const SizedBox(height: 48);
    final del = widget.label == 'del';
    final dark = palette.brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF3A342C) : const Color(0xFFFFFDF8);
    final shape = AlongCraft.border(
      AlongRadius.control.x,
      side: BorderSide(
        color: palette.ink.withValues(alpha: dark ? 0.55 : 0.32),
        width: 1,
      ),
    );
    return Semantics(
      button: true,
      label: del ? 'Delete' : widget.label,
      child: AnimatedScale(
        scale: _down && play ? 0.96 : 1,
        duration: play ? AlongDurations.press : Duration.zero,
        curve: AlongCurves.settle,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: fill,
            shadows: AlongElevation.rest(palette.ink),
            shape: shape,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: shape,
              onTapDown: (_) {
                if (!_down) setState(() => _down = true);
              },
              onTapCancel: () {
                if (_down) setState(() => _down = false);
              },
              onTap: () {
                if (_down) setState(() => _down = false);
                widget.onKey(widget.label);
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: roomy ? 8 : 0),
                  child: Center(
                    child: del
                        ? AlongIcon(
                            AlongIcons.close,
                            size: 20,
                            color: palette.ink,
                          )
                        : Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            style: AlongType.title(palette).copyWith(height: 1),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Turn-by-turn. The maneuver is the top banner. Speed and ETA share the bar.
class AlongFlowNav extends StatelessWidget {
  const AlongFlowNav({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final maneuver = DemoAdapter.maneuver;
    final roomy = _roomy(context);
    return Scaffold(
      backgroundColor: palette.mapLand,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AlongCityMap(
              mode: AlongCityMapMode.nav,
              progress: 0.28,
              fix: AlongFix.stale,
              demoLabel: false,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _ManeuverBanner(
              street: maneuver.street,
              distance: maneuver.distanceLabel,
              roomy: roomy,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _SpeedBar(
              speed: maneuver.speedLabel,
              eta: DemoAdapter.gps.etaLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManeuverBanner extends StatelessWidget {
  const _ManeuverBanner({
    required this.street,
    required this.distance,
    required this.roomy,
  });

  final String street;
  final String distance;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return _SolidCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _StraightArrow(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  distance,
                  maxLines: 1,
                  softWrap: false,
                  style: AlongType.display(palette).copyWith(height: 1),
                ),
              ),
              const SizedBox(width: 8),
              const AlongDemoMark(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            street,
            maxLines: roomy ? 2 : 1,
            softWrap: roomy,
            style: AlongType.title(palette).copyWith(height: 1.1),
          ),
        ],
      ),
    );
  }
}

class _StraightArrow extends StatelessWidget {
  const _StraightArrow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return CustomPaint(
      size: const Size(56, 56),
      painter: _StraightArrowPainter(color: palette.ink),
    );
  }
}

class _StraightArrowPainter extends CustomPainter {
  const _StraightArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mid = size.width / 2;
    final head = Path()
      ..moveTo(mid - 16, 22)
      ..lineTo(mid, 8)
      ..lineTo(mid + 16, 22);
    canvas.drawPath(head, paint);
    canvas.drawLine(Offset(mid, 18), Offset(mid, size.height - 6), paint);
  }

  @override
  bool shouldRepaint(covariant _StraightArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SpeedBar extends StatelessWidget {
  const _SpeedBar({required this.speed, required this.eta});

  final String speed;
  final String eta;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final value = AlongType.title(palette).copyWith(height: 1.1);
    final caption = AlongType.caption(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w600);
    return _SolidCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speed, maxLines: 1, softWrap: false, style: value),
                Text('Speed', maxLines: 1, softWrap: false, style: caption),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(eta, maxLines: 1, softWrap: false, style: value),
                Text('Nyanya', maxLines: 1, softWrap: false, style: caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt. The route heads the page. Fare, payment, seat, timeline, and
/// the rating follow as one column, then download, share, and the issue.
class AlongFlowReceipt extends StatelessWidget {
  const AlongFlowReceipt({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final quote = DemoAdapter.quote;
    final roomy = _roomy(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receipt', style: AlongType.display(palette)),
              Text(
                'Wuse Market to Nyanya',
                maxLines: roomy ? 2 : 1,
                softWrap: roomy,
                style: AlongType.body(palette)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Fare'),
              _FareLine(label: 'Base', value: alongNaira(quote.baseMinor)),
              _FareLine(label: 'Seat', value: alongNaira(quote.seatMinor)),
              _FareLine(label: 'Fees', value: alongNaira(quote.feesMinor)),
              _FareLine(
                label: 'Wallet credit',
                value: alongNaira(-quote.walletCreditMinor),
              ),
              _FareLine(
                label: 'Total',
                value: alongNaira(quote.totalMinor),
                strong: true,
              ),
              _IconLine(icon: AlongIcons.wallet, label: 'Wallet'),
              const SizedBox(height: 24),
              const _SectionLabel('Trip'),
              const _TimelineRow(label: 'Requested 14:02'),
              const _TimelineRow(label: 'Pickup Wuse Market'),
              const _TimelineRow(label: 'Drop Nyanya', last: true),
              const SizedBox(height: 12),
              const _ReceiptSeats(),
              const SizedBox(height: 8),
              const _RatingSummary(),
              const SizedBox(height: 8),
              const _LostItemRow(),
              const SizedBox(height: 24),
              const AlongButton(
                key: Key('report_issue'),
                label: 'Report an issue',
                variant: AlongButtonVariant.secondary,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptSeats extends StatelessWidget {
  const _ReceiptSeats();

  @override
  Widget build(BuildContext context) {
    const seats = ['driver', 'free', 'free', 'occupied', 'yours', 'free'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IconLine(icon: AlongIcons.seat, label: 'Window seat'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final side = ((constraints.maxWidth - gap * 5) / 6).clamp(
              28.0,
              40.0,
            );
            return Row(
              children: [
                for (var i = 0; i < seats.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  AlongSeatGlyph(status: seats[i], width: side),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LostItemRow extends StatelessWidget {
  const _LostItemRow();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      key: const Key('lost_item'),
      height: 44,
      child: Row(
        children: [
          AlongIcon(AlongIcons.receipt, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Report a lost item',
              maxLines: 1,
              softWrap: false,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AlongType.caption(palette)
            .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: roomy ? 2 : 1,
              softWrap: roomy,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.label, this.last = false});

  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        children: [
          Icon(
            last ? AlongIcons.locate : AlongIcons.check,
            size: 16,
            color: palette.ink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: roomy ? 2 : 1,
              softWrap: roomy,
              style: AlongType.body(palette),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Icon(AlongIcons.star, size: 16, color: palette.ink),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'You rated Chinedu',
            maxLines: 1,
            softWrap: false,
            style: AlongType.body(palette)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// The interrupted states, each a solid one-line banner.
class AlongFlowNotices extends StatelessWidget {
  const AlongFlowNotices({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    final primary = DemoAdapter.notices
        .where((notice) => notice.label == 'Payment failed')
        .map((notice) => notice.label)
        .first;
    final rest = [
      for (final notice in DemoAdapter.notices)
        if (notice.label != primary) notice.label,
    ];
    return _TopCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notices', style: AlongType.display(palette)),
          const SizedBox(height: 4),
          Text(
            'One notice at a time in the app',
            maxLines: roomy ? 2 : 1,
            softWrap: roomy,
            style: AlongType.caption(palette).copyWith(color: palette.ink),
          ),
          const SizedBox(height: 12),
          _SolidCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NoticeBanner(label: primary),
                const SizedBox(height: 12),
                const AlongButton(
                  key: Key('notices_retry'),
                  label: 'Try again',
                  onPressed: _noop,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final label in rest) ...[
            _QuietNotice(label: label),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _QuietNotice extends StatelessWidget {
  const _QuietNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final role = _noticeRole(palette, label);
    final roomy = _roomy(context);
    return Semantics(
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          children: [
            AlongIcon(role.icon, size: 20, color: role.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: roomy ? 2 : 1,
                softWrap: roomy,
                style: AlongType.caption(palette).copyWith(
                  color: palette.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
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
        decoration: AlongCraft.surface(
          palette,
          radius: AlongRadius.row.x,
          hairline: true,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: roomy ? 8 : 0,
            ),
            child: Row(
              children: [
                AlongIcon(role.icon, size: 20, color: role.color),
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

/// Grouped settings. Haptics is the live control. The other rows are the
/// account, payment, safety, access, language, and about groups.
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
    final motion = reduced ? 'Reduce motion is on' : 'Reduce motion uses fades';
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: AlongType.display(palette)),
              const SizedBox(height: 8),
              const _SettingsGroup(
                title: 'Account',
                rows: [_SettingsRow(icon: AlongIcons.user, label: 'Adaeze')],
              ),
              const _SettingsGroup(
                title: 'Payment',
                rows: [
                  _SettingsRow(icon: AlongIcons.wallet, label: 'Demo payment'),
                ],
              ),
              const _SettingsGroup(
                title: 'Safety',
                rows: [
                  _SettingsRow(
                    icon: AlongIcons.shield,
                    label: 'Trusted contacts',
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Accessibility',
                rows: [
                  _SettingsRow(
                    icon: AlongIcons.info,
                    label: motion,
                    roomy: roomy,
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Haptics',
                rows: [
                  _SettingsRow(
                    icon: AlongIcons.verified,
                    label: 'Haptics',
                    trailing: SizedBox(
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
                  ),
                ],
              ),
              AlongButton(
                key: const Key('haptics_try'),
                label: 'Test haptic',
                variant: AlongButtonVariant.secondary,
                onPressed: () => AlongHaptics.success(context),
              ),
              const SizedBox(height: 8),
              const _SettingsGroup(
                title: 'Language',
                rows: [_SettingsRow(icon: AlongIcons.chat, label: 'English')],
              ),
              const _SettingsGroup(
                title: 'About',
                rows: [_SettingsRow(icon: AlongIcons.info, label: 'Along')],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette)
                .copyWith(color: palette.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          _SolidCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.roomy = false,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final bool roomy;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          AlongIcon(icon, size: 20, color: palette.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: roomy ? 2 : 1,
              softWrap: roomy,
              style: AlongType.body(palette)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _AnchoredSheet extends StatelessWidget {
  const _AnchoredSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: SingleChildScrollView(reverse: true, child: child),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final roomy = _roomy(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: roomy
              ? SingleChildScrollView(child: child)
              : Align(alignment: Alignment.topCenter, child: child),
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
        radius: AlongRadius.card.x,
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

String _mmss(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
