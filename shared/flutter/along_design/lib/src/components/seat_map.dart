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
    final chrome = _chromeFor(body);
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
            for (final row in rows) ...[
              if (row.ruleTitle != null && row.ruleTitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AlongSpace.s4),
                  child: Text(
                    row.ruleTitle!,
                    key: Key('seat_row_rule_${row.id}'),
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticWarning,
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
          ],
        ),
      ),
    );
  }

  static _BodyChrome _chromeFor(String body) {
    switch (body) {
      case 'bench':
        return const _BodyChrome(
          fill: AlongColors.brandYellowTint,
          border: AlongColors.brandYellow,
          radius: 28,
        );
      case 'bike':
        return const _BodyChrome(
          fill: AlongColors.surface200,
          border: AlongColors.ink900,
          radius: 40,
        );
      case 'coach':
        return const _BodyChrome(
          fill: AlongColors.surface0,
          border: AlongColors.ink900,
          radius: 12,
        );
      case 'cabin':
      default:
        return const _BodyChrome(
          fill: AlongColors.surface0,
          border: AlongColors.ink500,
          radius: 24,
        );
    }
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
    final color = _fill(seat);
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
              side: BorderSide(
                color: seat.isDriver ? AlongColors.ink900 : AlongColors.ink500,
              ),
            ),
            child: InkWell(
              key: Key('seat_${seat.id}'),
              onTap: onTap == null ? null : () => onTap!(seat.id),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(seat.id),
              child: Center(
                child: seat.isCargo
                    ? Icon(Icons.luggage_outlined, size: 20, color: _ink(seat))
                    : Text(
                        seat.isDriver ? 'D' : _short(seat.label),
                        style: AlongText.caption.copyWith(color: _ink(seat)),
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

  static Color _fill(SeatMapSeat seat) {
    if (seat.isDriver || seat.isCargo) return AlongColors.ink900;
    switch (seat.status) {
      case 'occupied':
        return AlongColors.ink900;
      case 'held':
        return AlongColors.brandYellow;
      case 'blocked':
        return AlongColors.surface200;
      default:
        return AlongColors.semanticSuccessTint;
    }
  }

  static Color _ink(SeatMapSeat seat) {
    if (seat.isDriver || seat.isCargo || seat.status == 'occupied') {
      return AlongColors.surface0;
    }
    return AlongColors.ink900;
  }
}
