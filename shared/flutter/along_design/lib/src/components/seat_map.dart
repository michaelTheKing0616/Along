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
    final chrome = _chromeFor(body, palette);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chrome.fill,
        borderRadius: BorderRadius.circular(chrome.radius),
        border: Border.all(color: chrome.border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s12,
          vertical: AlongSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (body == 'cabin' || body == 'coach' || body == 'danfo')
              Container(
                width: body == 'coach' || body == 'danfo' ? 96 : 64,
                height: 16,
                margin: const EdgeInsets.only(bottom: AlongSpace.s8),
                decoration: BoxDecoration(
                  color: palette.mapWater,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: palette.ink, width: 1.5),
                ),
              ),
            for (final row in rows) ...[
              if (row.ruleTitle != null && row.ruleTitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                  child: Text(
                    row.ruleTitle!,
                    key: Key('seat_row_rule_${row.id}'),
                    style: AlongText.caption.copyWith(
                      color: palette.brightness == Brightness.dark
                          ? palette.accent
                          : AlongColors.semanticWarning,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final seat in row.seats)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AlongSpace.s4,
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
                ),
              ),
            ],
            const SizedBox(height: AlongSpace.s8),
            Row(
              mainAxisAlignment: body == 'bike'
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                _Wheel(color: palette.ink, hub: palette.surface),
                if (body != 'bike')
                  _Wheel(color: palette.ink, hub: palette.surface),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static _BodyChrome _chromeFor(String body, AlongPalette palette) {
    switch (body) {
      case 'bench':
        return _BodyChrome(
          fill: palette.accent.withValues(alpha: 0.28),
          border: palette.accentInk,
          radius: 28,
        );
      case 'bike':
        return _BodyChrome(
          fill: palette.recessed,
          border: palette.ink,
          radius: 40,
        );
      case 'coach':
      case 'danfo':
        return _BodyChrome(
          fill: palette.surface,
          border: palette.ink,
          radius: 12,
        );
      case 'cabin':
      default:
        return _BodyChrome(
          fill: palette.surface,
          border: palette.ink,
          radius: 28,
        );
    }
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.color, required this.hub});

  final Color color;
  final Color hub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: hub, width: 4),
      ),
    );
  }
}

class _BodyChrome {
  const _BodyChrome({
    required this.fill,
    required this.border,
    required this.radius,
  });

  final Color fill;
  final Color border;
  final double radius;
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
    return Semantics(
      button: onTap != null,
      label: '${seat.label}, ${seat.statusWord}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: AlongSpace.sizeTouchMin,
          height: AlongSpace.sizeTouchMin,
          child: Material(
            color: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: _side(seat, palette),
            ),
            child: InkWell(
              key: Key('seat_${seat.id}'),
              onTap: onTap == null ? null : () => onTap!(seat.id),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(seat.id),
              child: Center(
                child: seat.isCargo
                    ? Icon(
                        Icons.luggage_outlined,
                        size: 20,
                        color: _ink(seat, palette),
                      )
                    : Text(
                        seat.isDriver ? 'D' : _short(seat.label),
                        style: AlongText.caption.copyWith(
                          color: _ink(seat, palette),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
          alpha: palette.brightness == Brightness.dark ? 0.38 : 0.16,
        );
    }
  }

  static BorderSide _side(SeatMapSeat seat, AlongPalette palette) {
    if (seat.status == 'yours') {
      return BorderSide(color: palette.accentInk, width: 2);
    }
    if (seat.status == 'held') {
      return BorderSide(color: palette.accent, width: 2);
    }
    if (seat.status == 'free') {
      return BorderSide(color: palette.success, width: 1.5);
    }
    return BorderSide(color: palette.ink);
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
