import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Ambient vehicle discovery (Tier A — doc 03 §2).
class PresenceRepository {
  PresenceRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<dto.AmbientVehiclesResponse> ambientVehicles(
    dto.AmbientVehiclesRequest request,
  ) async {
    try {
      final raw = await _gateway.rpc(
        'ambient_vehicles',
        params: request.toJson(),
      );
      return dto.AmbientVehiclesResponse.fromJson(raw);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
