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
class SortChips extends StatefulWidget {
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
  State<SortChips> createState() => _SortChipsState();
}

class _SortChipsState extends State<SortChips> {
  final _scroll = ScrollController();
  var _fadeStart = false;
  var _fadeEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    final start = p.pixels > 1;
    final end = p.pixels < p.maxScrollExtent - 1;
    if (start != _fadeStart || end != _fadeEnd) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    // One line that scrolls sideways, so long translations never wrap.
    // Edges fade where more chips sit off screen, so the row reads as
    // scrollable instead of cut off.
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [
          if (_fadeStart) const Color(0x00000000) else const Color(0xFF000000),
          const Color(0xFF000000),
          const Color(0xFF000000),
          if (_fadeEnd) const Color(0x00000000) else const Color(0xFF000000),
        ],
        stops: [0, 32 / rect.width, 1 - 48 / rect.width, 1],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: SortOption.values.map((option) {
            final isSelected = option == widget.selected;
            final label = widget.labels?[option] ?? option.label;
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
                  shape: AlongCraft.compact(44),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.onSelected(option),
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: palette.ink.withValues(alpha: 0.08),
                    customBorder: AlongCraft.compact(44),
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
      ),
    );
  }
}
