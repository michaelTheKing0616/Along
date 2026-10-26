import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// Add and remove rows and seats. The driver marks exactly one driver seat.
class SeatLayoutEditor extends StatelessWidget {
  const SeatLayoutEditor({
    super.key,
    required this.layout,
    required this.reviewSeatMax,
    required this.onChanged,
    required this.addRowLabel,
    required this.addSeatLabel,
    required this.removeRowLabel,
    required this.overCapacityLabel,
    this.luggageLabel = 'Luggage',
  });

  final SeatLayout layout;
  final int reviewSeatMax;
  final ValueChanged<SeatLayout> onChanged;
  final String addRowLabel;
  final String addSeatLabel;
  final String removeRowLabel;
  final String overCapacityLabel;
  final String luggageLabel;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DriveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (n, row) in layout.rows.indexed) ...[
                if (n > 0) const SizedBox(height: AlongSpace.s16),
                Row(
                  children: [
                    Text(
                      row.id.isEmpty
                          ? row.id
                          : row.id[0].toUpperCase() + row.id.substring(1),
                      style: AlongType.label(p),
                    ),
                    const Spacer(),
                    _RoundIcon(
                      key: Key('seat_add_${row.id}'),
                      tooltip: addSeatLabel,
                      icon: Icons.add,
                      onTap: () => onChanged(layout.addSeat(row.id)),
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    _RoundIcon(
                      key: Key('seat_remove_row_${row.id}'),
                      tooltip: removeRowLabel,
                      icon: Icons.delete_outline,
                      onTap: layout.rows.length > 1
                          ? () => onChanged(layout.removeRow(row.id))
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s8),
                Wrap(
                  spacing: AlongSpace.s8,
                  runSpacing: AlongSpace.s8,
                  children: [
                    for (final seat in row.seats)
                      _SeatTile(
                        seat: seat,
                        luggageLabel: luggageLabel,
                        onTap: () => onChanged(layout.markDriver(seat.id)),
                        onLuggage: seat.isPassenger || seat.isCargo
                            ? () => onChanged(layout.markCargo(seat.id))
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AlongSpace.s12),
        DriveChips(
          items: [
            (
              const Key('seat_layout_add_row'),
              '+ $addRowLabel',
              false,
              () => onChanged(layout.addRow()),
            ),
          ],
        ),
        if (layout.overCapacity(reviewSeatMax)) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            overCapacityLabel,
            key: const Key('seat_over_capacity'),
            style: AlongText.caption.copyWith(
              color: AlongColors.semanticWarning,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.recessed,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 18,
              color: onTap == null ? p.ink.withValues(alpha: 0.3) : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact squircle seat: tap to make it the driver seat; corner badge
/// toggles luggage.
class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.seat,
    required this.luggageLabel,
    required this.onTap,
    required this.onLuggage,
  });

  final SeatSpec seat;
  final String luggageLabel;
  final VoidCallback onTap;
  final VoidCallback? onLuggage;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final driver = !seat.isPassenger && !seat.isCargo;
    final fg = driver ? p.onInk : p.ink;
    // The stack is padded so the 44px luggage hit area stays inside its
    // bounds (Flutter does not hit-test outside a widget's box).
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            width: 64,
            height: 64,
            child: Material(
              key: Key('layout_seat_${seat.id}'),
              color: driver ? p.ink : p.recessed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      seat.isCargo
                          ? Icons.luggage_outlined
                          : driver
                          ? Icons.airline_seat_recline_extra
                          : Icons.event_seat_outlined,
                      size: 20,
                      color: fg,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.caption(p).copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onLuggage != null)
            Positioned(
              top: 0,
              right: 0,
              child: Tooltip(
                message: luggageLabel,
                child: Semantics(
                  button: true,
                  label: luggageLabel,
                  child: GestureDetector(
                    key: Key('layout_luggage_${seat.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onLuggage,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: seat.isCargo ? p.accent : p.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.ink.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Icon(Icons.luggage, size: 13, color: p.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
