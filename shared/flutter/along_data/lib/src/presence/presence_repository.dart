import 'package:along_core/along_core.dart';
import 'package:along_data/src/contracts/api_contracts.g.dart' as dto;
import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:along_data/src/supabase/error_mapper.dart';

/// Driver presence ping and status RPCs.
class PresenceRepository {
  PresenceRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<void> setPresence(dto.SetPresenceRequest request) async {
    try {
      await _gateway.rpc('set_presence', params: request.toJson());
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> ping(dto.PresencePingRequest request) async {
    try {
      await _gateway.rpc('presence_ping', params: request.toJson());
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<PresenceState>> ambientVehicles(String cityId) async {
    try {
      final raw = await _gateway.rpc(
        'ambient_vehicles',
        params: {'p_city_id': cityId},
      );
      final cells = (raw['cells'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return cells.map(_mapCell).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  PresenceState _mapCell(Map<String, dynamic> cell) {
    final modeCode = (cell['mode'] as Map<String, dynamic>?)?['code'] as String?;
    return PresenceState(
      driverId: cell['cell_id'] as String? ?? '',
      mode: TransportMode.tryParse(modeCode) ?? TransportMode.car,
      status: cell['status'] as String? ?? 'offline',
      location: GeoPoint(
        lat: (cell['centroid']['lat'] as num).toDouble(),
        lng: (cell['centroid']['lng'] as num).toDouble(),
      ),
      updatedAt: DateTime.parse(cell['as_of'] as String),
      headingDegrees: (cell['heading'] as num?)?.toDouble(),
    );
  }
}
