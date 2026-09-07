import 'package:along_data/along_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';

Future<bool> placementsEnabled(
  ConfigRepository config, {
  String? cityId,
}) async {
  try {
    final raw = await config.configJson('placements.enabled', cityId: cityId);
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) return raw.trim().toLowerCase() == 'true';
    return false;
  } catch (_) {
    return false;
  }
}

final placementsEnabledProvider = FutureProvider.family<bool, String?>(
  (ref, cityId) async {
    return placementsEnabled(ref.read(configRepositoryProvider), cityId: cityId);
  },
);

final placementsRepositoryProvider = Provider<PlacementsRepository>((ref) {
  return PlacementsRepository(ref.watch(alongSupabaseProvider));
});

final tripOptionsPlacementProvider =
    FutureProvider.family<List<SponsoredPlacement>, PlacementContext?>(
  (ref, context) async {
    if (context == null) return const [];
    final enabled = await ref.watch(placementsEnabledProvider(null).future);
    if (!enabled) return const [];
    return ref.read(placementsRepositoryProvider).resolvePlacements(context);
  },
);

final tripsHistoryPlacementProvider = FutureProvider<List<SponsoredPlacement>>(
  (ref) async {
    final enabled = await ref.watch(placementsEnabledProvider(null).future);
    if (!enabled) return const [];

    final profile = await ref.read(riderProfileRepositoryProvider).fetchCurrentProfile();
    final cityId = profile?.homeCityId;
    if (cityId == null) return const [];

    final repo = ref.read(placementsRepositoryProvider);
    final corridorId = await repo.corridorIdForCity(cityId);
    if (corridorId == null) return const [];

    return repo.resolvePlacements(
      PlacementContext(
        type: PlacementContextType.corridor,
        targetReference: corridorId,
      ),
    );
  },
);
