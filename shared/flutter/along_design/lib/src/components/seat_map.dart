import 'dart:math' as math;

import 'package:along_design/src/elevation.dart';
import 'package:along_design/src/motion.dart';
import 'package:along_design/src/palette.dart';
import 'package:along_design/src/tokens.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// One seat on a driver-built diagram. [statusWord] is already translated.
class SeatMapSeat {
  const SeatMapSeat({
    required this.id,
    required this.label,
    required this.role,
    required this.status,
    required this.statusWord,
    this.price,
  });

  final String id;
  final String label;
  final String? price;

  /// `driver`, `passenger`, or `cargo`. Driver and cargo seats are not claimable.
  final String role;
  final String status;
  final String statusWord;

  bool get isDriver => role == 'driver';

  bool get isCargo => role == 'cargo';

  bool get isClaimable => role == 'passenger';
}

class SeatMapRowView {
  const SeatMapRowView({required this.id, required this.seats, this.ruleTitle});

  final String id;
  final List<SeatMapSeat> seats;

  /// Driver-authored title for a rule attached to this row, when there is one.
  final String? ruleTitle;
}

/// Top-down seat diagram. Chrome follows the layout `body` token.
class SeatMap extends StatelessWidget {
  const SeatMap({
    super.key,
    required this.body,
    required this.rows,
    this.onSeatTap,
    this.onSeatLongPress,
  });

  final String body;
  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final rules = <Widget>[
      for (final row in rows)
        if (row.ruleTitle != null && row.ruleTitle!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AlongSpace.s8),
            child: Text(
              row.ruleTitle!,
              key: Key('seat_row_rule_${row.id}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: AlongText.caption.copyWith(
                color: palette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
    ];
    // The cabin is drawn. A photograph cannot follow an arbitrary
    // rows × seats layout. Keke, bike, and coach stay on their silhouettes.
    final diagram = body == 'cabin'
        ? _CabinShell(
            rows: rows,
            onSeatTap: onSeatTap,
            onSeatLongPress: onSeatLongPress,
          )
        : _SchematicBody(
            body: body,
            rows: rows,
            onSeatTap: onSeatTap,
            onSeatLongPress: onSeatLongPress,
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(body == 'bike' ? 36 : 24),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // A vertical flex does not pass its max height to non-flex
            // children. The drawn cabin fills a bounded card. Schematic
            // bodies keep an intrinsic height.
            final fitCabin = body == 'cabin' && constraints.maxHeight.isFinite;
            return Column(
              mainAxisSize: fitCabin ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: fitCabin
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: [
                ...rules,
                if (fitCabin) Expanded(child: diagram) else diagram,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SchematicBody extends StatelessWidget {
  const _SchematicBody({
    required this.body,
    required this.rows,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final String body;
  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: Image.asset(
              _silhouetteAsset(body),
              package: 'along_design',
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              opacity: const AlwaysStoppedAnimation(0.9),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(28, body == 'bike' ? 28 : 48, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      for (final seat in row.seats) ...[
                        if (seat.isDriver && body != 'bike')
                          const _SteeringWheel(),
                        Expanded(
                          child: _SeatButton(
                            seat: seat,
                            onTap: seat.isClaimable ? onSeatTap : null,
                            onLongPress: seat.isClaimable
                                ? onSeatLongPress
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Drawn cabin. Nose up, wheel on the left. Two rows stay a sedan.
/// Three or more rows lengthen into a danfo. Every configured seat is
/// one cushion; the count comes from the row list.
class _CabinShell extends StatelessWidget {
  const _CabinShell({
    required this.rows,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  bool get _van => rows.length >= 3;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final width = maxW;
        final height = maxH.isFinite ? maxH : width * (_van ? 1.9 : 1.55);
        final frame = _CabinFrame(van: _van);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CarPainter(palette: palette, van: _van),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  width * frame.left,
                  height * frame.top,
                  width * (1 - frame.right),
                  height * (1 - frame.bottom),
                ),
                child: Column(
                  children: [
                    for (final row in rows)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: _SeatRow(
                            seats: _driverFirst(row.seats),
                            van: _van,
                            onSeatTap: onSeatTap,
                            onSeatLongPress: onSeatLongPress,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<SeatMapSeat> _driverFirst(List<SeatMapSeat> seats) {
    return [
      for (final seat in seats)
        if (seat.isDriver) seat,
      for (final seat in seats)
        if (!seat.isDriver) seat,
    ];
  }
}

/// Where the cushions sit inside the drawn body, as fractions of the shell.
class _CabinFrame {
  const _CabinFrame({required this.van});

  final bool van;

  double get left => van ? 0.16 : 0.18;
  double get right => van ? 0.84 : 0.82;
  double get top => van ? 0.12 : 0.23;
  double get bottom => van ? 0.95 : 0.93;
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.seats,
    required this.van,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<SeatMapSeat> seats;
  final bool van;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = seats.length;
        if (count == 0) return const SizedBox.shrink();
        const gap = 6.0;
        final aisle = van && count >= 4 ? constraints.maxWidth * 0.07 : 0.0;
        final seatW = math.max(
          0.0,
          (constraints.maxWidth - gap * (count - 1) - aisle - 1) / count,
        );
        final height = constraints.maxHeight;
        return Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0)
                SizedBox(width: van && i == count ~/ 2 ? gap + aisle : gap),
              SizedBox(
                width: seatW,
                height: height,
                child: _SeatButton(
                  seat: seats[i],
                  markHeight: height,
                  driverIcon: true,
                  onTap: seats[i].isClaimable ? onSeatTap : null,
                  onLongPress: seats[i].isClaimable ? onSeatLongPress : null,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter({required this.palette, required this.van});

  final AlongPalette palette;
  final bool van;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final body = dark ? const Color(0xFF2A2C33) : const Color(0xFF24262C);
    final edge = dark ? const Color(0xFF4A4C55) : const Color(0xFF121318);
    final tire = dark ? const Color(0xFF0A0A0C) : const Color(0xFF141416);
    final hub = dark ? const Color(0xFF8A8A94) : const Color(0xFFD5D7DC);
    final glass = dark ? const Color(0xFF243140) : const Color(0xFFD7E1EC);
    final dash = dark ? const Color(0xFF3A3C44) : const Color(0xFF3C3E46);
    final interiorTop = dark
        ? const Color(0xFF1C1D22)
        : const Color(0xFFF4F6F8);
    final interiorBottom = dark
        ? const Color(0xFF121316)
        : const Color(0xFFE3E6EB);

    final ground = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.54),
      width: size.width * 0.78,
      height: size.height * (van ? 0.86 : 0.72),
    );
    canvas.drawOval(
      ground,
      Paint()
        ..color = const Color(0x14000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    _wheels(canvas, size, tire, hub);
    final shell = van ? _vanPath(size) : _sedanPath(size);
    canvas.drawPath(
      shell.shift(Offset(0, size.height * 0.008)),
      Paint()
        ..color = const Color(0x2E000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(shell, Paint()..color = body);
    canvas.drawPath(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = edge,
    );
    final mirrorY = size.height * (van ? 0.125 : 0.21);
    final mirrorW = size.width * 0.05;
    final mirrorH = size.height * 0.028;
    for (final side in const [-1.0, 1.0]) {
      final center = Offset(size.width * (0.5 + side * 0.455), mirrorY);
      final mirror = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: mirrorW, height: mirrorH),
        Radius.circular(mirrorH / 2),
      );
      canvas.drawRRect(mirror, Paint()..color = body);
      canvas.drawRRect(
        mirror,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = edge,
      );
    }

    final frame = _CabinFrame(van: van);
    final floor = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * frame.left,
        size.height * frame.top,
        size.width * frame.right,
        size.height * frame.bottom,
      ),
      Radius.circular(size.width * 0.06),
    );
    canvas.drawRRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [interiorTop, interiorBottom],
        ).createShader(floor.outerRect),
    );

    final glassRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        size.width * (frame.left + 0.02),
        size.height * (van ? 0.045 : 0.09),
        size.width * (frame.right - 0.02),
        size.height * (frame.top - 0.012),
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(glassRect, Paint()..color = glass);

    final dashRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          size.width / 2,
          size.height * (frame.top - (van ? 0.028 : 0.034)),
        ),
        width: size.width * (frame.right - frame.left) * 0.92,
        height: math.max(10, size.height * (van ? 0.028 : 0.036)),
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(dashRect, Paint()..color = dash);

    final wheelCenter = Offset(
      dashRect.left + dashRect.width * 0.16,
      dashRect.center.dy,
    );
    final wheelR = math.min(dashRect.height * 0.72, size.width * 0.034);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, wheelR * 0.28)
      ..color = dark ? const Color(0xFFE8E8EC) : const Color(0xFFF4F4F6);
    canvas.drawCircle(wheelCenter, wheelR, ring);
    canvas.drawCircle(wheelCenter, wheelR * 0.28, Paint()..color = ring.color);
    final spoke = Paint()
      ..strokeWidth = math.max(1.1, wheelR * 0.18)
      ..strokeCap = StrokeCap.round
      ..color = ring.color;
    canvas.drawLine(wheelCenter, wheelCenter + Offset(0, -wheelR + 1), spoke);
    canvas.drawLine(
      wheelCenter,
      wheelCenter + Offset(-wheelR * 0.7, wheelR * 0.55),
      spoke,
    );
    canvas.drawLine(
      wheelCenter,
      wheelCenter + Offset(wheelR * 0.7, wheelR * 0.55),
      spoke,
    );
  }

  void _wheels(Canvas canvas, Size size, Color tire, Color hub) {
    final ys = van ? const [0.16, 0.50, 0.80] : const [0.22, 0.76];
    final ww = size.width * 0.055;
    final wh = size.height * (van ? 0.055 : 0.07);
    for (final yf in ys) {
      for (final xf in [0.025, 0.92]) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * xf, size.height * yf, ww, wh),
          Radius.circular(ww * 0.4),
        );
        canvas.drawRRect(rect, Paint()..color = tire);
        canvas.drawRRect(rect.deflate(ww * 0.28), Paint()..color = hub);
      }
    }
  }

  Path _sedanPath(Size size) {
    final w = size.width;
    final h = size.height;
    final right = <Offset>[
      Offset(w * 0.50, h * 0.02),
      Offset(w * 0.64, h * 0.055),
      Offset(w * 0.72, h * 0.12),
      Offset(w * 0.84, h * 0.20),
      Offset(w * 0.90, h * 0.30),
      Offset(w * 0.905, h * 0.70),
      Offset(w * 0.86, h * 0.88),
      Offset(w * 0.70, h * 0.965),
      Offset(w * 0.50, h * 0.985),
    ];
    return _smoothMirror(right, w);
  }

  Path _vanPath(Size size) {
    final w = size.width;
    final h = size.height;
    final right = <Offset>[
      Offset(w * 0.50, h * 0.018),
      Offset(w * 0.66, h * 0.04),
      Offset(w * 0.78, h * 0.07),
      Offset(w * 0.88, h * 0.12),
      Offset(w * 0.91, h * 0.22),
      Offset(w * 0.915, h * 0.78),
      Offset(w * 0.88, h * 0.92),
      Offset(w * 0.70, h * 0.975),
      Offset(w * 0.50, h * 0.988),
    ];
    return _smoothMirror(right, w);
  }

  Path _smoothMirror(List<Offset> right, double width) {
    final path = Path()..moveTo(right.first.dx, right.first.dy);
    for (var i = 1; i < right.length - 1; i++) {
      final cur = right[i];
      final next = right[i + 1];
      final mid = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.lineTo(right.last.dx, right.last.dy);
    for (var i = right.length - 2; i >= 1; i--) {
      final cur = Offset(width - right[i].dx, right[i].dy);
      final next = Offset(width - right[i - 1].dx, right[i - 1].dy);
      final mid = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CarPainter oldDelegate) {
    return oldDelegate.van != van ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

String _silhouetteAsset(String body) {
  switch (body) {
    case 'bike':
      return 'assets/vehicles/okada_top.png';
    case 'coach':
      return 'assets/vehicles/bus_top.png';
    case 'bench':
      return 'assets/vehicles/keke_top.png';
    default:
      return 'assets/vehicles/danfo_top.png';
  }
}

class _SteeringWheel extends StatelessWidget {
  const _SteeringWheel({this.ink, this.size = 28});

  final Color? ink;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WheelPainter(ink: ink ?? palette.ink, hub: palette.surface),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.ink, required this.hub});

  final Color ink;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.6, size.width * 0.12)
      ..color = ink;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, size.width * 0.14, Paint()..color = ink);
    final spoke = Paint()
      ..strokeWidth = math.max(2.0, size.width * 0.08)
      ..strokeCap = StrokeCap.round
      ..color = ink;
    canvas.drawLine(center, Offset(center.dx, 3), spoke);
    canvas.drawLine(center, Offset(4, size.height - 5), spoke);
    canvas.drawLine(center, Offset(size.width - 4, size.height - 5), spoke);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = hub.withValues(alpha: 0),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.ink != ink;
}

class _SeatButton extends StatefulWidget {
  const _SeatButton({
    required this.seat,
    required this.onTap,
    required this.onLongPress,
    this.markHeight = 86,
    this.driverIcon = false,
  });

  final SeatMapSeat seat;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;
  final double markHeight;

  /// Cabin driver marker. Schematic rows draw their own wheel beside the seat.
  final bool driverIcon;

  @override
  State<_SeatButton> createState() => _SeatButtonState();
}

class _SeatButtonState extends State<_SeatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  var _armed = false;

  /// Short underdamped settle. Tests and reduced motion stay at rest.
  static const _select = SpringDescription(
    mass: 0.55,
    stiffness: 380,
    damping: 14,
  );

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed) return;
    _armed = true;
    if (widget.seat.status != 'yours') return;
    if (AlongMotionPolicy.inWidgetTest || AlongMotionPolicy.reduced(context)) {
      return;
    }
    _scale.value = 0.86;
    _scale.animateWith(SpringSimulation(_select, 0.86, 1, 0));
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final palette = AlongPalette.of(context);
    final ink = _ink(seat, palette);
    final price = seat.price;
    final showPrice = price != null && price.contains('₦');
    final showWheel = seat.isDriver && widget.driverIcon;
    return Semantics(
      button: widget.onTap != null,
      label: '${seat.label}, ${seat.statusWord}',
      child: ExcludeSemantics(
        child: SizedBox(
          key: Key('seat_${seat.id}'),
          width: double.infinity,
          height: widget.markHeight,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap == null ? null : () => widget.onTap!(seat.id),
              onLongPress: widget.onLongPress == null
                  ? null
                  : () => widget.onLongPress!(seat.id),
              child: AnimatedBuilder(
                animation: _scale,
                builder: (context, child) {
                  final scale = _scale.value.clamp(0.86, 1.08).toDouble();
                  return Transform.scale(scale: scale, child: child);
                },
                child: CustomPaint(
                  painter: _SeatPainter(seat: seat, palette: palette),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(3, 16, 3, 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showWheel)
                            _SteeringWheel(ink: palette.onInk, size: 26)
                          else if (seat.isCargo)
                            Icon(Icons.luggage_outlined, size: 16, color: ink)
                          else if (seat.status == 'yours')
                            Icon(Icons.check_rounded, size: 16, color: ink)
                          else if (seat.status == 'occupied')
                            Icon(Icons.person_rounded, size: 16, color: ink),
                          if (!showWheel && !seat.isDriver) ...[
                            const SizedBox(height: 2),
                            Text(
                              seat.label.trim(),
                              maxLines: 1,
                              softWrap: false,
                              style: AlongText.caption.copyWith(
                                color: ink,
                                fontSize: 13,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (showPrice && !showWheel) ...[
                            const SizedBox(height: 2),
                            Text(
                              price,
                              maxLines: 1,
                              softWrap: false,
                              style: AlongText.caption.copyWith(
                                color: ink,
                                fontSize: 11,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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

  static Color _fill(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver) return palette.ink;
    if (seat.isCargo) return palette.ink;
    switch (seat.status) {
      case 'occupied':
      case 'blocked':
        return palette.recessed;
      case 'held':
        return palette.surface;
      case 'yours':
        return palette.accent;
      default:
        return palette.success.withValues(
          alpha: palette.brightness == Brightness.dark ? 0.38 : 0.22,
        );
    }
  }

  static Color _ink(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver || seat.isCargo) return palette.onInk;
    if (seat.status == 'yours') return palette.accentInk;
    if (seat.status == 'occupied' || seat.status == 'blocked') {
      return palette.muted;
    }
    return palette.ink;
  }
}

class _SeatPainter extends CustomPainter {
  _SeatPainter({required this.seat, required this.palette});

  final SeatMapSeat seat;
  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cushion = _SeatButtonState._fill(seat, palette);
    final selected = seat.status == 'yours';
    final held = seat.status == 'held';
    final ink = palette.ink;
    final paintW = math.min(size.width - 4, math.max(28.0, size.height * 0.92));
    final left = (size.width - paintW) / 2;
    final headH = math.min(14.0, size.height * 0.16);
    final headW = paintW * 0.52;
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + (paintW - headW) / 2, 1, headW, headH),
      Radius.circular(headH / 2),
    );
    final pad = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, headH + 3, paintW, size.height - headH - 6),
      Radius.circular(math.min(16, paintW * 0.22)),
    );
    canvas.drawRRect(
      pad.shift(const Offset(0, 2)),
      Paint()..color = ink.withValues(alpha: 0.12),
    );
    canvas.drawRRect(pad, Paint()..color = cushion);
    canvas.save();
    canvas.clipRRect(pad);
    canvas.drawRect(
      pad.outerRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: selected ? 0.28 : 0.22),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.08),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(pad.outerRect),
    );
    canvas.restore();
    canvas.drawRRect(
      head,
      Paint()..color = Color.lerp(cushion, ink, selected ? 0.35 : 0.28)!,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = held ? 1.6 : 1.15
      ..color = ink.withValues(alpha: selected ? 0.55 : (held ? 0.5 : 0.22));
    canvas.drawRRect(pad, stroke);
    canvas.drawRRect(head, stroke);
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.seat.role != seat.role ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
