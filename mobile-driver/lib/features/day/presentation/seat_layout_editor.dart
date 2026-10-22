import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';

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
  });

  final SeatLayout layout;
  final int reviewSeatMax;
  final ValueChanged<SeatLayout> onChanged;
  final String addRowLabel;
  final String addSeatLabel;
  final String removeRowLabel;
  final String overCapacityLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in layout.rows) ...[
          Row(
            children: [
              Text(row.id, style: AlongText.label),
              const Spacer(),
              IconButton(
                key: Key('seat_add_${row.id}'),
                tooltip: addSeatLabel,
                onPressed: () => onChanged(layout.addSeat(row.id)),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                key: Key('seat_remove_row_${row.id}'),
                tooltip: removeRowLabel,
                onPressed: layout.rows.length > 1
                    ? () => onChanged(layout.removeRow(row.id))
                    : null,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          Wrap(
            spacing: AlongSpace.s8,
            runSpacing: AlongSpace.s8,
            children: [
              for (final seat in row.seats)
                ActionChip(
                  key: Key('layout_seat_${seat.id}'),
                  label: Text(seat.isPassenger ? seat.label : seat.label),
                  avatar: Icon(
                    seat.isPassenger
                        ? Icons.event_seat
                        : Icons.airline_seat_recline_extra,
                    size: 18,
                  ),
                  onPressed: () => onChanged(layout.markDriver(seat.id)),
                ),
            ],
          ),
          const SizedBox(height: AlongSpace.s8),
        ],
        AlongButton(
          key: const Key('seat_layout_add_row'),
          label: addRowLabel,
          variant: AlongButtonVariant.secondary,
          onPressed: () => onChanged(layout.addRow()),
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
