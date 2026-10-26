import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

/// Radio list of the driver's vehicles: plate, make, seats.
class DayVehiclePicker extends StatelessWidget {
  const DayVehiclePicker({
    super.key,
    required this.vehicles,
    required this.selectedId,
    required this.seatsLabel,
    required this.onSelect,
  });

  final List<DayVehicle> vehicles;
  final String? selectedId;
  final String Function(int seats) seatsLabel;
  final ValueChanged<DayVehicle> onSelect;

  @override
  Widget build(BuildContext context) {
    return DriveRows(
      children: [
        for (final item in vehicles)
          DriveRow(
            key: Key('day_vehicle_${item.id}'),
            icon: AlongIcons.danfo,
            title: item.plateNumber,
            detail: [
              if (item.makeModel != null) item.makeModel!,
              seatsLabel(item.seatCapacity),
            ].join(' · '),
            selected: item.id == selectedId,
            onTap: () => onSelect(item),
          ),
      ],
    );
  }
}

/// Shift start / end side by side, then the home-bound stop.
class DayHoursFields extends StatelessWidget {
  const DayHoursFields({
    super.key,
    required this.start,
    required this.end,
    required this.home,
    required this.startLabel,
    required this.endLabel,
    required this.homeLabel,
  });

  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController home;
  final String startLabel;
  final String endLabel;
  final String homeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('day_shift_start'),
                controller: start,
                keyboardType: TextInputType.datetime,
                decoration: driveInput(
                  context,
                  startLabel,
                ).copyWith(hintText: '06:30'),
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: TextField(
                key: const Key('day_shift_end'),
                controller: end,
                keyboardType: TextInputType.datetime,
                decoration: driveInput(
                  context,
                  endLabel,
                ).copyWith(hintText: '18:00'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AlongSpace.s8),
        TextField(
          key: const Key('day_home_label'),
          controller: home,
          decoration: driveInput(context, homeLabel),
        ),
      ],
    );
  }
}

/// Numbers and wording applied to the next preset rule you add.
class DayRuleDetailsFields extends StatelessWidget {
  const DayRuleDetailsFields({
    super.key,
    required this.minutes,
    required this.walk,
    required this.max,
    required this.title,
    required this.body,
    required this.minutesLabel,
    required this.walkLabel,
    required this.maxLabel,
    required this.titleLabel,
    required this.bodyLabel,
  });

  final TextEditingController minutes;
  final TextEditingController walk;
  final TextEditingController max;
  final TextEditingController title;
  final TextEditingController body;
  final String minutesLabel;
  final String walkLabel;
  final String maxLabel;
  final String titleLabel;
  final String bodyLabel;

  @override
  Widget build(BuildContext context) {
    Widget number(Key? key, TextEditingController c, String label) => Expanded(
      child: TextField(
        key: key,
        controller: c,
        keyboardType: TextInputType.number,
        decoration: driveInput(context, label),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AlongSpace.s12),
      child: Column(
        children: [
          Row(
            children: [
              number(null, minutes, minutesLabel),
              const SizedBox(width: AlongSpace.s8),
              number(const Key('day_walk_minutes'), walk, walkLabel),
              const SizedBox(width: AlongSpace.s8),
              number(null, max, maxLabel),
            ],
          ),
          const SizedBox(height: AlongSpace.s8),
          TextField(
            controller: title,
            decoration: driveInput(context, titleLabel),
          ),
          const SizedBox(height: AlongSpace.s8),
          TextField(
            controller: body,
            decoration: driveInput(context, bodyLabel),
          ),
        ],
      ),
    );
  }
}
