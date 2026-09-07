import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/features/offline/stale_badge.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

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
  });

  final ValueChanged<DestinationPick> onDestinationSelected;
  final String? hint;
  final bool embedded;

  @override
  ConsumerState<DestinationSearchPanel> createState() =>
      _DestinationSearchPanelState();
}

class _DestinationSearchPanelState extends ConsumerState<DestinationSearchPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchField(
          key: const Key('destination_search_field'),
          variant: SearchFieldVariant.full,
          hint: widget.hint ?? l10n.homeSearchHint,
          controller: _controller,
          onChanged: ref.read(searchControllerProvider.notifier).onQueryChanged,
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(l10n.searchRecentsTitle, style: AlongText.bodyStrong),
        const SizedBox(height: AlongSpace.s8),
        ...state.recents.map(
          (recent) => ListTile(
            key: Key('recent_${recent.label}'),
            leading: const Icon(Icons.history_rounded),
            title: Text(recent.label),
            onTap: () => _selectRecent(recent),
          ),
        ),
        if (state.isOffline)
          Padding(
            padding: const EdgeInsets.only(top: AlongSpace.s8),
            child: Text(
              l10n.searchOfflineHint,
              style: AlongText.caption.copyWith(color: AlongColors.ink500),
            ),
          ),
        if (state.isStaleResults) ...[
          const SizedBox(height: AlongSpace.s8),
          StaleBadge(label: l10n.cachedOptionsStaleBadge),
        ],
        if (state.query.length >= 2) ...[
          const SizedBox(height: AlongSpace.s16),
          Text(l10n.searchResultsTitle, style: AlongText.bodyStrong),
          const SizedBox(height: AlongSpace.s8),
          if (state.isSearching) const LinearProgressIndicator(),
          if (widget.embedded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final result = state.results[index];
                return ListTile(
                  key: Key('result_${result.name}'),
                  title: Text(result.name),
                  subtitle: Text(
                    l10n.searchResultSubtitle(
                      result.area,
                      result.distanceM.round(),
                    ),
                  ),
                  onTap: () => _selectPlace(result),
                );
              },
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  final result = state.results[index];
                  return ListTile(
                    key: Key('result_${result.name}'),
                    title: Text(result.name),
                    subtitle: Text(
                      l10n.searchResultSubtitle(
                        result.area,
                        result.distanceM.round(),
                      ),
                    ),
                    onTap: () => _selectPlace(result),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
