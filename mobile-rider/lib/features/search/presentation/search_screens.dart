import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-06 Destination search (doc 06).
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({super.key});

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchField(
              variant: SearchFieldVariant.full,
              hint: l10n.homeSearchHint,
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
                onTap: () => context.push(AppRoutes.tripOptions),
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
            if (!state.isOffline && state.query.length >= 2) ...[
              const SizedBox(height: AlongSpace.s16),
              Text(l10n.searchResultsTitle, style: AlongText.bodyStrong),
              const SizedBox(height: AlongSpace.s8),
              if (state.isSearching) const LinearProgressIndicator(),
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
                      onTap: () async {
                        await ref
                            .read(searchControllerProvider.notifier)
                            .selectPlace(result);
                        if (context.mounted) {
                          context.push(AppRoutes.tripOptions);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
            TextButton(
              key: const Key('search_choose_on_map'),
              onPressed: () => context.push(AppRoutes.adjustPickup),
              child: Text(l10n.homeChooseOnMap),
            ),
          ],
        ),
      ),
    );
  }
}

/// R-06b Adjust pickup / choose on map (doc 06).
class AdjustPickupScreen extends ConsumerWidget {
  const AdjustPickupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adjustPickupControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adjustPickupTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(color: AlongColors.surface100),
                Icon(Icons.place, size: 48, color: AlongColors.ink900),
                if (state.isLoading)
                  const Positioned(
                    top: AlongSpace.s16,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          if (state.snappedStage != null)
            Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.adjustPickupBoardingAt(state.snappedStage!.name),
                  style: AlongText.bodyStrong,
                ),
              ),
            ),
          Expanded(
            flex: 0,
            child: SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: state.nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = state.nearbyPlaces[index];
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Text(
                      l10n.searchResultSubtitle(
                        place.area,
                        place.distanceM.round(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: AlongButton(
              key: const Key('adjust_pickup_confirm'),
              label: l10n.adjustPickupConfirm,
              onPressed: () => context.push(AppRoutes.tripOptions),
            ),
          ),
        ],
      ),
    );
  }
}
