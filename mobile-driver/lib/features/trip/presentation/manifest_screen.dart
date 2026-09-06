import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/trip/domain/driver_trip_config.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/manifest_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-15 Manifest — accepted/boarded riders with Na Me chip (doc 06).
class ManifestScreen extends ConsumerWidget {
  const ManifestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(manifestControllerProvider);

    return Scaffold(
      key: const Key('manifest_screen'),
      appBar: AppBar(
        title: Text(l10n.manifestTitle),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.entries.isEmpty
              ? Center(
                  child: Text(
                    l10n.manifestEmpty,
                    style: AlongText.body.copyWith(color: AlongColors.ink500),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(manifestControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AlongSpace.s16),
                    itemCount: state.entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AlongSpace.s12),
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return _ManifestRow(
                        key: Key('manifest_row_${entry.tripId}'),
                        entry: entry,
                        l10n: l10n,
                        onTap: () => context.push(
                          AppRoutes.activeTrip,
                          extra: ActiveTripArgs(
                            tripId: entry.tripId,
                            initialEntry: entry,
                          ),
                        ),
                        onMarkBoarded: entry.canMarkBoarded
                            ? () async {
                                await ref
                                    .read(manifestControllerProvider.notifier)
                                    .markBoarded(entry.tripId);
                              }
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}

class _ManifestRow extends StatelessWidget {
  const _ManifestRow({
    super.key,
    required this.entry,
    required this.l10n,
    required this.onTap,
    this.onMarkBoarded,
  });

  final DriverManifestEntry entry;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback? onMarkBoarded;

  @override
  Widget build(BuildContext context) {
    final colour = naMeColourFromToken(entry.naMe.colorToken);
    final shape = naMeShapeFromToken(entry.naMe.shape);

    return Material(
      color: AlongColors.surface0,
      borderRadius: BorderRadius.circular(AlongRadius.md.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.rider.displayName,
                      style: AlongText.bodyStrong,
                    ),
                  ),
                  NaMeChip(colour: colour, shape: shape),
                ],
              ),
              const SizedBox(height: AlongSpace.s8),
              Text(
                l10n.manifestBoarding(entry.board.name),
                style: AlongText.body,
              ),
              const SizedBox(height: AlongSpace.s4),
              Text(
                l10n.manifestStatus(entry.status.name),
                style: AlongText.caption.copyWith(color: AlongColors.ink500),
              ),
              if (onMarkBoarded != null) ...[
                const SizedBox(height: AlongSpace.s12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AlongButton(
                    key: Key('manifest_boarded_${entry.tripId}'),
                    label: l10n.manifestMarkBoarded,
                    variant: AlongButtonVariant.secondary,
                    onPressed: onMarkBoarded,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
