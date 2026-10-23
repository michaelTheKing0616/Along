import 'dart:math' as math;

import 'package:along_design/src/elevation.dart';
import 'package:along_design/src/flows/driver_portrait.dart';
import 'package:along_design/src/icons.dart';
import 'package:along_design/src/motion.dart';
import 'package:along_design/src/palette.dart';
import 'package:along_design/src/tokens.g.dart';
import 'package:along_design/src/type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Privacy-safe rider mark. Initials only, never a name or a photo.
class AlongRider {
  const AlongRider(this.initials);

  final String initials;

  static const riding = <AlongRider>[
    AlongRider('CN'),
    AlongRider('AM'),
    AlongRider('TU'),
  ];
}

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
    this.footer,
    this.riders = const [],
  });

  final String body;
  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  /// Ride facts under the legend. The cabin never stretches to fill them.
  final Widget? footer;

  /// Initials of people already in the cabin. Empty hides the row.
  final List<AlongRider> riders;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final rules = <Widget>[
      for (final row in rows)
        if (row.ruleTitle != null && row.ruleTitle!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RuleChip(
                key: Key('seat_row_rule_${row.id}'),
                label: row.ruleTitle!.trim(),
              ),
            ),
          ),
    ];
    // The cabin is a hairline outline. Seat count comes from the rows.
    // Keke, bike, and coach stay on their silhouettes.
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
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rules,
            diagram,
            if (body == 'cabin') ...[
              const SizedBox(height: 14),
              const _SeatLegend(),
            ],
            if (riders.isNotEmpty) ...[
              const SizedBox(height: 12),
              AlongWhosRiding(riders: riders),
            ],
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
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

/// Hairline cabin. Height wraps the rows at a fixed 20px gap.
/// Every cushion is the same square, sized from the width.
class _CabinShell extends StatelessWidget {
  const _CabinShell({
    required this.rows,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return ClipPath(
      clipper: _CabinClipper(),
      child: CustomPaint(
        painter: _CabinOutlinePainter(palette: palette),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 26, 8, 14),
          child: _SeatGrid(
            rows: rows,
            onSeatTap: onSeatTap,
            onSeatLongPress: onSeatLongPress,
          ),
        ),
      ),
    );
  }
}

/// Square cushion from the row width. A padded 360 cabin lands near 68.
/// The cap is 84 so a full-width cabin can grow. The row gap never grows.
class _CabinFit {
  const _CabinFit(this.seat);

  final double seat;

  static const maxSeat = 84.0;
  static const columnGap = 8.0;
  static const rowGap = 20.0;

  static _CabinFit solve({required double maxWidth, required int columns}) {
    final cols = math.max(1, columns);
    final width = maxWidth.isFinite ? math.max(0.0, maxWidth) : cols * maxSeat;
    if (cols == 1) return _CabinFit(math.min(maxSeat, width));
    final raw = (width - (cols - 1) * columnGap) / cols;
    return _CabinFit(math.min(maxSeat, math.max(0.0, raw)));
  }
}

class _SeatGrid extends StatelessWidget {
  const _SeatGrid({
    required this.rows,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    final cols = rows.fold<int>(
      1,
      (maxCols, row) => math.max(maxCols, row.seats.length),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = _CabinFit.solve(
          maxWidth: constraints.maxWidth,
          columns: cols,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: _CabinFit.rowGap),
              _SeatGridRow(
                row: rows[r],
                seat: fit.seat,
                width: constraints.maxWidth,
                onSeatTap: onSeatTap,
                onSeatLongPress: onSeatLongPress,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SeatGridRow extends StatelessWidget {
  const _SeatGridRow({
    required this.row,
    required this.seat,
    required this.width,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final SeatMapRowView row;
  final double seat;
  final double width;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    final seats = _driverFirst(row.seats);
    final badge = _badgeFor(row.ruleTitle);
    final bounded = width.isFinite;
    final marks = [
      for (final item in seats)
        SizedBox(
          width: seat,
          height: seat,
          child: _SeatButton(
            seat: item,
            markHeight: seat,
            driverIcon: true,
            badge: item.isDriver ? null : badge,
            onTap: item.isClaimable ? onSeatTap : null,
            onLongPress: item.isClaimable ? onSeatLongPress : null,
          ),
        ),
    ];
    if (!bounded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < marks.length; i++) ...[
            if (i > 0) const SizedBox(width: _CabinFit.columnGap),
            marks[i],
          ],
        ],
      );
    }
    return SizedBox(
      width: width,
      height: seat,
      child: Row(
        mainAxisAlignment: seats.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: marks,
      ),
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

  static IconData? _badgeFor(String? rule) {
    final text = rule?.trim().toLowerCase() ?? '';
    if (text.isEmpty) return null;
    if (text.contains('women')) return AlongIcons.female;
    return AlongIcons.tag;
  }
}

/// Rounded cabin, slightly narrower at the nose. No wheels, no mirrors.
class _CabinOutlinePainter extends CustomPainter {
  _CabinOutlinePainter({required this.palette});

  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF16171A) : const Color(0xFFF6F7F9);
    final line = dark ? const Color(0xFF4A4C54) : const Color(0xFFD0D2D8);
    final path = _cabinOutline(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = line,
    );
    _doorSeams(canvas, size, line);
    final dashW = math.min(72.0, size.width * 0.28);
    final dash = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, 11),
        width: dashW,
        height: 3,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(dash, Paint()..color = line);
  }

  void _doorSeams(Canvas canvas, Size size, Color line) {
    final seam = Paint()
      ..color = line
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final pillar = Paint()..color = line;
    for (final left in [true, false]) {
      final x = left ? 4.0 : size.width - 4;
      canvas.drawLine(
        Offset(x, size.height * 0.22),
        Offset(x, size.height * 0.44),
        seam,
      );
      canvas.drawLine(
        Offset(x, size.height * 0.56),
        Offset(x, size.height * 0.90),
        seam,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, size.height * 0.50),
            width: 4,
            height: math.max(10, size.height * 0.08),
          ),
          const Radius.circular(2),
        ),
        pillar,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CabinOutlinePainter oldDelegate) {
    return oldDelegate.palette.brightness != palette.brightness;
  }
}

Path _cabinOutline(Size size) {
  final w = size.width;
  final h = size.height;
  final taper = math.min(14.0, w * 0.045);
  final r = math.min(22.0, w * 0.08);
  final path = Path();
  path.moveTo(taper + r, 0.5);
  path.lineTo(w - taper - r, 0.5);
  path.arcToPoint(Offset(w - taper, r), radius: Radius.circular(r));
  path.lineTo(w - 0.5, h - r);
  path.arcToPoint(Offset(w - r - 0.5, h - 0.5), radius: Radius.circular(r));
  path.lineTo(r, h - 0.5);
  path.arcToPoint(Offset(0.5, h - r), radius: Radius.circular(r));
  path.lineTo(taper, r);
  path.arcToPoint(Offset(taper + r, 0.5), radius: Radius.circular(r));
  path.close();
  return path;
}

class _CabinClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _cabinOutline(size);

  @override
  bool shouldReclip(covariant _CabinClipper oldClipper) => false;
}

class _RuleChip extends StatelessWidget {
  const _RuleChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.recessed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongText.caption.copyWith(
            color: palette.ink,
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendMark(
          label: 'Available',
          fill: _SeatButtonState.available(palette),
          border: _SeatButtonState.hairline(palette),
        ),
        const SizedBox(width: 14),
        _LegendMark(
          label: 'Selected',
          fill: palette.accent,
          border: palette.accent,
        ),
        const SizedBox(width: 14),
        _LegendMark(
          label: 'Taken',
          fill: _SeatButtonState.taken(palette),
          border: _SeatButtonState.hairline(palette),
        ),
      ],
    );
  }
}

class _LegendMark extends StatelessWidget {
  const _LegendMark({
    required this.label,
    required this.fill,
    required this.border,
  });

  final String label;
  final Color fill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongText.caption.copyWith(
            color: palette.ink,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Pickup, departure, and seats left. Sits under the legend.
class AlongSeatContext extends StatelessWidget {
  const AlongSeatContext({
    super.key,
    required this.origin,
    required this.destination,
    required this.departs,
    required this.seatsLeft,
    this.ruled = true,
  });

  final String origin;
  final String destination;
  final String departs;
  final String seatsLeft;

  /// Top rule when the strip sits inside the cabin card.
  final bool ruled;

  /// The gallery sedan: Wuse to Garki, leaving soon, three of six left.
  static const sample = AlongSeatContext(
    origin: 'Wuse Market',
    destination: 'Garki',
    departs: 'Departs in 12 min',
    seatsLeft: '3/6 seats left',
  );

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final route = AlongType.meta(palette)
        .copyWith(color: palette.ink, fontWeight: FontWeight.w600, height: 1.1);
    final fact = AlongType.caption(
      palette,
    ).copyWith(color: palette.muted, fontWeight: FontWeight.w600, height: 1.1);
    return DecoratedBox(
      key: const Key('seat_ride_context'),
      decoration: BoxDecoration(
        border: ruled ? Border(top: BorderSide(color: palette.line)) : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: ruled ? 12 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    origin,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: route,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(AlongIcons.arrowRight, size: 14, color: palette.ink),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    destination,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: route,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(departs, maxLines: 1, softWrap: false, style: fact),
                const Spacer(),
                Text(seatsLeft, maxLines: 1, softWrap: false, style: fact),
              ],
            ),
          ],
        ),
      ),
    );
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
    this.badge,
  });

  final SeatMapSeat seat;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;
  final double markHeight;

  /// Cabin driver marker. Schematic rows draw their own wheel beside the seat.
  final bool driverIcon;

  /// Driver-authored tag, drawn as a corner mark. Never a seat color.
  final IconData? badge;

  @override
  State<_SeatButton> createState() => _SeatButtonState();
}

class _SeatButtonState extends State<_SeatButton>
    with TickerProviderStateMixin {
  late final AnimationController _scale;
  late final AnimationController _reveal;
  var _armed = false;

  /// 0.9, through about 1.05, then rest at 1. The view clamps the peak.
  static const _select = SpringDescription(
    mass: 0.5,
    stiffness: 420,
    damping: 12,
  );

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  bool get _play => AlongMotionPolicy.play(context);

  void _armSelection() {
    if (!_play) {
      _scale.value = 1;
      _reveal.value = 1;
      return;
    }
    _scale.value = 0.9;
    _scale.animateWith(SpringSimulation(_select, 0.9, 1, 0));
    _reveal.forward(from: 0);
    AlongHaptics.tick(context);
  }

  void _armTaken() {
    if (!_play) {
      _reveal.value = 1;
      _scale.value = 1;
      return;
    }
    _reveal.forward(from: 0);
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 0.4, stiffness: 520, damping: 11),
        1,
        1,
        8,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed) return;
    _armed = true;
    if (widget.seat.status == 'yours') _armSelection();
  }

  @override
  void didUpdateWidget(covariant _SeatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seat.status == widget.seat.status) return;
    if (widget.seat.status == 'yours') {
      _armSelection();
    } else if (widget.seat.status == 'occupied') {
      _armTaken();
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final palette = AlongPalette.of(context);
    final ink = _ink(seat, palette);
    final price = seat.price;
    final showPrice =
        price != null && price.contains('₦') && seat.status != 'occupied';
    final showWheel = seat.isDriver && widget.driverIcon;
    final badge =
        widget.badge ??
        (seat.status == 'held' && !widget.driverIcon
            ? AlongIcons.schedule
            : null);
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
              onTap: widget.onTap == null
                  ? null
                  : () {
                      AlongHaptics.selection(context);
                      widget.onTap!(seat.id);
                    },
              onLongPress: widget.onLongPress == null
                  ? null
                  : () => widget.onLongPress!(seat.id),
              child: AnimatedBuilder(
                animation: Listenable.merge([_scale, _reveal]),
                builder: (context, child) {
                  final scale = _scale.value.clamp(0.9, 1.05).toDouble();
                  return Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      painter: widget.driverIcon
                          ? _CarSeatPainter(
                              seat: seat,
                              palette: palette,
                              held: seat.status == 'held' ? 0.66 : 0,
                            )
                          : _SeatPainter(seat: seat, palette: palette),
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        4,
                        widget.driverIcon ? widget.markHeight * 0.40 : 12,
                        4,
                        4,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showWheel)
                                _SteeringWheel(ink: palette.ink, size: 16)
                              else if (seat.isCargo)
                                Icon(AlongIcons.luggage, size: 14, color: ink)
                              else if (!widget.driverIcon &&
                                  seat.status == 'yours')
                                AlongStrokeCheck(color: ink)
                              else if (seat.status == 'occupied' &&
                                  !widget.driverIcon)
                                Icon(AlongIcons.user, size: 14, color: ink),
                              if (!showWheel && !seat.isDriver) ...[
                                const SizedBox(height: 2),
                                Text(
                                  seat.label.trim(),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AlongText.caption.copyWith(
                                    color: ink,
                                    fontSize: 12,
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
                                    fontSize: 10,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
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
                    if (widget.driverIcon &&
                        !seat.isDriver &&
                        (seat.status == 'yours' || seat.status == 'occupied'))
                      Positioned(
                        top: 2,
                        right: 2,
                        child: _CornerBadge(
                          fill: seat.status == 'yours'
                              ? palette.accentInk
                              : palette.ink.withValues(alpha: 0.10),
                          child: seat.status == 'yours'
                              ? AlongStrokeCheck(color: palette.accent, size: 9)
                              : Icon(AlongIcons.user, size: 11, color: ink),
                        ),
                      )
                    else if (badge != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Icon(badge, size: 11, color: ink),
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

  static bool _dark(AlongPalette palette) =>
      palette.brightness == Brightness.dark;

  static Color available(AlongPalette palette) =>
      _dark(palette) ? const Color(0xFF2A2B30) : const Color(0xFFFFFFFF);

  static Color taken(AlongPalette palette) =>
      _dark(palette) ? const Color(0xFF32343A) : const Color(0xFFE8E9ED);

  static Color driver(AlongPalette palette) =>
      _dark(palette) ? const Color(0xFF3A3C44) : const Color(0xFFE2E3E8);

  static Color hairline(AlongPalette palette) =>
      _dark(palette) ? const Color(0xFF5A5C66) : const Color(0xFFD0D2D8);

  static Color _fill(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver) return driver(palette);
    if (seat.status == 'yours') return palette.accent;
    if (seat.status == 'occupied' || seat.status == 'blocked') {
      return taken(palette);
    }
    return available(palette);
  }

  static Color _ink(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver) return palette.ink;
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
    final radius = math.min(16.0, size.shortestSide * 0.25);
    final pad = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    canvas.drawRRect(pad, Paint()..color = cushion);
    canvas.drawRRect(
      pad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = selected
            ? palette.accentInk.withValues(alpha: 0.18)
            : _SeatButtonState.hairline(palette),
    );
    final barW = size.width * 0.42;
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH((size.width - barW) / 2, 7, barW, 3.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      bar,
      Paint()
        ..color = selected
            ? palette.accentInk.withValues(alpha: 0.28)
            : palette.ink.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.seat.role != seat.role ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.fill, required this.child});

  final Color fill;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: child,
    );
  }
}

/// Small top-down seat. The cabin painter, without a hit target.
class AlongSeatGlyph extends StatelessWidget {
  const AlongSeatGlyph({super.key, required this.status, this.width = 36});

  /// `yours`, `occupied`, `free`, `held`, or `driver`.
  final String status;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final driver = status == 'driver';
    final seat = SeatMapSeat(
      id: status,
      label: '',
      role: driver ? 'driver' : 'passenger',
      status: driver ? 'occupied' : status,
      statusWord: status,
    );
    return SizedBox(
      width: width,
      height: width * 1.1,
      child: CustomPaint(
        painter: _CarSeatPainter(
          seat: seat,
          palette: palette,
          held: status == 'held' ? 0.66 : 0,
        ),
      ),
    );
  }
}

/// Flat top-down seat. Width to height is about 1:1.1.
class _CarSeatPainter extends CustomPainter {
  _CarSeatPainter({
    required this.seat,
    required this.palette,
    required this.held,
  });

  final SeatMapSeat seat;
  final AlongPalette palette;
  final double held;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = _SeatButtonState._fill(seat, palette);
    final ink = _SeatButtonState._ink(seat, palette);
    final selected = seat.status == 'yours';
    final hairline = selected
        ? palette.accentInk.withValues(alpha: 0.22)
        : _SeatButtonState.hairline(palette);
    final backColor = Color.alphaBlend(ink.withValues(alpha: 0.10), fill);
    final seatW = math.min(size.width - 2, (size.height - 2) / 1.1);
    final seatH = seatW * 1.1;
    final left = (size.width - seatW) / 2;
    final top = (size.height - seatH) / 2;
    final headH = seatH * 0.12;
    final headW = seatW * 0.46;
    final backH = seatH * 0.16;
    final backW = seatW * 0.74;
    final cushion = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top + seatH * 0.24, seatW, seatH * 0.76),
      Radius.circular(seatW * 0.22),
    );
    canvas.drawRRect(cushion, Paint()..color = fill);
    canvas.save();
    canvas.clipRRect(cushion);
    canvas.drawRect(
      Rect.fromLTWH(cushion.left, cushion.top, cushion.width, seatH * 0.10),
      Paint()..color = ink.withValues(alpha: 0.07),
    );
    final bolster = Paint()..color = ink.withValues(alpha: 0.08);
    final bolsterW = seatW * 0.13;
    final bolsterH = cushion.height * 0.62;
    final bolsterTop = cushion.top + cushion.height * 0.22;
    final bolsterRadius = Radius.circular(bolsterW / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cushion.left + 2, bolsterTop, bolsterW, bolsterH),
        bolsterRadius,
      ),
      bolster,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cushion.right - bolsterW - 2,
          bolsterTop,
          bolsterW,
          bolsterH,
        ),
        bolsterRadius,
      ),
      bolster,
    );
    canvas.restore();
    canvas.drawRRect(
      cushion,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = hairline,
    );
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + (seatW - backW) / 2,
        cushion.top - backH * 0.62,
        backW,
        backH,
      ),
      Radius.circular(backH / 2),
    );
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + (seatW - headW) / 2,
        back.top - headH - seatH * 0.025,
        headW,
        headH,
      ),
      Radius.circular(headH / 2),
    );
    canvas.drawRRect(back, Paint()..color = backColor);
    canvas.drawRRect(
      back,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = hairline,
    );
    canvas.drawRRect(head, Paint()..color = backColor);
    canvas.drawRRect(
      head,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = hairline,
    );
    if (held > 0) {
      final ringRect = cushion.outerRect.deflate(3.2);
      final ring = RRect.fromRectAndRadius(
        ringRect,
        Radius.circular(math.max(4, seatW * 0.22 - 3.2)),
      );
      final path = Path()..addRRect(ring);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * held.clamp(0.0, 1.0)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = palette.accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CarSeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.held != held ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}

/// Check that draws itself on. At rest the stroke is complete.
class AlongStrokeCheck extends StatefulWidget {
  const AlongStrokeCheck({super.key, required this.color, this.size = 14});

  final Color color;
  final double size;

  @override
  State<AlongStrokeCheck> createState() => AlongStrokeCheckState();
}

class AlongStrokeCheckState extends State<AlongStrokeCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AlongMotionPolicy.play(context)) return;
      _draw.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _draw,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _CheckPainter(progress: _draw.value, color: widget.color),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, size.width * 0.14)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class AlongWhosRiding extends StatelessWidget {
  const AlongWhosRiding({super.key, required this.riders});

  final List<AlongRider> riders;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final shown = riders.take(4).toList();
    return Row(
      children: [
        Text(
          "Who's riding",
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: palette.ink,
          ),
        ),
        const Spacer(),
        for (final rider in shown) ...[
          Semantics(
            label: 'Rider ${rider.initials}',
            container: true,
            child: ExcludeSemantics(
              child: AlongMonogram(initials: rider.initials, size: 28),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}
