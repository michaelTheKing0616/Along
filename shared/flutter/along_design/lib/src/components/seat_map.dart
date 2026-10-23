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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fill a bounded height (the product screen, the gallery).
        // A scrolling list passes an unbounded height and stays shrink-wrapped.
        final fill = constraints.hasBoundedHeight && body == 'cabin';
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(body == 'bike' ? 36 : 24),
            boxShadow: AlongElevation.card(palette.ink),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...rules,
                if (fill) Expanded(child: diagram) else diagram,
                if (body == 'cabin') ...[
                  const SizedBox(height: 14),
                  const _SeatLegend(),
                ],
              ],
            ),
          ),
        );
      },
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

/// Hairline cabin. Every row shares the widest row's columns.
/// A 3-seat row over 4 columns gives each seat a 4/3 span, flush
/// to the same left and right edges.
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
      painter: _CabinOutlinePainter(palette: palette),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 22, 10, 12),
        child: _SeatGrid(
          rows: rows,
          onSeatTap: onSeatTap,
          onSeatLongPress: onSeatLongPress,
        ),
      ),
    );
  }
}

/// Width-fit and height-fit for one square cushion, capped at 76.
/// Four-across rows keep the cushion at about 56 by tightening the
/// gap, and still run edge to edge inside the cabin.
class _CabinFit {
  const _CabinFit({required this.seat, required this.gap});

  final double seat;
  final double gap;

  static const maxSeat = 76.0;
  static const minSeat = 56.0;
  static const preferredGap = 10.0;

  static _CabinFit solve({
    required double maxWidth,
    required double maxHeight,
    required int columns,
    required int rowCount,
  }) {
    final cols = math.max(1, columns);
    final rows = math.max(1, rowCount);
    final width = maxWidth.isFinite ? math.max(0.0, maxWidth) : cols * maxSeat;
    var seat = maxSeat;
    if (cols == 1) {
      seat = math.min(maxSeat, width);
    } else {
      final preferred = (width - (cols - 1) * preferredGap) / cols;
      if (preferred >= minSeat) {
        seat = math.min(maxSeat, preferred);
      } else if (width >= cols * minSeat) {
        seat = minSeat;
      } else {
        seat = width / cols;
      }
    }

    if (maxHeight.isFinite) {
      final gaps = math.max(0, rows - 1);
      final heightBudget = math.max(0.0, maxHeight - 0.5);
      var heightFit = gaps == 0
          ? heightBudget
          : (heightBudget - gaps * preferredGap) / rows;
      if (heightFit < 0) heightFit = heightBudget / rows;
      if (heightFit < seat) seat = math.max(0.0, heightFit);
      if (rows * seat > heightBudget) seat = heightBudget / rows;
    }

    var gap = 0.0;
    if (cols > 1) {
      gap = (width - cols * seat) / (cols - 1);
      if (gap < 0) {
        seat = width / cols;
        gap = 0;
      }
    }
    return _CabinFit(seat: seat, gap: gap);
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
        final tight = constraints.hasBoundedHeight;
        final fit = _CabinFit.solve(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          columns: cols,
          rowCount: rows.length,
        );
        return Column(
          mainAxisSize: tight ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: tight && rows.length > 1
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (!tight && r > 0)
                const SizedBox(height: _CabinFit.preferredGap),
              _SeatGridRow(
                row: rows[r],
                seat: fit.seat,
                gap: fit.gap,
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
    required this.gap,
    required this.width,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final SeatMapRowView row;
  final double seat;
  final double gap;
  final double width;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  @override
  Widget build(BuildContext context) {
    final seats = _driverFirst(row.seats);
    final badge = _badgeFor(row.ruleTitle);
    final bounded = width.isFinite;
    final span = bounded ? width : null;
    return SizedBox(
      width: span,
      height: seat,
      child: Row(
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < seats.length; i++) ...[
            if (i > 0) SizedBox(width: seats.length == 1 ? 0 : gap),
            if (seats.length == 1 && bounded) const Spacer(),
            SizedBox(
              width: _seatWidth(i, seats.length),
              height: seat,
              child: _SeatButton(
                seat: seats[i],
                markHeight: seat,
                driverIcon: true,
                badge: seats[i].isDriver ? null : badge,
                onTap: seats[i].isClaimable ? onSeatTap : null,
                onLongPress: seats[i].isClaimable ? onSeatLongPress : null,
              ),
            ),
            if (seats.length == 1 && bounded) const Spacer(),
          ],
        ],
      ),
    );
  }

  /// Widest row: one column each, square. Narrower rows: each seat
  /// spans `columns / count` and the row stays flush left and right.
  double _seatWidth(int index, int count) {
    if (count <= 1 || !width.isFinite) return seat;
    final raw = (width - (count - 1) * gap) / count;
    if (index < count - 1) return math.max(0.0, raw);
    final leading = (count - 1) * (raw + gap);
    return math.max(0.0, width - leading);
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
    if (text.contains('women')) return Icons.female_rounded;
    return Icons.sell_outlined;
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
    final path = _outline(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = line,
    );
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

  Path _outline(Size size) {
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

  @override
  bool shouldRepaint(covariant _CabinOutlinePainter oldDelegate) {
    return oldDelegate.palette.brightness != palette.brightness;
  }
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
    final showPrice =
        price != null && price.contains('₦') && seat.status != 'occupied';
    final showWheel = seat.isDriver && widget.driverIcon;
    final badge =
        widget.badge ?? (seat.status == 'held' ? Icons.schedule_rounded : null);
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
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(3, 12, 3, 4),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showWheel)
                                  _SteeringWheel(ink: palette.ink, size: 16)
                                else if (seat.isCargo)
                                  Icon(
                                    Icons.luggage_outlined,
                                    size: 14,
                                    color: ink,
                                  )
                                else if (seat.status == 'yours')
                                  Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: ink,
                                  )
                                else if (seat.status == 'occupied')
                                  Icon(
                                    Icons.person_rounded,
                                    size: 14,
                                    color: ink,
                                  ),
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
                      if (badge != null)
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
