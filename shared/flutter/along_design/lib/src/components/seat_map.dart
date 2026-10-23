import 'dart:math' as math;

import 'package:along_design/src/elevation.dart';
import 'package:along_design/src/motion.dart';
import 'package:along_design/src/palette.dart';
import 'package:along_design/src/tokens.g.dart';
import 'package:flutter/material.dart';

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
    // The sedan photograph is the cabin shell. Danfo, keke, bike, and coach
    // stay on the schematic because they have no matching interior.
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
            // children. The cabin photo has to take the leftover space or
            // the 864×1152 shell overflows a bounded test surface. Schematic
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

/// Photograph is 864×1152, nose up, steering wheel on the left.
/// Front row is a three-cushion bench (seams near x 0.46 and 0.54).
/// The rear is one bench. Four markers share that full width, centered
/// on the cushion rather than the trunk lip. Marker count still comes
/// from the row list. A bounded cabin stretches the crop to the card.
class _CabinShell extends StatelessWidget {
  const _CabinShell({
    required this.rows,
    required this.onSeatTap,
    required this.onSeatLongPress,
  });

  final List<SeatMapRowView> rows;
  final ValueChanged<String>? onSeatTap;
  final ValueChanged<String>? onSeatLongPress;

  /// Cabin window. Cuts the doors and the trunk lip so the benches
  /// fill the card, and a 48dp marker still fits one front cushion.
  static const _cropL = 0.31;
  static const _cropT = 0.18;
  static const _cropR = 0.69;
  static const _cropB = 0.62;
  static const _cropAspect =
      ((_cropR - _cropL) * 864) / ((_cropB - _cropT) * 1152);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        // A finite slot is the card interior. Stretch the crop to fill it
        // so the cabin does not letterbox a white band under the bench.
        // Unbounded callers keep the crop's own aspect.
        final width = maxW;
        final height = maxH.isFinite ? maxH : width / _cropAspect;
        return SizedBox(
          width: width,
          height: height,
          child: _shell(width, height),
        );
      },
    );
  }

  Widget _shell(double width, double height) {
    final markers = <Widget>[];
    for (var r = 0; r < rows.length; r++) {
      final seats = _driverFirst(rows[r].seats);
      final count = seats.length;
      const seatH = 48.0;
      // 48dp keeps the hit target at AlongSpace.sizeTouchMin. The painted
      // cushion is inset inside that box.
      const seatW = 48.0;
      final xs = _photoXs(r, rows.length, count);
      final photoY = _photoY(r, rows.length);
      final top = (_mapY(photoY, height) - seatH / 2)
          .clamp(0.0, math.max(0.0, height - seatH))
          .toDouble();
      for (var s = 0; s < count; s++) {
        final seat = seats[s];
        final left = (_mapX(xs[s], width) - seatW / 2)
            .clamp(0.0, math.max(0.0, width - seatW))
            .toDouble();
        markers.add(
          Positioned(
            left: left,
            top: top,
            width: seatW,
            height: seatH,
            child: _SeatButton(
              seat: seat,
              markHeight: seatH,
              driverIcon: seat.isDriver,
              onTap: seat.isClaimable ? onSeatTap : null,
              onLongPress: seat.isClaimable ? onSeatLongPress : null,
            ),
          ),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(child: _cabinPhoto()),
          ...markers,
        ],
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

  /// Cushion centers in full-photo fractions, left to right.
  /// Driver is sorted first, so the left front center is the wheel side.
  /// Front seams are at 0.46 and 0.54; 0.50 is the middle cushion.
  /// The rear bench fabric runs about x 0.34–0.66. Four markers split
  /// that width into equal slots (the photo reads as three cushions).
  static List<double> _photoXs(int index, int rowCount, int count) {
    final front = rowCount <= 1 || index == 0;
    if (front && count == 2) return const [0.39, 0.60];
    if (front && count == 3) return const [0.39, 0.50, 0.60];
    if (!front && count == 4) return const [0.38, 0.46, 0.54, 0.62];
    const start = 0.34;
    const end = 0.66;
    if (count <= 1) return const [(start + end) / 2];
    return [
      for (var i = 0; i < count; i++) start + (end - start) * i / (count - 1),
    ];
  }

  /// Front cushion center is y 0.395. Rear cushion fabric is y 0.525–0.58;
  /// 0.55 sits on that band. 0.575 dropped the marker onto the trunk lip.
  static double _photoY(int index, int rowCount) {
    const frontY = 0.395;
    const rearY = 0.55;
    if (rowCount <= 1) return frontY;
    if (rowCount == 2) return index == 0 ? frontY : rearY;
    final t = index / (rowCount - 1);
    return frontY + (rearY - frontY) * t;
  }

  static double _mapX(double photo, double width) =>
      (photo - _cropL) / (_cropR - _cropL) * width;

  static double _mapY(double photo, double height) =>
      (photo - _cropT) / (_cropB - _cropT) * height;

  static Widget _cabinPhoto() {
    const photoW = 864.0;
    const photoH = 1152.0;
    return FittedBox(
      fit: BoxFit.fill,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: (_cropR - _cropL) * photoW,
        height: (_cropB - _cropT) * photoH,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: photoW,
          maxWidth: photoW,
          minHeight: photoH,
          maxHeight: photoH,
          child: Transform.translate(
            offset: const Offset(-_cropL * photoW, -_cropT * photoH),
            child: Image.asset(
              'assets/photos/car-cabin-top.jpg',
              package: 'along_design',
              width: photoW,
              height: photoH,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
          ),
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
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.seat.status == 'yours') {
      if (AlongMotionPolicy.inWidgetTest) {
        _pulse.value = 0.62;
      } else {
        _pulse.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final palette = AlongPalette.of(context);
    final ink = _ink(seat, palette);
    final price = seat.price;
    final showPrice = price != null && price.contains('₦');
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
                animation: _pulse,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SeatPainter(
                      seat: seat,
                      palette: palette,
                      pulse: seat.status == 'yours' ? _pulse.value : 0,
                    ),
                    child: seat.isDriver && widget.driverIcon
                        ? Align(
                            alignment: const Alignment(0, 0.15),
                            child: _SteeringWheel(ink: palette.onInk, size: 30),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(2, 6, 2, 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (seat.isCargo)
                                  Icon(
                                    Icons.luggage_outlined,
                                    size: 16,
                                    color: ink,
                                  )
                                else if (!seat.isDriver)
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
                                if (showPrice) ...[
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _fill(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver || seat.isCargo || seat.status == 'occupied') {
      return palette.ink;
    }
    switch (seat.status) {
      case 'held':
        return palette.surface;
      case 'yours':
        return palette.accent;
      case 'blocked':
        return palette.recessed;
      default:
        return palette.success.withValues(
          alpha: palette.brightness == Brightness.dark ? 0.38 : 0.22,
        );
    }
  }

  static Color _ink(SeatMapSeat seat, AlongPalette palette) {
    if (seat.isDriver || seat.isCargo || seat.status == 'occupied') {
      return palette.onInk;
    }
    if (seat.status == 'yours') return palette.accentInk;
    if (seat.status == 'blocked') return palette.muted;
    return palette.ink;
  }
}

class _SeatPainter extends CustomPainter {
  _SeatPainter({
    required this.seat,
    required this.palette,
    required this.pulse,
  });

  final SeatMapSeat seat;
  final AlongPalette palette;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final cushion = _SeatButtonState._fill(seat, palette);
    final selected = seat.status == 'yours';
    final ink = palette.ink;
    final head = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, 3, size.width * 0.44, 8),
      const Radius.circular(4),
    );
    final pad = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 12, size.width - 4, size.height - 15),
      const Radius.circular(8),
    );
    if (selected) {
      canvas.drawRRect(
        pad.inflate(2 + pulse * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.accent.withValues(alpha: 0.45 + pulse * 0.35),
      );
    }
    final shadow = Paint()..color = ink.withValues(alpha: 0.08);
    canvas.drawRRect(pad.shift(const Offset(0, 1)), shadow);
    canvas.drawRRect(pad, Paint()..color = cushion);
    canvas.drawRRect(
      head,
      Paint()..color = Color.lerp(cushion, ink, selected ? 0.4 : 0.32)!,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = ink.withValues(alpha: selected ? 0.7 : 0.28);
    canvas.drawRRect(pad, stroke);
    canvas.drawRRect(head, stroke);
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.seat.role != seat.role ||
        oldDelegate.pulse != pulse ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
