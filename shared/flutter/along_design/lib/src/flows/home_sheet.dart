import 'package:flutter/material.dart';

import '../craft.dart';
import '../icons.dart';
import '../motion.dart';
import '../palette.dart';
import '../tokens.g.dart';
import '../type.dart';

/// One tappable place on the home sheet: a saved place, a recent, or a
/// nearby ride. [onTap] fires on the whole row; [action] adds one ink word.
class AlongPlace {
  const AlongPlace({
    required this.icon,
    required this.title,
    this.detail,
    this.onTap,
    this.action,
    this.onAction,
    this.key,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final String? action;
  final VoidCallback? onAction;
  final Key? key;
}

/// The ink "Where to?" bar. One tap opens search.
class AlongWhereToBar extends StatelessWidget {
  const AlongWhereToBar({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AlongPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null
              ? null
              : () {
                  AlongHaptics.tick(context);
                  onTap!();
                },
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: palette.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(AlongRadius.button),
              ),
            ),
            child: Row(
              children: [
                AlongIcon(AlongIcons.search, color: palette.onInk, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.title(palette)
                        .copyWith(color: palette.onInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 48pt place row with a recessed icon tile.
class AlongPlaceRow extends StatelessWidget {
  const AlongPlaceRow({super.key, required this.place});

  final AlongPlace place;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final detail = place.detail;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: AlongCraft.fill(
                palette.recessed,
                corner: AlongRadius.control.x,
              ),
              child: AlongIcon(place.icon, size: 20, color: palette.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.body(palette),
                  ),
                  if (detail != null && place.action != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.caption(palette),
                    ),
                ],
              ),
            ),
            if (place.action != null)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: place.onAction == null
                      ? null
                      : () {
                          AlongHaptics.tick(context);
                          place.onAction!();
                        },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                    child: Text(
                      place.action!,
                      maxLines: 1,
                      softWrap: false,
                      style: AlongType.label(palette).copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else if (detail != null) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AlongType.caption(palette).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (place.onTap == null) return KeyedSubtree(key: place.key, child: row);
    return Semantics(
      key: place.key,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AlongHaptics.tick(context);
          place.onTap!();
        },
        child: row,
      ),
    );
  }
}

/// Home sheet body: an optional [lead] (live trip strip, banner), the
/// Where-to bar, then [places]. Rows stay one tap from a quote.
class AlongHomeSheet extends StatelessWidget {
  const AlongHomeSheet({
    super.key,
    required this.whereTo,
    this.onWhereTo,
    this.whereToKey,
    this.lead,
    this.places = const <AlongPlace>[],
    this.sectionTitle,
    this.section = const <AlongPlace>[],
  });

  final String whereTo;
  final VoidCallback? onWhereTo;
  final Key? whereToKey;
  final Widget? lead;
  final List<AlongPlace> places;
  final String? sectionTitle;
  final List<AlongPlace> section;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lead != null) ...[lead!, const SizedBox(height: 12)],
        AlongWhereToBar(key: whereToKey, label: whereTo, onTap: onWhereTo),
        if (places.isNotEmpty) const SizedBox(height: 8),
        for (final place in places) AlongPlaceRow(place: place),
        if (section.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (sectionTitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                sectionTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AlongType.label(palette),
              ),
            ),
          for (final place in section) AlongPlaceRow(place: place),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
