import 'package:along_data/src/contracts/api_contracts.g.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver onboarding and profile reads (doc 03 §1).
class DriverRepository {
  DriverRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<void> startDriverOnboarding({
    required String cityId,
    required String displayName,
    String? gender,
  }) async {
    try {
      await _gateway.rpc(
        'start_driver_onboarding',
        params: StartDriverOnboardingRequest(
          city_id: cityId,
          display_name: displayName,
          gender: gender,
        ).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<String> registerVehicle(RegisterVehicleRequest request) async {
    try {
      final result = await _gateway.rpc(
        'register_vehicle',
        params: request.toJson(),
      ) as Map<String, dynamic>;
      return RegisterVehicleResponse.fromJson(result).vehicle_id;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<DriverProfileSnapshot?> fetchDriverProfile(String driverId) async {
    try {
      final rows = await _gateway.selectRows(
        'drivers',
        filters: {'id': driverId},
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      return DriverProfileSnapshot(
        driverId: driverId,
        verifiedStatus: row['verified_status'] as String? ?? 'unverified',
        cityId: row['city_id'] as String?,
        standing: row['standing'] as String? ?? 'good_standing',
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> setDriverCity(String cityId) async {
    try {
      await _gateway.rpc(
        'set_driver_city',
        params: SetDriverCityRequest(p_city_id: cityId).toJson(),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}

class DriverProfileSnapshot {
  const DriverProfileSnapshot({
    required this.driverId,
    required this.verifiedStatus,
    required this.cityId,
    required this.standing,
  });

  final String driverId;
  final String verifiedStatus;
  final String? cityId;
  final String standing;

  bool get isVerified => verifiedStatus == 'verified';
  bool get isLedgerBlocked => standing == 'matching_paused';
}
