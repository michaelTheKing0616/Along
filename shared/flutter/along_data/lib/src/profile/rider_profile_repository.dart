import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Rider profile + preferences for R-26.
class RiderProfile {
  const RiderProfile({
    required this.displayName,
    this.phoneE164,
    this.homeCityId,
    this.wayfindingMode = WayfindingMode.text,
    this.savedSort,
    this.womenOnlyPref = false,
  });

  final String displayName;
  final String? phoneE164;
  final String? homeCityId;
  final WayfindingMode wayfindingMode;
  final SortCriterion? savedSort;
  final bool womenOnlyPref;
}

/// Reads profile rows and syncs prefs via `update_rider_prefs`.
class RiderProfileRepository {
  RiderProfileRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<RiderProfile?> fetchCurrentProfile() async {
    final userId = _gateway.currentUser?.id;
    if (userId == null) return null;

    try {
      final profiles = await _gateway.selectRows(
        'profiles',
        filters: {'id': userId},
      );
      if (profiles.isEmpty) return null;

      final riders = await _gateway.selectRows(
        'riders',
        filters: {'id': userId},
      );
      final rider = riders.isNotEmpty ? riders.first : null;
      final profile = profiles.first;

      return RiderProfile(
        displayName: profile['display_name'] as String? ?? 'Rider',
        phoneE164: profile['phone_e164'] as String?,
        homeCityId: rider?['home_city_id'] as String?,
        wayfindingMode: WayfindingMode.tryParse(
          rider?['wayfinding_mode'] as String?,
        ),
        savedSort: _parseSort(rider?['saved_sort'] as String?),
        womenOnlyPref: rider?['women_only_pref'] as bool? ?? false,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<bool> womenOnlyMatchingEnabled(String? cityId) async {
    if (cityId == null) return false;
    try {
      final rows = await _gateway.selectRows(
        'cities',
        filters: {'id': cityId},
      );
      if (rows.isEmpty) return false;
      final flags = rows.first['regulatory_flags'] as Map<String, dynamic>? ?? {};
      return flags['women_only_matching'] == true;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> updatePrefs({
    WayfindingMode? wayfindingMode,
    SortCriterion? savedSort,
    bool? womenOnlyPref,
  }) async {
    try {
      await _gateway.rpc(
        'update_rider_prefs',
        params: dto.UpdateRiderPrefsRequest(
          wayfinding_mode: wayfindingMode?.wireValue,
          saved_sort: savedSort == null ? null : _sortWire(savedSort),
          women_only_pref: womenOnlyPref,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> setHomeCity(String cityId) async {
    try {
      await _gateway.rpc(
        'set_home_city',
        params: dto.SetHomeCityRequest(p_city_id: cityId).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  SortCriterion? _parseSort(String? raw) => switch (raw) {
        'cheapest' => SortCriterion.cheapest,
        'fastest' => SortCriterion.fastest,
        'least_strenuous' => SortCriterion.leastStrenuous,
        'recommended' => SortCriterion.recommended,
        _ => null,
      };

  String _sortWire(SortCriterion sort) => switch (sort) {
        SortCriterion.recommended => 'recommended',
        SortCriterion.cheapest => 'cheapest',
        SortCriterion.fastest => 'fastest',
        SortCriterion.leastStrenuous => 'least_strenuous',
      };
}
