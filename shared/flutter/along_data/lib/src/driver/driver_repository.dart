import 'package:along_data/src/contracts/api_contracts.g.dart';
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver onboarding RPCs (doc 03 §1).
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
}
