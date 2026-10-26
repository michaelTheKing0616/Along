import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/offline/stale_badge.dart';
import 'package:mobile_rider/features/search/data/popular_places.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/l10n/l10n_format.dart';

/// Selected destination from R-06 search (places-search or recents).
class DestinationPick {
  const DestinationPick({
    required this.name,
    required this.location,
    this.referenceId,
    this.kind = 'place',
  });

  final String name;
  final GeoPoint location;
  final String? referenceId;
  final String kind;

  factory DestinationPick.fromPlace(PlaceResult place) => DestinationPick(
    name: place.name,
    location: place.location,
    referenceId: place.id,
    kind: place.kind,
  );

  factory DestinationPick.fromRecent(RecentPlace recent) => DestinationPick(
    name: recent.label,
    location: recent.location,
    referenceId: recent.id,
    kind: recent.kind,
  );

  PlacementContext? toPlacementContext() {
    final id = referenceId;
    if (id == null || id.isEmpty) return null;
    final type = switch (kind) {
      'park' => PlacementContextType.park,
      'stage' => PlacementContextType.destination,
      _ => null,
    };
    if (type == null) return null;
    return PlacementContext(type: type, targetReference: id);
  }

  Map<String, dynamic> toNewAlightPayload() => {
    if (referenceId != null && kind == 'stage') 'stage_id': referenceId,
    'lat': location.lat,
    'lng': location.lng,
    'name': name,
  };
}

/// Reusable R-06 search field + recents + places-search results.
class DestinationSearchPanel extends ConsumerStatefulWidget {
  const DestinationSearchPanel({
    super.key,
    required this.onDestinationSelected,
    this.hint,
    this.embedded = false,
    this.initialQuery,
    this.onChooseOnMap,
    this.extra,
  });

  /// Shown under Choose on map while nothing is typed (the voice field).
  final Widget? extra;

  /// Shows a Choose on map row under the field when set.
  final VoidCallback? onChooseOnMap;

  final ValueChanged<DestinationPick> onDestinationSelected;
  final String? hint;
  final bool embedded;
  final String? initialQuery;

  @override
  ConsumerState<DestinationSearchPanel> createState() =>
      _DestinationSearchPanelState();
}

class _DestinationSearchPanelState
    extends ConsumerState<DestinationSearchPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    final seeded = widget.initialQuery?.trim() ?? '';
    if (seeded.length >= 2) {
      Future.microtask(
        () =>
            ref.read(searchControllerProvider.notifier).onQueryChanged(seeded),
      );
    }
  }

  @override
  void didUpdateWidget(covariant DestinationSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialQuery;
    if (next != null &&
        next != oldWidget.initialQuery &&
        next != _controller.text) {
      _controller.text = next;
      ref.read(searchControllerProvider.notifier).onQueryChanged(next);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectPlace(PlaceResult place) async {
    await ref.read(searchControllerProvider.notifier).selectPlace(place);
    widget.onDestinationSelected(DestinationPick.fromPlace(place));
  }

  Future<void> _selectRecent(RecentPlace recent) async {
    widget.onDestinationSelected(DestinationPick.fromRecent(recent));
  }

  static IconData kindIcon(String kind) => switch (kind) {
    'park' => AlongIcons.bus,
    'stage' => AlongIcons.signpost,
    'market' => AlongIcons.storefront,
    'home' => AlongIcons.home,
    'work' => AlongIcons.work,
    _ => AlongIcons.mapPin,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final l10n = AppLocalizations.of(context);
    final palette = AlongPalette.of(context);
    final searching = state.query.length >= 2;
    // Search opens from home, so home is alive; never boot it from here.
    final home = ref.exists(homeControllerProvider)
        ? ref.watch(homeControllerProvider)
        : null;
    final city = home?.cityName;
    final here = home?.userLocation;
    String? away(GeoPoint to) => here == null
        ? null
        : l10n.placeAway(l10n.distance(haversineDistanceM(here, to)));
    final recentNames = {for (final r in state.recents) r.label};
    final popular = [
      for (final p
          in popularPlacesByCity[city?.toLowerCase()] ?? const <PopularPlace>[])
        if (!recentNames.contains(p.name)) p,
    ];

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AlongSpace.s4,
        AlongSpace.s20,
        AlongSpace.s4,
        AlongSpace.s8,
      ),
      child: Text(title, style: AlongType.label(palette)),
    );
    // Rows sit on one raised card, so the list reads as a group.
    Widget card(List<Widget> rows) => DecoratedBox(
      decoration: AlongCraft.surface(palette, radius: AlongRadius.card.x),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s12,
          vertical: AlongSpace.s4,
        ),
        child: Column(children: rows),
      ),
    );

    final body = <Widget>[
      if (widget.onChooseOnMap != null && !searching) ...[
        const SizedBox(height: AlongSpace.s12),
        // Three one-tap starts. Home and Work are set with a pin until the
        // rider saves them, so every tile still leads somewhere.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ShortcutTile(
                  key: const Key('search_shortcut_home'),
                  icon: AlongIcons.home,
                  title: l10n.searchShortcutHome,
                  detail: l10n.searchShortcutAdd,
                  onTap: widget.onChooseOnMap!,
                ),
              ),
              const SizedBox(width: AlongSpace.s8),
              Expanded(
                child: _ShortcutTile(
                  key: const Key('search_shortcut_work'),
                  icon: AlongIcons.work,
                  title: l10n.searchShortcutWork,
                  detail: l10n.searchShortcutAdd,
                  onTap: widget.onChooseOnMap!,
                ),
              ),
              const SizedBox(width: AlongSpace.s8),
              Expanded(
                child: _ShortcutTile(
                  key: const Key('search_choose_on_map'),
                  icon: AlongIcons.mapPin,
                  title: l10n.searchChooseOnMapDetail,
                  detail: l10n.searchShortcutPinDetail,
                  onTap: widget.onChooseOnMap!,
                ),
              ),
            ],
          ),
        ),
      ],
      if (widget.extra != null && !searching) ...[
        const SizedBox(height: AlongSpace.s8),
        widget.extra!,
      ],
      if (state.isOffline)
        Padding(
          padding: const EdgeInsets.only(top: AlongSpace.s12),
          child: Text(
            l10n.searchOfflineHint,
            style: AlongType.caption(palette),
          ),
        ),
      if (state.isStaleResults) ...[
        const SizedBox(height: AlongSpace.s8),
        StaleBadge(label: l10n.cachedOptionsStaleBadge),
      ],
      if (!searching && state.recents.isNotEmpty) ...[
        section(l10n.searchRecentsTitle),
        card([
          for (final recent in state.recents)
            AlongPlaceRow(
              stacked: true,
              place: AlongPlace(
                key: Key('recent_${recent.label}'),
                icon: AlongIcons.history,
                title: recent.label,
                detail: away(recent.location),
                onTap: () => _selectRecent(recent),
              ),
            ),
        ]),
      ],
      if (!searching && popular.isNotEmpty && city != null) ...[
        section(l10n.searchPopularTitle(city)),
        card([
          for (final place in popular)
            AlongPlaceRow(
              stacked: true,
              place: AlongPlace(
                key: Key('popular_${place.name}'),
                icon: kindIcon(place.kind),
                title: place.name,
                detail: here == null
                    ? place.area
                    : l10n.searchResultDetail(
                        place.area,
                        l10n.distance(haversineDistanceM(here, place.location)),
                      ),
                onTap: () => _selectRecent(place.toRecent()),
              ),
            ),
        ]),
      ],
      if (searching && state.results.isNotEmpty) ...[
        section(l10n.searchResultsTitle),
        card([
          for (final result in state.results)
            AlongPlaceRow(
              stacked: true,
              place: AlongPlace(
                key: Key('result_${result.name}'),
                icon: kindIcon(result.kind),
                title: result.name,
                detail: l10n.searchResultDetail(
                  result.area,
                  l10n.distance(result.distanceM),
                ),
                onTap: () => _selectPlace(result),
              ),
            ),
        ]),
      ],
    ];

    final field = SearchField(
      key: const Key('destination_search_field'),
      variant: SearchFieldVariant.full,
      hint: widget.hint ?? l10n.homeSearchHint,
      controller: _controller,
      autofocus: !widget.embedded,
      onChanged: ref.read(searchControllerProvider.notifier).onQueryChanged,
    );

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [field, ...body],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: AlongSpace.s16),
            children: body,
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: '$title, $detail',
      excludeSemantics: true,
      child: AlongPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AlongHaptics.tick(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(AlongSpace.s12),
            decoration: AlongCraft.surface(
              palette,
              radius: AlongRadius.button.x,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: AlongCraft.compactFill(palette.recessed, 40),
                  child: AlongIcon(icon, size: 20, color: palette.ink),
                ),
                const SizedBox(height: AlongSpace.s8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AlongType.label(
                    palette,
                  ).copyWith(color: palette.ink, fontWeight: FontWeight.w600),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AlongType.caption(palette),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
