import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver presence and Tier A ambient discovery (doc 03 §2, §6).
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
      return dto.AmbientVehiclesResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<dto.AmbientDemandResponse> ambientDemand(
    dto.AmbientDemandRequest request,
  ) async {
    try {
      final raw = await _gateway.rpc(
        'ambient_demand',
        params: request.toJson(),
      );
      return dto.AmbientDemandResponse.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<dto.SetPresenceResponse> setPresence(
    dto.SetPresenceRequest request,
  ) async {
    try {
      final raw = await _gateway.rpc(
        'set_presence',
        params: request.toJson(),
      );
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        if (map['session_id'] is String) {
          return dto.SetPresenceResponse.fromJson(map);
        }
      }
      return dto.SetPresenceResponse(
        session_id: 'local-session',
        status: request.p_status,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<bool> presencePing(dto.PresencePingRequest request) async {
    try {
      final raw = await _gateway.rpc(
        'presence_ping',
        params: request.toJson(),
      );
      if (raw is Map<String, dynamic>) {
        return raw['accepted'] == true;
      }
      return false;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
