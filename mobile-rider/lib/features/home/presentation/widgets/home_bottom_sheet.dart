import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/home/data/recent_places_store.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

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

    return AlongBottomSheet(
      size: AlongBottomSheetSize.collapsed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AlongSpace.s8),
          GestureDetector(
            onTap: onSearchTap,
            child: AbsorbPointer(
              child: SearchField(
                variant: SearchFieldVariant.home,
                hint: l10n.homeSearchHint,
              ),
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          TextButton(
            key: const Key('home_plan_day'),
            onPressed: () => context.push(AppRoutes.itineraryEntry),
            child: Text(l10n.homePlanYourDay),
          ),
          const SizedBox(height: AlongSpace.s12),
          if (state.recents.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.recents.take(3).length,
                separatorBuilder: (_, __) => const SizedBox(width: AlongSpace.s8),
                itemBuilder: (context, index) {
                  final recent = state.recents[index];
                  return ActionChip(
                    label: Text(recent.label),
                    onPressed: () => onRecentTap(recent),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

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

    return AlongBottomSheet(
      size: AlongBottomSheetSize.half,
      title: l10n.homeNearbyTitle,
      child: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = rows[index];
          final modeLabel = _modeLabel(l10n, row.modeLabelKey);
          return ListTile(
            key: Key('nearby_row_${row.modeCode}'),
            title: Text(
              l10n.homeNearbyRow(
                row.countBucket,
                modeLabel,
                row.headingLabel,
                row.etaMinutes,
              ),
            ),
            onTap: () => onRowTap(row),
          );
        },
      ),
    );
  }

  String _modeLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'mode_keke' => l10n.modeKeke,
      'mode_okada' => l10n.modeOkada,
      'mode_minibus' => l10n.modeMinibus,
      _ => l10n.modeCar,
    };
  }
}
