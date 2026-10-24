import 'dart:math' as math;

import 'package:along_design/src/craft.dart';
import 'package:along_design/src/flows/driver_portrait.dart';
import 'package:along_design/src/icons.dart';
import 'package:along_design/src/motion.dart';
import 'package:along_design/src/palette.dart';
import 'package:along_design/src/tokens.g.dart';
import 'package:along_design/src/type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Cushion depress while a finger is down, keyed by seat id. Rest is 0.
abstract final class AlongSeatPress {
  static final depress = <String, double>{};
}

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
    return Padding(
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
    return CustomPaint(
      painter: _CabinOutlinePainter(palette: palette, bold: true),
      child: ClipPath(
        clipper: _CabinClipper(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _CabinFit.nose),
              _SeatGrid(
                rows: rows,
                onSeatTap: onSeatTap,
                onSeatLongPress: onSeatLongPress,
              ),
              const SizedBox(height: _CabinFit.tail),
            ],
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

  /// Space under the price line, before the next cushion.
  static const rowGap = 8.0;

  /// Label and price sit under the cushion, not inside it.
  static const captionGap = 4.0;
  static const captionSlot = 36.0;

  /// Empty nose and tail so the cushions sit in the door section,
  /// past the taper in [_cabinOutline].
  static const nose = 48.0;
  static const tail = 28.0;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: seat,
                height: seat,
                child: _SeatButton(
                  seat: item,
                  markHeight: seat,
                  driverIcon: true,
                  captionBelow: true,
                  badge: item.isDriver ? null : badge,
                  onTap: item.isClaimable ? onSeatTap : null,
                  onLongPress: item.isClaimable ? onSeatLongPress : null,
                ),
              ),
              const SizedBox(height: _CabinFit.captionGap),
              _SeatCaption(seat: item, width: seat),
            ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _SeatCaption extends StatelessWidget {
  const _SeatCaption({required this.seat, required this.width});

  final SeatMapSeat seat;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final style = AlongType.caption(palette)
        .copyWith(fontWeight: FontWeight.w600, height: 1.2);
    final price = seat.price;
    final showPrice =
        price != null && price.contains('₦') && seat.status != 'occupied';
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(
            seat.label.trim(),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
          if (showPrice)
            Text(
              price,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// One stroke weight for the cabin, the door seams, and every seat.
const _vectorStroke = 1.5;

/// Car body from above: tapered nose, straight doors, tapered rear.
class _CabinOutlinePainter extends CustomPainter {
  _CabinOutlinePainter({required this.palette, this.bold = false});

  final AlongPalette palette;
  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = palette.brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF2A2824) : const Color(0xFFF4F1EB);
    final line = dark ? const Color(0xFFE4DCD2) : const Color(0xFF141210);
    final path = _cabinOutline(size);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _vectorStroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = line;
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, stroke);
    _doorSeams(canvas, size, stroke);
    final nose = math.min(28.0, size.height * 0.16);
    final glass = Path()
      ..moveTo(size.width * 0.34, nose * 0.62)
      ..quadraticBezierTo(
        size.width * 0.50,
        nose * 0.28,
        size.width * 0.66,
        nose * 0.62,
      );
    canvas.drawPath(glass, stroke);
    final tail = math.min(18.0, size.height * 0.12);
    final deck = Path()
      ..moveTo(size.width * 0.32, size.height - tail * 0.55)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height - tail * 0.85,
        size.width * 0.68,
        size.height - tail * 0.55,
      );
    canvas.drawPath(deck, stroke);
  }

  void _doorSeams(Canvas canvas, Size size, Paint seam) {
    final top = _CabinFit.nose + 6;
    final bottom = size.height - _CabinFit.tail - 6;
    if (bottom - top < 16) return;
    for (final left in [true, false]) {
      final x = left ? 8.0 : size.width - 8;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + (bottom - top) * 0.42),
        seam,
      );
      canvas.drawLine(
        Offset(x, top + (bottom - top) * 0.58),
        Offset(x, bottom),
        seam,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CabinOutlinePainter oldDelegate) {
    return oldDelegate.palette.brightness != palette.brightness ||
        oldDelegate.bold != bold;
  }
}

Path _cabinOutline(Size size) {
  final w = size.width;
  final h = size.height;
  final nose = math.min(28.0, h * 0.16);
  final tail = math.min(18.0, h * 0.12);
  final side = math.max(1.5, w * 0.008);
  // Door wall still starts at nose + 14. The 24 fillet lives in the nose
  // and the tail, above and below that line.
  final shoulder = nose + 14;
  final tailJoin = h - tail - 8;
  final fillet = math.min(AlongRadius.card.x, shoulder - 4);
  final path = Path();
  path.moveTo(w * 0.50, 1.2);
  path.cubicTo(
    w * 0.64,
    1.2,
    w * 0.76,
    nose * 0.20,
    w * 0.86,
    math.max(4.0, shoulder - fillet),
  );
  path.cubicTo(
    w - side - fillet * 0.12,
    shoulder - fillet * 0.45,
    w - side,
    shoulder - fillet * 0.28,
    w - side,
    shoulder,
  );
  path.lineTo(w - side, tailJoin);
  path.cubicTo(
    w - side,
    tailJoin + fillet * 0.42,
    w * 0.88,
    h - 6,
    w * 0.72,
    h - 3.5,
  );
  path.quadraticBezierTo(w * 0.61, h - 1.2, w * 0.50, h - 1.2);
  path.quadraticBezierTo(w * 0.39, h - 1.2, w * 0.28, h - 3.5);
  path.cubicTo(w * 0.12, h - 6, side, tailJoin + fillet * 0.42, side, tailJoin);
  path.lineTo(side, shoulder);
  path.cubicTo(
    side,
    shoulder - fillet * 0.28,
    side + fillet * 0.12,
    shoulder - fillet * 0.45,
    w * 0.14,
    math.max(4.0, shoulder - fillet),
  );
  path.cubicTo(w * 0.24, nose * 0.20, w * 0.36, 1.2, w * 0.50, 1.2);
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
    return Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: AlongType.label(palette),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        _LegendMark(
          label: 'Available',
          fill: _SeatButtonState.available(palette),
          border: _SeatButtonState.hairline(palette),
        ),
        _LegendMark(
          label: 'Selected',
          fill: palette.accent,
          border: palette.accent,
        ),
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
          clipBehavior: Clip.antiAlias,
          decoration: AlongCraft.fill(
            fill,
            corner: AlongRadius.xs.x,
            side: BorderSide(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AlongText.caption.copyWith(
            color: palette.ink,
            fontSize: 13,
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
    final fact = AlongType.caption(palette).copyWith(
      color: palette.ink.withValues(alpha: 0.72),
      fontWeight: FontWeight.w600,
    );
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    final facts = roomy
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(departs, maxLines: 2, softWrap: true, style: fact),
              Text(seatsLeft, maxLines: 2, softWrap: true, style: fact),
            ],
          )
        : Row(
            children: [
              Text(departs, maxLines: 1, softWrap: false, style: fact),
              const Spacer(),
              Text(seatsLeft, maxLines: 1, softWrap: false, style: fact),
            ],
          );
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
            facts,
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
    this.captionBelow = false,
    this.badge,
  });

  final SeatMapSeat seat;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;
  final double markHeight;

  /// Cabin driver marker. Schematic rows draw their own wheel beside the seat.
  final bool driverIcon;

  /// Cabin prices sit under the cushion. The square stays the hit target.
  final bool captionBelow;

  /// Driver-authored tag, drawn as a corner mark. Never a seat color.
  final IconData? badge;

  @override
  State<_SeatButton> createState() => _SeatButtonState();
}

class _SeatButtonState extends State<_SeatButton>
    with TickerProviderStateMixin {
  late final AnimationController _scale;
  late final AnimationController _reveal;
  late final AnimationController _depress;
  var _armed = false;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
    _reveal = AnimationController(
      vsync: this,
      duration: AlongDurations.draw,
      value: 1,
    );
    _depress = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(() {
        AlongSeatPress.depress[widget.seat.id] = _depress.value;
      });
  }

  void _pressIn() {
    if (widget.onTap == null) return;
    if (!_play) {
      _depress.value = 0;
      return;
    }
    _scale.animateWith(SpringSimulation(AlongSprings.select, 0.92, 1, 0));
    _depress.animateWith(
      SpringSimulation(AlongSprings.press, _depress.value, 1, 0),
    );
  }

  void _pressOut() {
    if (!_play) {
      _depress.value = 0;
      AlongSeatPress.depress[widget.seat.id] = 0;
      return;
    }
    _depress.animateWith(
      SpringSimulation(AlongSprings.press, _depress.value, 0, 0),
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
    _scale.animateWith(SpringSimulation(AlongSprings.select, 0.9, 1, 0));
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
    _scale.animateWith(SpringSimulation(AlongSprings.taken, 1, 1, 8));
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
    _depress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final palette = AlongPalette.of(context);
    final ink = widget.driverIcon
        ? _contrastInk(seat, palette)
        : _ink(seat, palette);
    final price = seat.price;
    final showPrice =
        !widget.captionBelow &&
        price != null &&
        price.contains('₦') &&
        seat.status != 'occupied';
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
              onTapDown: widget.onTap == null ? null : (_) => _pressIn(),
              onTapUp: widget.onTap == null ? null : (_) => _pressOut(),
              onTapCancel: widget.onTap == null ? null : _pressOut,
              onTap: widget.onTap == null
                  ? null
                  : () {
                      AlongHaptics.confirm(context);
                      widget.onTap!(seat.id);
                    },
              onLongPress: widget.onLongPress == null
                  ? null
                  : () => widget.onLongPress!(seat.id),
              child: AnimatedBuilder(
                animation: Listenable.merge([_scale, _reveal, _depress]),
                builder: (context, child) {
                  final scale = _scale.value.clamp(0.9, 1.05).toDouble();
                  final depress = _play ? _depress.value : 0.0;
                  AlongSeatPress.depress[seat.id] = depress;
                  return Transform.scale(
                    scale: scale,
                    child: CustomPaint(
                      painter: widget.driverIcon
                          ? _CarSeatPainter(
                              seat: seat,
                              palette: palette,
                              held: seat.status == 'held' ? 0.66 : 0,
                              contrast: true,
                              drawWheel: false,
                              depress: depress,
                            )
                          : _SeatPainter(
                              seat: seat,
                              palette: palette,
                              depress: depress,
                            ),
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
                                _SteeringWheel(ink: ink, size: 16)
                              else if (seat.isCargo)
                                Icon(AlongIcons.luggage, size: 14, color: ink)
                              else if (!widget.driverIcon &&
                                  seat.status == 'yours')
                                AlongStrokeCheck(color: ink)
                              else if (seat.status == 'occupied' &&
                                  !widget.driverIcon)
                                Icon(AlongIcons.user, size: 14, color: ink),
                              if (!widget.captionBelow &&
                                  !showWheel &&
                                  !seat.isDriver) ...[
                                const SizedBox(height: 2),
                                Text(
                                  seat.label.trim(),
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AlongText.caption.copyWith(
                                    color: ink,
                                    fontSize: 13,
                                    height: 1,
                                    fontWeight: FontWeight.w600,
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
                                    fontSize: 13,
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

  static Color available(AlongPalette palette) => const Color(0xFFFFFFFF);

  /// Brand ink at 85%, in both themes, so a taken seat stays a filled mark.
  static Color taken(AlongPalette palette) =>
      const Color(0xFF141210).withValues(alpha: 0.85);

  static Color driver(AlongPalette palette) => taken(palette);

  static Color hairline(AlongPalette palette) => const Color(0xFF141210);

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

  /// Label ink for the high-contrast cabin. Taken cushions are near-black.
  static Color _contrastInk(SeatMapSeat seat, AlongPalette palette) {
    final taken =
        seat.isDriver || seat.status == 'occupied' || seat.status == 'blocked';
    if (seat.status == 'yours') return palette.accentInk;
    if (taken) return const Color(0xFFF4F1EA);
    return palette.ink;
  }
}

class _SeatPainter extends CustomPainter {
  _SeatPainter({required this.seat, required this.palette, this.depress = 0});

  final SeatMapSeat seat;
  final AlongPalette palette;
  final double depress;

  @override
  void paint(Canvas canvas, Size size) {
    final cushion = _SeatButtonState._fill(seat, palette);
    final selected = seat.status == 'yours';
    final radius = math.min(AlongRadius.card.x, size.shortestSide * 0.38);
    final pad = AlongCraft.path(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      radius,
    );
    final squash = depress.clamp(0.0, 1.0);
    if (squash > 0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height);
      canvas.scale(1, 1 - 0.18 * squash);
      canvas.translate(-size.width / 2, -size.height);
    }
    canvas.drawPath(pad, Paint()..color = cushion);
    canvas.drawPath(
      pad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = selected
            ? palette.accentInk.withValues(alpha: 0.18)
            : _SeatButtonState.hairline(palette),
    );
    final barW = size.width * 0.42;
    final bar = AlongCraft.path(
      Rect.fromLTWH((size.width - barW) / 2, 7, barW, 3.5),
      1,
    );
    canvas.drawPath(
      bar,
      Paint()
        ..color = selected
            ? palette.accentInk.withValues(alpha: 0.28)
            : palette.ink.withValues(alpha: 0.18),
    );
    if (squash > 0) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.seat.role != seat.role ||
        oldDelegate.depress != depress ||
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
      clipBehavior: Clip.antiAlias,
      decoration: AlongCraft.fill(fill, corner: AlongRadius.xs.x),
      child: child,
    );
  }
}

/// The cabin outline with the same seat painter, at a fixed cushion size.
/// Offer uses this so the diagram is a car, not loose glyphs.
class AlongCabinDiagram extends StatelessWidget {
  const AlongCabinDiagram({
    super.key,
    required this.rows,
    this.seat = 72,
    this.contrast = false,
  });

  /// Each inner list is a row of status tokens (`driver`, `yours`, `free`,
  /// `occupied`, `held`).
  final List<List<String>> rows;
  final double seat;

  /// Dark taken seats, yellow selected seats, and a heavier cabin stroke.
  final bool contrast;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final columns = rows.fold<int>(
      1,
      (maxCols, row) => math.max(maxCols, row.length),
    );
    final span = columns * seat + (columns - 1) * 8;
    return CustomPaint(
      painter: _CabinOutlinePainter(palette: palette, bold: contrast),
      child: ClipPath(
        clipper: _CabinClipper(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _CabinFit.nose),
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: 8),
                _OfferSeatRow(
                  statuses: rows[r],
                  seat: seat,
                  span: span,
                  contrast: contrast,
                ),
              ],
              const SizedBox(height: _CabinFit.tail),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferSeatRow extends StatelessWidget {
  const _OfferSeatRow({
    required this.statuses,
    required this.seat,
    required this.span,
    required this.contrast,
  });

  final List<String> statuses;
  final double seat;
  final double span;
  final bool contrast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: span,
      child: Row(
        mainAxisAlignment: statuses.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          for (final status in statuses)
            AlongSeatGlyph(status: status, width: seat, contrast: contrast),
        ],
      ),
    );
  }
}

/// Small top-down seat. The cabin painter, without a hit target.
class AlongSeatGlyph extends StatelessWidget {
  const AlongSeatGlyph({
    super.key,
    required this.status,
    this.width = 36,
    this.contrast = false,
  });

  /// `yours`, `occupied`, `free`, `held`, or `driver`.
  final String status;
  final double width;

  /// Stronger cushion fills. Offer uses this so a free seat is not a pale blob.
  final bool contrast;

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
      height: width,
      child: CustomPaint(
        painter: _CarSeatPainter(
          seat: seat,
          palette: palette,
          held: status == 'held' ? 0.66 : 0,
          contrast: contrast,
        ),
      ),
    );
  }
}

/// Open-seat count with the same cushion painter. Rides, offer, and the
/// receipt use it so a seat is Along's mark, not a leftover word.
class AlongSeatCount extends StatelessWidget {
  const AlongSeatCount({super.key, required this.count, this.glyph = 12});

  final int count;
  final double glyph;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final shown = count.clamp(1, 3);
    return Semantics(
      label: '$count seats',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            AlongSeatGlyph(status: 'free', width: glyph),
          ],
          const SizedBox(width: 4),
          Text(
            '$count seats',
            maxLines: 1,
            softWrap: false,
            style: AlongType.caption(palette).copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w600,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
    this.contrast = false,
    this.drawWheel = true,
    this.depress = 0,
  });

  final SeatMapSeat seat;
  final AlongPalette palette;
  final double held;
  final bool contrast;
  final bool drawWheel;
  final double depress;

  @override
  void paint(Canvas canvas, Size size) {
    final selected = seat.status == 'yours';
    final taken =
        seat.isDriver || seat.status == 'occupied' || seat.status == 'blocked';
    final fill = selected
        ? palette.accent
        : taken
        ? _SeatButtonState.taken(palette)
        : _SeatButtonState.available(palette);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _vectorStroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF141210);
    final inset = _vectorStroke;
    final bounds = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final backH = bounds.height * 0.22;
    final backRect = Rect.fromLTWH(
      bounds.left + bounds.width * 0.10,
      bounds.top,
      bounds.width * 0.80,
      backH,
    );
    final back = AlongCraft.path(backRect, backH * 0.45);
    final pan = _seatPan(
      Rect.fromLTWH(
        bounds.left,
        bounds.top + backH + bounds.height * 0.06,
        bounds.width,
        bounds.height - backH - bounds.height * 0.06,
      ),
    );
    final squash = depress.clamp(0.0, 1.0);
    if (squash > 0) {
      final pivot = Offset(bounds.center.dx, bounds.bottom);
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.scale(1, 1 - 0.12 * squash);
      canvas.translate(-pivot.dx, -pivot.dy);
    }
    final fillPaint = Paint()..color = fill;
    canvas.drawPath(back, fillPaint);
    canvas.drawPath(back, stroke);
    canvas.drawPath(pan, fillPaint);
    canvas.drawPath(pan, stroke);
    if (drawWheel && seat.isDriver) {
      final hub = pan.getBounds().center;
      final wheel = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _vectorStroke
        ..color = const Color(0xFFF7F4EF);
      canvas.drawCircle(hub, bounds.width * 0.12, wheel);
      canvas.drawCircle(
        hub,
        bounds.width * 0.035,
        Paint()..color = wheel.color,
      );
    }
    if (squash > 0) canvas.restore();
    if (held > 0) {
      final metric = pan.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * held.clamp(0.0, 1.0)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _vectorStroke
          ..strokeCap = StrokeCap.round
          ..color = palette.accent,
      );
    }
  }

  /// Rounded pan. The sides step out for the armrests, then back in.
  Path _seatPan(Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final path = Path();
    path.moveTo(l + w * 0.28, t);
    path.lineTo(r - w * 0.28, t);
    path.quadraticBezierTo(r - w * 0.02, t, r, t + h * 0.24);
    path.lineTo(r, t + h * 0.32);
    path.quadraticBezierTo(
      r - w * 0.12,
      t + h * 0.42,
      r - w * 0.05,
      t + h * 0.54,
    );
    path.lineTo(r - w * 0.05, b - h * 0.34);
    path.quadraticBezierTo(r - w * 0.05, b, r - w * 0.32, b);
    path.lineTo(l + w * 0.32, b);
    path.quadraticBezierTo(l + w * 0.05, b, l + w * 0.05, b - h * 0.34);
    path.lineTo(l + w * 0.05, t + h * 0.54);
    path.quadraticBezierTo(l + w * 0.12, t + h * 0.42, l, t + h * 0.32);
    path.lineTo(l, t + h * 0.24);
    path.quadraticBezierTo(l + w * 0.02, t, l + w * 0.28, t);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CarSeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.held != held ||
        oldDelegate.contrast != contrast ||
        oldDelegate.drawWheel != drawWheel ||
        oldDelegate.depress != depress ||
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
      duration: AlongDurations.draw,
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
    final roomy = MediaQuery.textScalerOf(context).scale(1) > 1.05;
    final faces = [
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
    ];
    if (roomy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Who's riding",
            maxLines: 2,
            softWrap: true,
            style: AlongType.caption(palette).copyWith(
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: faces),
        ],
      );
    }
    return Row(
      children: [
        Text(
          "Who's riding",
          maxLines: 1,
          softWrap: false,
          style: AlongType.caption(palette).copyWith(
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: palette.ink,
          ),
        ),
        const Spacer(),
        ...faces,
      ],
    );
  }
}
