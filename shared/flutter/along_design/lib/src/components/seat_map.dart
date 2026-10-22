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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(body == 'bike' ? 36 : 24),
        boxShadow: AlongElevation.card(palette.ink),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()..rotateX(0.04),
              child: CustomPaint(
                painter: _CabinPainter(body: body, palette: palette),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    body == 'bike' ? 20 : 36,
                    18,
                    22,
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SteeringWheel extends StatelessWidget {
  const _SteeringWheel();

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _WheelPainter(ink: palette.ink, hub: palette.surface),
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
    final radius = size.width / 2 - 1;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = ink;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, 3.2, Paint()..color = ink);
    final spoke = Paint()
      ..strokeWidth = 1.6
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

class _CabinPainter extends CustomPainter {
  _CabinPainter({required this.body, required this.palette});

  final String body;
  final AlongPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = palette.ink;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = ink.withValues(alpha: 0.55);
    final fill = Paint()..color = palette.recessed.withValues(alpha: 0.65);
    if (body == 'bike') {
      final rect = Rect.fromLTWH(
        size.width * 0.28,
        4,
        size.width * 0.44,
        size.height - 8,
      );
      final r = RRect.fromRectAndRadius(rect, const Radius.circular(28));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, outline);
      _wheel(canvas, Offset(size.width / 2, size.height - 10), 8, ink);
      return;
    }
    final rect = Rect.fromLTWH(18, 8, size.width - 36, size.height - 16);
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(28)));
    canvas.drawPath(
      bodyPath.shift(const Offset(0, 2)),
      Paint()..color = ink.withValues(alpha: 0.06),
    );
    canvas.drawPath(bodyPath, Paint()..color = palette.bg);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = ink.withValues(alpha: 0.35),
    );
  }

  void _wheel(Canvas canvas, Offset at, double radius, Color ink) {
    canvas.drawCircle(at, radius, Paint()..color = ink);
    canvas.drawCircle(
      at,
      radius * 0.52,
      Paint()..color = Color.lerp(palette.surface, ink, 0.35)!,
    );
    canvas.drawCircle(at, radius * 0.2, Paint()..color = palette.surface);
  }

  @override
  bool shouldRepaint(covariant _CabinPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.palette.brightness != palette.brightness;
}

class _SeatButton extends StatefulWidget {
  const _SeatButton({
    required this.seat,
    required this.onTap,
    required this.onLongPress,
  });

  final SeatMapSeat seat;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;

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
          height: 86,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 20, 6, 4),
                      child: Column(
                        children: [
                          const Spacer(),
                          if (seat.isCargo)
                            Icon(Icons.luggage_outlined, size: 18, color: ink)
                          else
                            Text(
                              seat.isDriver ? 'DRV' : _short(seat.label),
                              maxLines: 1,
                              softWrap: false,
                              style: AlongText.caption.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          const Spacer(),
                          if (showPrice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: seat.status == 'yours'
                                    ? palette.ink
                                    : palette.surface,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: palette.ink.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                price,
                                maxLines: 1,
                                softWrap: false,
                                style: AlongText.caption.copyWith(
                                  color: seat.status == 'yours'
                                      ? palette.surface
                                      : ink,
                                  fontSize: 10,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 14),
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

  static String _short(String label) {
    final trimmed = label.trim();
    if (trimmed.length <= 3) return trimmed;
    final parts = trimmed.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return parts.take(2).map((part) => part.substring(0, 1)).join();
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
    final rect = Rect.fromLTWH(12, 10, size.width - 24, size.height - 30);
    final pad = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    if (selected) {
      canvas.drawRRect(
        pad.inflate(2 + pulse * 1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = palette.accent.withValues(alpha: 0.45 + pulse * 0.35),
      );
    }
    canvas.drawRRect(
      pad.shift(const Offset(0, 1)),
      Paint()..color = palette.ink.withValues(alpha: 0.06),
    );
    canvas.drawRRect(pad, Paint()..color = cushion);
    canvas.drawRRect(
      pad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = palette.ink.withValues(alpha: selected ? 0.55 : 0.22),
    );
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, rect.top + 6),
        width: size.width * 0.36,
        height: 7,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      head,
      Paint()..color = palette.ink.withValues(alpha: selected ? 0.28 : 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _SeatPainter oldDelegate) {
    return oldDelegate.seat.status != seat.status ||
        oldDelegate.seat.role != seat.role ||
        oldDelegate.pulse != pulse ||
        oldDelegate.palette.brightness != palette.brightness;
  }
}
