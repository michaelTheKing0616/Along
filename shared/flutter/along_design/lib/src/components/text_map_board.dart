import 'dart:math' as math;

import 'package:along_design/src/tokens.g.dart';
import 'package:flutter/material.dart';

/// One row in the tile-free list. [heading] is a compass label such as N or NE.
class TextMapEntry {
  const TextMapEntry({
    required this.id,
    required this.title,
    required this.detail,
    required this.heading,
  });

  final String id;
  final String title;
  final String detail;
  final String heading;
}

/// List-and-arrow supply view used when the map tiles stay off.
class TextMapBoard extends StatelessWidget {
  const TextMapBoard({
    super.key,
    required this.title,
    required this.emptyLabel,
    required this.rows,
    this.onRowTap,
  });

  final String title;
  final String emptyLabel;
  final List<TextMapEntry> rows;
  final ValueChanged<String>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface0,
      child: SafeArea(
        child: rows.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AlongSpace.s24),
                child: Text(emptyLabel, style: AlongText.body),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s16,
                  AlongSpace.s64,
                  AlongSpace.s16,
                  AlongSpace.s24,
                ),
                children: [
                  Text(title, style: AlongText.heading2),
                  const SizedBox(height: AlongSpace.s12),
                  for (final row in rows)
                    ListTile(
                      key: Key('text_map_${row.id}'),
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: AlongSpace.s12,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeadingArrow(heading: row.heading),
                          if (row.heading.trim().isNotEmpty)
                            Text(row.heading, style: AlongText.label),
                        ],
                      ),
                      title: Text(row.title, style: AlongText.bodyStrong),
                      subtitle: Text(row.detail, style: AlongText.caption),
                      onTap: onRowTap == null ? null : () => onRowTap!(row.id),
                    ),
                ],
              ),
      ),
    );
  }
}

class _HeadingArrow extends StatelessWidget {
  const _HeadingArrow({required this.heading});

  final String heading;

  @override
  Widget build(BuildContext context) {
    final degrees = _degrees(heading);
    final arrow = Transform.rotate(
      angle: degrees * math.pi / 180,
      child: const Icon(
        Icons.navigation_rounded,
        color: AlongColors.ink900,
        size: 24,
      ),
    );
    if (heading.trim().isEmpty) return arrow;
    return Semantics(label: heading, child: arrow);
  }

  static double _degrees(String heading) {
    return switch (heading.trim().toUpperCase()) {
      'N' => 0,
      'NE' => 45,
      'E' => 90,
      'SE' => 135,
      'S' => 180,
      'SW' => 225,
      'W' => 270,
      'NW' => 315,
      _ => 0,
    };
  }
}
