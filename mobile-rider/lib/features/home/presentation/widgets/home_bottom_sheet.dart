import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

IconData _modeIcon(String code) => switch (code) {
  'keke' => AlongIcons.keke,
  'okada' => AlongIcons.okada,
  'danfo' => AlongIcons.danfo,
  'bus' || 'brt' => AlongIcons.bus,
  _ => AlongIcons.taxi,
};

List<AlongPlace> _nearbyPlaces(
  AppLocalizations l10n,
  Iterable<NearbyAmbientRow> rows,
  ValueChanged<NearbyAmbientRow> onTap,
) => [
  for (final row in rows)
    AlongPlace(
      key: Key('nearby_row_${row.modeCode}'),
      icon: _modeIcon(row.modeCode),
      title: '${row.countBucket} ${row.modeLabel}',
      detail: l10n.homeNearbyEta(row.etaMinutes),
      onTap: () => onTap(row),
    ),
];

/// Home sheet: Where to?, recents, plan your day, then up to three nearby
/// rides. Every row is one tap. No expand toggle.
class HomePeekSheet extends StatelessWidget {
  const HomePeekSheet({
    super.key,
    required this.state,
    required this.onSearchTap,
    required this.onRecentTap,
    required this.onNearbyTap,
  });

  final HomeState state;
  final VoidCallback onSearchTap;
  final ValueChanged<RecentPlace> onRecentTap;
  final ValueChanged<NearbyAmbientRow> onNearbyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlongHomeSheet(
      key: const Key('home_sheet'),
      whereTo: l10n.homeSearchHint,
      whereToKey: const Key('home_where_to'),
      onWhereTo: onSearchTap,
      places: [
        for (final recent in state.recents.take(3))
          AlongPlace(
            key: Key('home_recent_${recent.label}'),
            icon: AlongIcons.schedule,
            title: recent.label,
            onTap: () => onRecentTap(recent),
          ),
        AlongPlace(
          key: const Key('home_plan_day'),
          icon: AlongIcons.path,
          title: l10n.homePlanYourDay,
          onTap: () => context.push(AppRoutes.itineraryEntry),
        ),
      ],
      sectionTitle: l10n.homeNearbyTitle,
      section: _nearbyPlaces(l10n, state.nearbyRows.take(3), onNearbyTap),
    );
  }
}

/// Full nearby list, same rows as the home sheet.
class HomeNearbySheet extends StatelessWidget {
  const HomeNearbySheet({
    super.key,
    required this.rows,
    required this.onRowTap,
  });

  final List<NearbyAmbientRow> rows;
  final ValueChanged<NearbyAmbientRow> onRowTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final places = _nearbyPlaces(l10n, rows, onRowTap);
    return AlongSpringSheet(
      fraction: 0.5,
      title: l10n.homeNearbyTitle,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [for (final p in places) AlongPlaceRow(place: p)],
      ),
    );
  }
}
