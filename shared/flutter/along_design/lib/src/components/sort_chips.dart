import 'package:flutter/material.dart';

import '../tokens.g.dart';

/// Trip option sort criteria (doc 05 §9 `SortChips`).
enum SortOption { recommended, cheapest, fastest, leastStrenuous }

extension SortOptionLabels on SortOption {
  String get label => switch (this) {
        SortOption.recommended => 'Recommended',
        SortOption.cheapest => 'Cheapest',
        SortOption.fastest => 'Fastest',
        SortOption.leastStrenuous => 'Least strenuous',
      };
}

/// Single-select sort chip row — persists via caller's [selected] / [onSelected].
class SortChips extends StatelessWidget {
  const SortChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SortOption selected;
  final ValueChanged<SortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AlongSpace.s8,
      runSpacing: AlongSpace.s8,
      children: SortOption.values.map((option) {
        final isSelected = option == selected;
        return Semantics(
          button: true,
          selected: isSelected,
          label: option.label,
          child: Material(
            color: isSelected ? AlongColors.brandYellow : AlongColors.surface100,
            borderRadius: BorderRadius.circular(AlongRadius.sm.x),
            child: InkWell(
              onTap: () => onSelected(option),
              splashFactory: NoSplash.splashFactory,
              highlightColor: AlongColors.ink900.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AlongRadius.sm.x),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AlongSpace.s12,
                  vertical: AlongSpace.s8,
                ),
                child: Text(
                  option.label,
                  style: AlongText.label.copyWith(
                    color: isSelected
                        ? AlongColors.brandYellowOn
                        : AlongColors.ink700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
