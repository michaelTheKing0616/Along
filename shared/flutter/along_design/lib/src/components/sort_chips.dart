import 'package:flutter/material.dart';

import '../craft.dart';
import '../palette.dart';
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
    this.labels,
  });

  final SortOption selected;
  final ValueChanged<SortOption> onSelected;

  /// Translated labels. Missing entries fall back to the English label.
  final Map<SortOption, String>? labels;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    // One line that scrolls sideways, so long translations never wrap.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: SortOption.values.map((option) {
          final isSelected = option == selected;
          final label = labels?[option] ?? option.label;
          return Padding(
            padding: EdgeInsets.only(
              right: option == SortOption.values.last ? 0 : AlongSpace.s8,
            ),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: label,
              excludeSemantics: true,
              child: Material(
                color: isSelected ? palette.accent : palette.recessed,
                shape: AlongCraft.border(AlongRadius.control.x),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(option),
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: palette.ink.withValues(alpha: 0.08),
                  customBorder: AlongCraft.border(AlongRadius.control.x),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AlongSpace.s12,
                      vertical: AlongSpace.s12,
                    ),
                    child: Text(
                      label,
                      style: AlongText.label.copyWith(
                        color: isSelected ? palette.accentInk : palette.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
