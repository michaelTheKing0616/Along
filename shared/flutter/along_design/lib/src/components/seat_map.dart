import 'package:along_design/src/elevation.dart';
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
  });

  final String id;
  final String label;

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
            CustomPaint(
              painter: _CabinPainter(body: body, palette: palette),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  8,
                  body == 'bike' ? 16 : 28,
                  8,
                  18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final seat in row.seats) ...[
                              if (seat.isDriver && body != 'bike')
                                const _SteeringWheel(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
      _wheel(canvas, Offset(size.width / 2, size.height - 10), ink);
      return;
    }
    final rect = Rect.fromLTWH(6, 2, size.width - 12, size.height - 4);
    final cabin = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(cabin, fill);
    canvas.drawRRect(cabin, outline);
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, 8, size.width * 0.56, 14),
      const Radius.circular(7),
    );
    canvas.drawRRect(glass, Paint()..color = palette.mapWater);
    canvas.drawRRect(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ink.withValues(alpha: 0.25),
    );
    _wheel(canvas, Offset(18, size.height - 8), ink);
    _wheel(canvas, Offset(size.width - 18, size.height - 8), ink);
  }

  void _wheel(Canvas canvas, Offset at, Color ink) {
    canvas.drawCircle(at, 7, Paint()..color = ink);
    canvas.drawCircle(at, 3, Paint()..color = palette.surface);
  }

  @override
  bool shouldRepaint(covariant _CabinPainter oldDelegate) =>
      oldDelegate.body != body ||
      oldDelegate.palette.brightness != palette.brightness;
}

class _SeatButton extends StatelessWidget {
  const _SeatButton({
    required this.seat,
    required this.onTap,
    required this.onLongPress,
  });

  final SeatMapSeat seat;
  final ValueChanged<String>? onTap;
  final ValueChanged<String>? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final color = _fill(seat, palette);
    final ink = _ink(seat, palette);
    return Semantics(
      button: onTap != null,
      label: '${seat.label}, ${seat.statusWord}',
      child: ExcludeSemantics(
        child: SizedBox(
          key: Key('seat_${seat.id}'),
          width: AlongSpace.sizeTouchMin,
          height: 52,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap == null ? null : () => onTap!(seat.id),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(seat.id),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                          bottom: Radius.circular(8),
                        ),
                        border: Border.fromBorderSide(_side(seat, palette)),
                      ),
                      child: seat.isCargo
                          ? Icon(Icons.luggage_outlined, size: 18, color: ink)
                          : Text(
                              seat.isDriver ? 'D' : _short(seat.label),
                              style: AlongText.caption.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 32,
                    height: 7,
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: seat.isDriver ? 0.9 : 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _short(String label) {
    final parts = label.split(' ').where((part) => part.isNotEmpty).toList();
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

  static BorderSide _side(SeatMapSeat seat, AlongPalette palette) {
    if (seat.status == 'held') {
      return BorderSide(color: palette.accent, width: 2);
    }
    return BorderSide.none;
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
