import 'package:flutter/material.dart';

import '../craft.dart';
import '../tokens.g.dart';

/// Driver availability states (doc 05 §9 `StatusToggle`).
enum DriverStatus { offline, atPark, roamingAvailable, roamingFull }

extension DriverStatusLabels on DriverStatus {
  String get label => switch (this) {
        DriverStatus.offline => 'Offline',
        DriverStatus.atPark => 'At park',
        DriverStatus.roamingAvailable => 'Roaming',
        DriverStatus.roamingFull => 'Full',
      };
}

/// Segmented driver status control — one tap changes state (no confirm).
class StatusToggle extends StatelessWidget {
  const StatusToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DriverStatus selected;
  final ValueChanged<DriverStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Driver status',
      child: Container(
        height: AlongSpace.sizeCtaPrimary,
        clipBehavior: Clip.antiAlias,
        decoration: AlongCraft.fill(
          AlongColors.surface100,
          corner: AlongRadius.control.x,
        ),
        padding: const EdgeInsets.all(AlongSpace.s4),
        child: Row(
          children: DriverStatus.values.map((status) {
            final isSelected = status == selected;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                label: status.label,
                child: Material(
                  color: isSelected
                      ? AlongColors.brandYellow
                      : Colors.transparent,
                  shape: AlongCraft.border(AlongRadius.control.x),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(status),
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: AlongColors.ink900.withValues(alpha: 0.08),
                    customBorder: AlongCraft.border(AlongRadius.control.x),
                    child: Center(
                      child: Text(
                        status.label,
                        style: AlongText.label.copyWith(
                          color: isSelected
                              ? AlongColors.brandYellowOn
                              : AlongColors.ink700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
